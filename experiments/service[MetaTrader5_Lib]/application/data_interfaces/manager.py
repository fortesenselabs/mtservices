import logging
import asyncio
import threading
from typing import List

logging.basicConfig(
    filename="collector.log",
    level=logging.DEBUG,
    format="%(asctime)s %(levelname)s %(message)s",
)

class DataInterfaceManager:
    """
        Manage Interfaces
    """
    def __init__(self, interfaces: List, store_data: bool):
        self.interfaces = interfaces
        self.store_data = store_data

    def start(self):
        for interface in self.interfaces:
            t = threading.Thread(target=interface.run)
            t.start()

    def stop(self):
        for interface in self.interfaces:
            interface.stop()

    def get_data(self):
        data = {}
        for interface in self.interfaces:
            data[interface.name] = interface.get_data()
        return data
    
    def get_info(self):
        return
