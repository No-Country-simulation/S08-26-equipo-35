# tests/conftest.py
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from fastapi.testclient import TestClient
from app.main import app
from app.db.base import Base
from app.db.session import get_db
from app.core.security import get_current_user
from app.models.users import User
from app.core.config import settings
from app.core.security import create_access_token, hash_password
from uuid import UUID, uuid4
from datetime import datetime, timedelta
from faker import Faker
from app.models.groups import Group, GroupStatus
from app.models.group_members import GroupMember
from app.models.expenses import Expense, SplitType
from app.models.expense_splits import ExpenseSplit
from decimal import Decimal


# Configuración de la base de datos de test (SQLite en memoria)
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture(scope="session")
def db_engine():
    Base.metadata.create_all(bind=engine)
    yield engine
    Base.metadata.drop_all(bind=engine)


@pytest.fixture(scope="function")
def db_session(db_engine):
    connection = db_engine.connect()
    transaction = connection.begin()
    session = TestingSessionLocal(bind=connection)
    
    # Asegúrate de que los enums se creen correctamente
    # Esto es necesario para SQLite ya que no maneja ENUMs nativos como Postgres
    # Para la prueba, simulamos que existen en la DB.
    # En una configuración real de Postgres, esto lo maneja Alembic.

    yield session

    session.close()
    transaction.rollback()
    connection.close()


@pytest.fixture(scope="function")
def client(db_session):
    def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()


# Fixture para un usuario de prueba autenticado
@pytest.fixture(scope="function")
def test_user(db_session: Session) -> User:
    fake = Faker('es_ES')
    hashed_password = hash_password("TestPassword123!")
    user = User(
        user_id=uuid4(),
        name=fake.name(),
        email=fake.email(),
        password_hash=hashed_password,
        preferred_payout_alias="test_alias",
        preferred_payout_type="CBU",
        created_at=datetime.utcnow()
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture(scope="function")
def test_user_token(test_user: User) -> str:
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    return create_access_token(
        data={"sub": test_user.email}, expires_delta=access_token_expires
    )


@pytest.fixture(scope="function")
def authenticated_client(client: TestClient, test_user: User, test_user_token: str):
    def override_get_current_user():
        return test_user

    app.dependency_overrides[get_current_user] = override_get_current_user
    client.headers = {"Authorization": f"Bearer {test_user_token}"}
    yield client
    app.dependency_overrides.clear()
    client.headers = {}


@pytest.fixture(scope="function")
def test_users(db_session: Session):
    fake = Faker('es_ES')
    users = []
    for _ in range(5):
        user = User(
            user_id=uuid4(),
            name=fake.name(),
            email=fake.email(),
            password_hash=hash_password("Password123!"),
            preferred_payout_alias=fake.user_name(),
            preferred_payout_type="CVU",
            created_at=datetime.utcnow()
        )
        db_session.add(user)
        users.append(user)
    db_session.commit()
    for user in users:
        db_session.refresh(user)
    return users


@pytest.fixture(scope="function")
def test_group(db_session: Session, test_user: User) -> Group:
    group = Group(
        group_id=uuid4(),
        group_name="Test Group",
        created_by_user_id=test_user.user_id,
        status=GroupStatus.ACTIVE,
        created_at=datetime.utcnow()
    )
    db_session.add(group)
    db_session.commit()
    db_session.refresh(group)
    return group


@pytest.fixture(scope="function")
def test_group_with_members(db_session: Session, test_user: User, test_users: list[User]) -> Group:
    group = Group(
        group_id=uuid4(),
        group_name="Group with Members",
        created_by_user_id=test_user.user_id,
        status=GroupStatus.ACTIVE,
        created_at=datetime.utcnow()
    )
    db_session.add(group)
    db_session.commit()
    db_session.refresh(group)

    # Añadir al creador del grupo como miembro
    group_member_creator = GroupMember(
        group_id=group.group_id,
        user_id=test_user.user_id,
        joined_at=datetime.utcnow()
    )
    db_session.add(group_member_creator)

    # Añadir otros miembros
    for user in test_users:
        if user.user_id != test_user.user_id: # No añadir al creador dos veces
            group_member = GroupMember(
                group_id=group.group_id,
                user_id=user.user_id,
                joined_at=datetime.utcnow()
            )
            db_session.add(group_member)
    db_session.commit()
    return group

@pytest.fixture(scope="function")
def test_expense(db_session: Session, test_group_with_members: Group, test_user: User) -> Expense:
    expense = Expense(
        expense_id=uuid4(),
        group_id=test_group_with_members.group_id,
        payer_user_id=test_user.user_id,
        title="Dinner",
        expense_category="Food",
        total_amount=Decimal("100.00"),
        split_type=SplitType.EQUAL,
        created_at=datetime.utcnow()
    )
    db_session.add(expense)
    db_session.commit()
    db_session.refresh(expense)

    # Crear splits (ejemplo para EQUAL)
    members = db_session.query(GroupMember).filter(GroupMember.group_id == test_group_with_members.group_id).all()
    amount_per_member = expense.total_amount / len(members)

    for member in members:
        split = ExpenseSplit(
            expense_id=expense.expense_id,
            user_id=member.user_id,
            amount_owed=amount_per_member
        )
        db_session.add(split)
    db_session.commit()
    return expense