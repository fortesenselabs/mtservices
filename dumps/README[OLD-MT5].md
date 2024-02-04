# MetaTrader 5 socket server

This is a metatrader 5 server using sockets

## How to run

```bash
git clone <repo>
```

- Copy contents of the server/MT5 folder to your <metatrader_5_folder>/MQL5
- Drag and drop the compiled EA in your Metatrader client

## Commands

- CONFIG: ScriptConfiguration
- ACCOUNT: GetAccountInfo [tested]
- BALANCE: GetBalanceInfo [tested]
- HISTORY: HistoryInfo [tested]
- TRADE: TradingRequest [testing]
- POSITIONS: GetPositions [tested]
- ORDERS: GetOrders [tested]
- RESET: ResetSubscriptionsAndIndicators

## TODOs

- Add and test live stream (price and event)
- Persistent history Data on SQLite Multithreading
- Read from Database
- test Modify order (client)
- test Modify position (client)
- test Stop Orders (client)
- test Limit Orders (client)
- fix timeframe error in histotical data collection e.g D1 for a year is suppose to be 365, but it is 262000+


## References

- https://github.com/ejtraderLabs/ejtraderMT
- https://github.com/JafferWilson/MT4-Ticks-To-MT5
