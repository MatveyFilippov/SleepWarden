from datetime import datetime, timezone
import logging
from fastapi import Request, status
from .base import APP
from .models import IamAwakeResponse


log = logging.getLogger("app.handlers")


@APP.post("/i_am_alive", response_model=IamAwakeResponse, status_code=status.HTTP_200_OK)
async def i_am_alive(request: Request) -> IamAwakeResponse:
    client = request.client
    client_ip = client.host if client else "unknown_host"
    log.info(f"Received 'I am alive' from {client_ip}")
    return IamAwakeResponse(timestamp=datetime.now(timezone.utc))
