from datetime import datetime, timezone
import logging
from app import start as start_app


logging.basicConfig(
    encoding="UTF-8",
    level=logging.DEBUG,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
    handlers=[
        logging.FileHandler("SleepWardenBackend.log"),
        logging.StreamHandler(),
    ],
)
logging.Formatter.formatTime = (
    lambda self, record, datefmt=None: (
        datetime
        .fromtimestamp(record.created, tz=timezone.utc)
        .isoformat(timespec='milliseconds')
    )
)


if __name__ == "__main__":
    start_app(host="0.0.0.0", port=1216)
