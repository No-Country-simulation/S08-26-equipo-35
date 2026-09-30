from uuid import UUID

from fastapi import HTTPException, WebSocketException, status
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.users import User
from app.services.expense_service import validate_group_member


def _invalid_credentials() -> WebSocketException:
    return WebSocketException(
        code=status.WS_1008_POLICY_VIOLATION,
        reason="No se pudieron validar las credenciales",
    )


def authenticate_ws(token: str, db: Session) -> User:
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM],
        )
    except JWTError as exc:
        raise _invalid_credentials() from exc

    email = payload.get("sub")
    if not isinstance(email, str) or not email:
        raise _invalid_credentials()

    user = db.query(User).filter(User.email == email).first()
    if user is None:
        raise _invalid_credentials()
    return user


def authorize_group_membership(
    db: Session, group_id: UUID, user_id: UUID
) -> None:
    try:
        validate_group_member(
            db,
            group_id,
            user_id,
            "No perteneces a este grupo",
        )
    except HTTPException as exc:
        raise WebSocketException(
            code=status.WS_1008_POLICY_VIOLATION,
            reason="No perteneces a este grupo",
        ) from exc
