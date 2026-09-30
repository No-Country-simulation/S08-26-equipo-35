from app.db.session import get_db
from app.models.groups import Group
from app.models.group_members import GroupMember
from app.models.users import User
import uuid

db = next(get_db())
group_id = uuid.UUID('0f355ab6-9396-4477-9739-35c2fccbbc34')

group = db.query(Group).filter(Group.group_id == group_id).first()
print('Group found:', group is not None)
if group:
    print('Group name:', group.group_name)

user = db.query(User).filter(User.email == 'test@example.com').first()
print('User found:', user is not None)
if user:
    print('User ID:', user.user_id)
    member = db.query(GroupMember).filter(
        GroupMember.group_id == group_id,
        GroupMember.user_id == user.user_id
    ).first()
    print('Is group member:', member is not None)
