class AppBaseTemplate:
    """
        Base template class for other classes and Globally visible variables.
    """
    def __init__(self) -> None:
        # System
        self.loop = None  # asyncio main loop
        self.sched = None  # Scheduler

        self.analyzer = None  # Store and analyze data

        # Connector client
        self.client = None

        # WebSocket for push notifications
        self.bm = None
        self.conn_key = None  # Socket

        self.signal = None,  # Latest signal "BUY", "SELL"


        #
        # State of the server (updated after each interval)
        #
        # State 0 or None or empty means ok. String and other non empty objects mean error
        # Networks, connections, exceptions etc. what does not allow us to work at all
        self.error_status = 0
        self.server_status = 0  # If server allow us to trade (maintenance, down etc.)
        self.account_status = 0  # If account allows us to trade (funds, suspended etc.)
        # Something wrong with our trading logic (wrong use, inconsistent state etc. what we cannot recover)
        self.trade_state_status = 0

        # Trade status
        self.transaction = None
        self.status = None  # BOUGHT, SOLD, BUYING, SELLING
        self.order = None  # Latest or current order
        self.order_time = None  # Order submission time

        # Available assets for trade
        # Can be set by the sync/recover function or updated by the trading algorithm
        # BTC owned (on account, already bought, available for trade)
        self.base_quantity = "0.04108219"
        self.quote_quantity = "1000.0"  # USDT owned (on account, available for trade)

        #
        # Trader. Status data retrieved from the server. Below are examples only.
        #
        # 0: normal，1：system maintenance
        self.system_status = {"status": 0, "msg": "normal"}
        self.symbol_info = {}
        self.account_info = {}

    