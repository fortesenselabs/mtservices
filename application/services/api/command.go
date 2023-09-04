package api

// func Command(**kwargs) -> dict:
// """Construct a request dictionary from default and send it to server"""

// # default dictionary
// request = {
// 	"action": None,
// 	"actionType": None,
// 	"symbol": None,
// 	"chartTF": None,
// 	"fromDate": None,
// 	"toDate": None,
// 	"id": None,
// 	"magic": None,
// 	"volume": None,
// 	"price": None,
// 	"stoploss": None,
// 	"takeprofit": None,
// 	"expiration": None,
// 	"deviation": None,
// 	"comment": None,
// 	"chartId": None,
// 	"indicatorChartId": None,
// 	"chartIndicatorSubWindow": None,
// 	"style": None,
// }

// # update dict values if exist
// for key, value in kwargs.items():
// 	if key in request:
// 		request[key] = value
// 	else:
// 		raise KeyError("Unknown key in **kwargs ERROR")

// # send dict to server
// self._send_request(request)

// # return server reply
// return self._pull_reply()
