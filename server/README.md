# MetaTrader 5 socket server

This is a metatrader 5 server using sockets
 
## How to run

```bash
git clone <repo>
```

- Copy contents of the server/MT5 folder to your <metatrader_5_folder>/MQL5
- Drag and drop the compiled EA in your Metatrader client 

## Commands

POST /sub - setup web hook. options: callback_url and callback_format (json or x-form)

GET /symbols/{name}/info - get symbol information.

GET /symbols/{name}/tick - get symbol ask/bid prices.

GET /account/info - get account details, number of  orders, number of positions

GET /positions - returns list of positions

GET /positions/{id} - return position by id

GET /deals?offset={offset}&limit={limit} - returns list of deals/transactions 

GET /deals/{id} - return deal by id

GET /orders - returns list of orders

GET /orders/{id} - return order by id

GET /history - returns list of history orders

GET /history/{id} - return order history by id

POST /trade - open position, details in POST body

# Example of POST body for trade command

## Open Buy
```json
{ 
  "symbol":"EURUSD", 
  "actionType": "ORDER_TYPE_BUY", 
  "volume": 0.1, 
  "stoploss": 1.3455, 
  "takeprofit": 1.33333, 
  "comment": "test buy"
}
```

## Open Sell
```json
{ 
  "symbol":"EURUSD", 
  "actionType": "ORDER_TYPE_SELL", 
  "volume": 0.1, 
  "stoploss": 1.3455, 
  "takeprofit": 1.33333, 
  "comment": "test buy"
}
```

## Open Buy Limit
```json
{ 
  "symbol":"EURUSD", 
  "actionType": "ORDER_TYPE_BUY_LIMIT", 
  "price": 1.4444, 
  "volume": 0.1, 
  "stoploss": 1.3455, 
  "takeprofit": 1.33333, 
  "comment": "test buy limit"
}
```

## Open Sell Limit
```json
{ 
  "symbol":"EURUSD", 
  "actionType": "ORDER_TYPE_SELL_LIMIT", 
  "price": 1.4444,
  "volume": 0.1, 
  "stoploss": 1.3455, 
  "takeprofit": 1.33333, 
  "comment": "test sell limit"
}
```

## Open Buy Stop
```json
{ 
  "symbol":"EURUSD", 
  "actionType": 
  "ORDER_TYPE_BUY_STOP", 
  "price": 1.4444, 
  "volume": 0.1, 
  "stoploss": 1.3455, 
  "takeprofit": 1.33333, 
  "comment": "test buy stop"
}
```

## Open Sell Stop
```json
{ 
  "symbol":"EURUSD", 
  "actionType": "ORDER_TYPE_SELL_STOP", 
  "price": 1.4444, 
  "volume": 0.1, 
  "stoploss": 1.3455, 
  "takeprofit": 1.33333, 
  "comment": "test sell stop"
}  
```

## Position Close by ID
```json
{ "actionType": "POSITION_CLOSE_ID", "id": 1212121 }
```

## Order Cancel
```json
{ "actionType": "ORDER_CANCEL", "id": 1212121 }
```

## Order Cancel
```json
{ "actionType": "POSITION_PARTIAL", "id": 1212121, "volume": 0.1 }
```


# Examples of /trade output
```json
{
    "error": 10018,
    "desription": "TRADE_RETCODE_MARKET_CLOSED",
    "order_id": 0,
    "volume": 0,
    "price": 0,
    "bid": 0,
    "ask": 0,
    "function": "CRestApi::tradingModule"
}
```
```json
{
    "error": 10009,
    "desription": "TRADE_RETCODE_DONE",
    "order_id": 405895526,
    "volume": 0.1,
    "price": 1.13047,
    "bid": 1.13038,
    "ask": 1.13047,
    "function": "CRestApi::tradingModule"
}
```
