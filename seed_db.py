import random
from faker import Faker
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from app.core.config import settings # Tu archivo de configuración actual
from app.db.base import Base # Para acceder a los metadatos si fuera necesario

# Importa todos tus modelos aquí para que SQLAlchemy los reconozca
from app.models.users import User, PayoutMethod
from app.models.groups import Group, GroupStatus
from app.models.group_members import GroupMember
from app.models.expenses import Expense, SplitType
from app.models.expense_splits import ExpenseSplit
from app.models.settlements import Settlement, SettlementStatus

fake = Faker('es_ES')

# Creamos el engine SOLO para este script de seeding
engine = create_engine(settings.DATABASE_URL)

def seed_database():
    with Session(engine) as session:
        print("🧹 Limpiando datos anteriores...")
        # Orden inverso por las Foreign Keys
        session.query(Settlement).delete()
        session.query(ExpenseSplit).delete()
        session.query(Expense).delete()
        session.query(GroupMember).delete()
        session.query(Group).delete()
        session.query(User).delete()
        session.commit()

        print("👥 Creando 20 Usuarios...")
        users = []
        for _ in range(20):
            user = User(
                name=fake.name(),
                email=fake.unique.email(),
                password_hash=fake.password(length=12, special_chars=True, digits=True, upper_case=True),
                preferred_payout_type=random.choice(list(PayoutMethod)),
                preferred_payout_alias=fake.word() if random.random() > 0.5 else None
            )
            users.append(user)
        session.add_all(users)
        session.commit()

        print("🏢 Creando 5 Grupos...")
        groups = []
        for _ in range(5):
            group = Group(
                group_name=fake.company() + " Trip",
                created_by_user_id=random.choice(users).user_id,
                status=GroupStatus.ACTIVE
            )
            groups.append(group)
        session.add_all(groups)
        session.commit()

        print("🤝 Asignando Miembros...")
        for group in groups:
            members_count = random.randint(3, 6)
            selected_users = random.sample(users, members_count)
            for user in selected_users:
                member = GroupMember(
                    group_id=group.group_id,
                    user_id=user.user_id,
                    joined_at=fake.date_time_this_year()
                )
                session.add(member)
        session.commit()

        print("💸 Generando Gastos y Divisiones...")
        for group in groups:
            members = session.query(GroupMember).filter_by(group_id=group.group_id).all()
            member_ids = [m.user_id for m in members]
            
            for _ in range(10): 
                payer = random.choice(member_ids)
                amount = round(random.uniform(10, 500), 2)
                
                expense = Expense(
                    group_id=group.group_id,
                    payer_user_id=payer,
                    title=fake.sentence(nb_words=4),
                    total_amount=amount,
                    split_type=random.choice(list(SplitType))
                )
                session.add(expense)
                session.flush() 

                individual_amount = round(amount / len(member_ids), 2)
                for uid in member_ids:
                    split = ExpenseSplit(
                        expense_id=expense.expense_id,
                        user_id=uid,
                        amount_owed=individual_amount
                    )
                    session.add(split)
        
        session.commit()
        print("✅ ¡Base de datos poblada con éxito!")

if __name__ == "__main__":
    seed_database()