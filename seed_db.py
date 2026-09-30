# seed_db.py
import os
import sys
from datetime import datetime, timedelta
from decimal import Decimal
import random
import uuid

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from faker import Faker

# Ajustar el path para que Python encuentre los módulos de la aplicación
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), 'app')))

from app.core.config import settings
from app.db.base import Base
from app.models.users import User, PayoutMethod
from app.models.groups import Group, GroupStatus
from app.models.group_members import GroupMember
from app.models.expenses import Expense, SplitType
from app.models.expense_splits import ExpenseSplit
from app.models.settlements import Settlement, SettlementStatus
from app.core.security import hash_password # Importar hash_password

# Configuración del motor de la base de datos
engine = create_engine(settings.DATABASE_URL)

# Creamos una sesión
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def seed_data():
    fake = Faker('es_ES')
    
    with Session(engine) as session:
        print("Eliminando datos existentes...")
        # Eliminar datos en el orden correcto para evitar problemas de FK
        session.query(Settlement).delete()
        session.query(ExpenseSplit).delete()
        session.query(Expense).delete()
        session.query(GroupMember).delete()
        session.query(Group).delete()
        session.query(User).delete()
        session.commit()
        print("Datos eliminados.")

        print("Creando usuarios...")
        users = []
        for _ in range(20):
            password = fake.password(length=12, special_chars=True, digits=True, upper_case=True, lower_case=True)
            hashed_password = hash_password(password) # Hashear la contraseña
            user = User(
                user_id=uuid.uuid4(),
                name=fake.name(),
                email=fake.unique.email(),
                password_hash=hashed_password, # Guardar el hash
                preferred_payout_alias=fake.user_name(),
                preferred_payout_type=random.choice(list(PayoutMethod)),
                created_at=fake.date_time_between(start_date="-2y", end_date="now")
            )
            users.append(user)
            session.add(user)
        session.commit()
        print(f"{len(users)} usuarios creados.")

        print("Creando grupos...")
        groups = []
        for _ in range(5):
            creator = random.choice(users)
            group = Group(
                group_id=uuid.uuid4(),
                group_name=f"{fake.company()} Trip",
                created_by_user_id=creator.user_id,
                status=GroupStatus.ACTIVE,
                created_at=fake.date_time_between(start_date="-1y", end_date="now")
            )
            groups.append(group)
            session.add(group)
        session.commit()
        print(f"{len(groups)} grupos creados.")

        print("Añadiendo miembros a los grupos...")
        group_members = []
        for group in groups:
            # Añadir al creador del grupo como miembro
            creator_member = GroupMember(
                group_id=group.group_id,
                user_id=group.created_by_user_id,
                joined_at=group.created_at
            )
            group_members.append(creator_member)
            
            # Añadir 3-6 miembros adicionales al grupo
            potential_members = [u for u in users if u.user_id != group.created_by_user_id]
            random.shuffle(potential_members)
            
            num_additional_members = random.randint(3, 6)
            for i in range(min(num_additional_members, len(potential_members))):
                member = GroupMember(
                    group_id=group.group_id,
                    user_id=potential_members[i].user_id,
                    joined_at=fake.date_time_between(start_date=group.created_at, end_date="now")
                )
                group_members.append(member)
        session.add_all(group_members)
        session.commit()
        print(f"{len(group_members)} miembros de grupo creados.")

        print("Creando gastos y divisiones...")
        expense_categories = ["Food", "Transport", "Accommodation", "Activities", "Shopping", "Utilities", "Other"]
        expenses = []
        expense_splits = []

        for group in groups:
            members_in_group = session.query(GroupMember).filter_by(group_id=group.group_id).all()
            if not members_in_group:
                continue

            member_ids = [m.user_id for m in members_in_group]

            for _ in range(10): # 10 gastos por grupo
                payer = random.choice(members_in_group).user_id
                total_amount = Decimal(random.uniform(10.00, 500.00)).quantize(Decimal("0.01"))
                split_type = random.choice(list(SplitType))
                created_at = fake.date_time_between(start_date=group.created_at, end_date="now")
                
                expense = Expense(
                    expense_id=uuid.uuid4(),
                    group_id=group.group_id,
                    payer_user_id=payer,
                    title=fake.sentence(nb_words=4),
                    expense_category=random.choice(expense_categories), # <-- CORRECCIÓN AQUÍ
                    total_amount=total_amount,
                    split_type=split_type,
                    created_at=created_at
                )
                expenses.append(expense)
                session.add(expense)
                session.flush() # Para obtener expense.expense_id

                if split_type == SplitType.EQUAL:
                    amount_per_member = (total_amount / len(members_in_group)).quantize(Decimal("0.01"))
                    remainder = total_amount * 100 % len(members_in_group)
                    
                    for i, member_id in enumerate(member_ids):
                        split_amount = amount_per_member
                        if i < remainder:
                            split_amount += Decimal("0.01")
                        expense_splits.append(
                            ExpenseSplit(
                                expense_id=expense.expense_id,
                                user_id=member_id,
                                amount_owed=split_amount
                            )
                        )
                elif split_type == SplitType.EXACT_AMOUNT:
                    # Distribución de montos exactos de forma aleatoria
                    remaining_amount = total_amount
                    num_splits = random.randint(1, len(members_in_group))
                    selected_split_members = random.sample(member_ids, num_splits)
                    
                    split_amounts = []
                    for _ in range(num_splits - 1):
                        split = Decimal(random.uniform(0.01, float(remaining_amount) / 2)).quantize(Decimal("0.01"))
                        split_amounts.append(split)
                        remaining_amount -= split
                    split_amounts.append(remaining_amount.quantize(Decimal("0.01")))

                    random.shuffle(split_amounts) # Mezclar para asignar a usuarios aleatorios

                    for i, member_id in enumerate(selected_split_members):
                        if i < len(split_amounts):
                            expense_splits.append(
                                ExpenseSplit(
                                    expense_id=expense.expense_id,
                                    user_id=member_id,
                                    amount_owed=split_amounts[i]
                                )
                            )
                        else: # Si hay más miembros que splits generados (puede pasar con random)
                            expense_splits.append(
                                ExpenseSplit(
                                    expense_id=expense.expense_id,
                                    user_id=member_id,
                                    amount_owed=Decimal("0.00") # Asignar 0 para no romper la suma
                                )
                            )

        session.add_all(expense_splits)
        session.commit()
        print(f"{len(expenses)} gastos creados con {len(expense_splits)} divisiones.")

        print("Creando liquidaciones...")
        settlements = []
        for group in groups:
            members_in_group = session.query(GroupMember).filter_by(group_id=group.group_id).all()
            if len(members_in_group) < 2:
                continue

            for _ in range(random.randint(0, 3)): # 0-3 liquidaciones por grupo
                payer = random.choice(members_in_group).user_id
                receiver = random.choice([m.user_id for m in members_in_group if m.user_id != payer])
                amount = Decimal(random.uniform(5.00, 200.00)).quantize(Decimal("0.01"))
                status_s = random.choice(list(SettlementStatus))
                settled_at = fake.date_time_between(start_date=group.created_at, end_date="now")

                settlement = Settlement(
                    settlement_id=uuid.uuid4(),
                    group_id=group.group_id,
                    payer_user_id=payer,
                    receiver_user_id=receiver,
                    amount=amount,
                    status=status_s,
                    settled_at=settled_at
                )
                settlements.append(settlement)
                session.add(settlement)
        session.commit()
        print(f"{len(settlements)} liquidaciones creadas.")

    print("Proceso de seeding completado exitosamente.")

if __name__ == "__main__":
    # Base.metadata.create_all(bind=engine) # No necesario si Alembic ya corre
    seed_data()