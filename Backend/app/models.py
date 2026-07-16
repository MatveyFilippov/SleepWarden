from datetime import datetime
from pydantic import BaseModel


class IamAwakeResponse(BaseModel):
    timestamp: datetime
