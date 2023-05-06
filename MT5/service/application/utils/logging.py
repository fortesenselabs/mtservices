import sys
import logging
from logging.handlers import RotatingFileHandler

def setup_logging(logfile_path, logging_level: int = logging.DEBUG):
    """
    Set up logging to console and file.

    Args:
        logfile_path (str): Path to the log file.

    Returns:
        logging.Logger: Configured logger.
    """
    logger = logging.getLogger()
    logger.setLevel(logging_level)

    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')

    # Log to file
    file_handler = logging.FileHandler(logfile_path)
    file_handler.setLevel(logging_level)
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)

    # Log to console
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(logging_level)
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)

    return logger


# Set up logging to file
# log_formatter = logging.Formatter('%(asctime)s %(levelname)s %(funcName)s(%(lineno)d) %(message)s')
# file_handler = RotatingFileHandler('logs/service.log', maxBytes=1024*1024, backupCount=5)
# file_handler.setLevel(logging.INFO)
# file_handler.setFormatter(log_formatter)
# logger.addHandler(file_handler)

# # Set up logging to console
# console_handler = logging.StreamHandler(sys.stdout)
# console_handler.setLevel(logging.INFO)
# console_handler.setFormatter(log_formatter)
# logger.addHandler(console_handler)