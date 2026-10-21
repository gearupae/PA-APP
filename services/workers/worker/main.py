"""Worker entrypoint stub — polls or listens on Redis when queue is wired."""

import logging
import time

from worker.config import settings

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("pa-app-worker")


def main() -> None:
    log.info("PA-APP worker started (stub). redis=%s", settings.redis_url)
    while True:
        # TODO: BRPOP from queue, dispatch process_recording and sync_mail_account jobs
        time.sleep(60)


if __name__ == "__main__":
    main()
