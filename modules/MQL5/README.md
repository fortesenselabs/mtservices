# MetaTrader 5 NATS Client

This is a metatrader 5 NATS messaging client

## How to run

```bash
git clone <repo>
```

- Copy contents of the server/MT5 folder to your <metatrader_5_folder>/MQL5
- Drag and drop the compiled EA in your Metatrader client

## Commands

- CONFIG: ScriptConfiguration [not-done]
- ACCOUNT: GetAccountInfo [not-done]
- BALANCE: GetBalanceInfo [not-done]
- HISTORY: HistoryInfo [not-done]
- TRADE: TradingRequest [not-done]
- POSITIONS: GetPositions [not-done]
- ORDERS: GetOrders [not-done]
- RESET: ResetSubscriptionsAndIndicators [not-done]

## TODOs

- Add and test live stream (price and event)
- Persistent history Data on SQLite Multithreading
- Read from Database
- test Modify order (client)
- test Modify position (client)
- test Stop Orders (client)
- test Limit Orders (client)
- fix timeframe error in histotical data collection e.g D1 for a year is suppose to be 365, but it is 262000+ -> This was for the REST server/client, we also have to test the nats client for it.
- Remove the chart event handler dependency => OnTickSymbol
- Implement a parser for parsing commands
- Implement a subscription manager (keep track of subscriptions)

## References

- https://github.com/ejtraderLabs/ejtraderMT
- https://github.com/JafferWilson/MT4-Ticks-To-MT5
