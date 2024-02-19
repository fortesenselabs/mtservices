# MetaTrader 5 Sever

This is the MetaTrader 5 sockets server

## Commands

- ACCOUNT: GetAccountInfo [done]
- BALANCE: GetBalanceInfo [done]
- HISTORY: HistoryInfo [done]
- TRADE: TradingRequest [done]
- POSITIONS: GetPositions [done]
- ORDERS: GetOrders [done]
- TICK: GetTicks [done]

# Protocol

- plain text (mostly for receiving requests)
- json (mostly for sending responses back to the client)

## Notes

- This is not for high frequency trading
- server might take some time to process some data collection requests e.g if the requested historical tick data is more then 12 hours
