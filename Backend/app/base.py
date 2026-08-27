import logging
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
import uvicorn
from .__version__ import __version__


APP = FastAPI(version=__version__, title="SleepWarden")
log = logging.getLogger("app.base")


@APP.middleware("http")
async def log_middleware(request: Request, call_next):
    log.debug((
        f"REQUEST: {request.method} {request.url.path}"
        f" (Requester:{request.client};"
        f"Headers:{request.headers.raw};"
        f"QueryParams:{request.query_params};"
        f"Body:{await request.body()})"
    ))
    response = await call_next(request)
    log.debug(f"RESPONSE: {response.status_code}")
    return response


@APP.exception_handler(Exception)
async def global_exception_handler(request: Request, ex: Exception):
    log.error(f"Faced with unhandled exception: {ex}", exc_info=True)
    log.debug("RESPONSE: 500")
    return JSONResponse(
        content={"detail": "Internal server error"},
        status_code=500,
    )


def start(host: str, port: int):
    log.info(f"Start application (-v{APP.version}) on http://{host}:{port}")
    uvicorn.run(APP, host=host, port=port, log_level=logging.WARNING, access_log=False)
