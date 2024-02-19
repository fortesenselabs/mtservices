package metatrader

import (
	"log"
	"os"

	"github.com/FortesenseLabs/wisefinance-mtservices/clients/go-metatrader/models"
)

type MetaTrader struct {
	Host              string
	RealVolume        bool
	Debug             bool
	AuthorizationCode string
	InstrumentLookup  []string
	API               *MTFunctions
}

func NewMetaTrader(host string, realVolume bool, debug bool, authorizationCode string, instrumentLookup []string) *MetaTrader {
	if debug {
		log.SetFlags(log.LstdFlags | log.Lmicroseconds)
		log.SetOutput(os.Stdout)
	}

	api := NewMTFunctions(host, 1122, debug, instrumentLookup, authorizationCode)

	return &MetaTrader{
		Host:              host,
		RealVolume:        realVolume,
		Debug:             debug,
		AuthorizationCode: authorizationCode,
		InstrumentLookup:  instrumentLookup,
		API:               api,
	}
}

func (mt *MetaTrader) Connect() {
	mt.API.Connect()
}

func (mt *MetaTrader) Disconnect() {
	mt.API.Disconnect()
}

// func (mt *MetaTrader) GetOrders() (*models.OrdersResponse, error) {
// 	return mt.API.SendCommand("ORDERS")
// }

// func (mt *MetaTrader) GetPositions() (*models.PositionsResponse, error) {
// 	return mt.API.SendCommand("POSITIONS")
// }

// func (mt *MetaTrader) GetAccountInfo() (*models.AccountInfoResponse, error) {
// 	return mt.API.SendCommand("ACCOUNT")
// }

func (mt *MetaTrader) GetBalance() (*models.BalanceResponse, error) {
	var response *models.BalanceResponse
	err := mt.API.SendCommand("BALANCE", response)
	if err != nil {
		return nil, nil
	}

	return response, nil
}

// func (mt *MetaTrader) GetHistoricalData(symbol string, timeFrame string, actionType string, from string, to string) (*models.HistoricalDataResponse, error) {
// 	fromDate, err := utils.ConvertDateToUTC(from, "02-01-2006 15:04:05")
// 	if err != nil {
// 		return nil, err
// 	}

// 	toDate, err := utils.ConvertDateToUTC(to, "02-01-2006 15:04:05")
// 	if err != nil {
// 		return nil, err
// 	}

// 	command := "HISTORY|symbol=" + symbol + "|timeFrame=" + timeFrame + "|actionType=" + actionType + "|from=" + fromDate + "|to=" + toDate

// 	return mt.API.SendCommand(command)
// }

// func (mt *MetaTrader) Buy(symbol string, volume float64, stoploss float64, takeprofit float64, deviation float64) (*models.TradeResponse, error) {
// 	return mt.trade(symbol, "ORDER_TYPE_BUY", volume, stoploss, takeprofit, 0, deviation)
// }

// func (mt *MetaTrader) Sell(symbol string, volume float64, stoploss float64, takeprofit float64, deviation float64) (*models.TradeResponse, error) {
// 	return mt.trade(symbol, "ORDER_TYPE_SELL", volume, stoploss, takeprofit, 0, deviation)
// }

// func (mt *MetaTrader) BuyLimit(symbol string, volume float64, stoploss float64, takeprofit float64, price float64, deviation float64) (*models.TradeResponse, error) {
// 	return mt.trade(symbol, "ORDER_TYPE_BUY_LIMIT", volume, stoploss, takeprofit, price, deviation)
// }

// func (mt *MetaTrader) SellLimit(symbol string, volume float64, stoploss float64, takeprofit float64, price float64, deviation float64) (*models.TradeResponse, error) {
// 	return mt.trade(symbol, "ORDER_TYPE_SELL_LIMIT", volume, stoploss, takeprofit, price, deviation)
// }

// func (mt *MetaTrader) BuyStop(symbol string, volume float64, stoploss float64, takeprofit float64, price float64, deviation float64) (*models.TradeResponse, error) {
// 	return mt.trade(symbol, "ORDER_TYPE_BUY_STOP", volume, stoploss, takeprofit, price, deviation)
// }

// func (mt *MetaTrader) SellStop(symbol string, volume float64, stoploss float64, takeprofit float64, price float64, deviation float64) (*models.TradeResponse, error) {
// 	return mt.trade(symbol, "ORDER_TYPE_SELL_STOP", volume, stoploss, takeprofit, price, deviation)
// }

// func (mt *MetaTrader) trade(symbol string, actionType string, volume float64, stoploss float64, takeprofit float64, price float64, deviation float64) (*models.TradeResponse, error) {
// 	actions := []string{
// 		"ORDER_TYPE_BUY",
// 		"ORDER_TYPE_SELL",
// 		"ORDER_TYPE_BUY_LIMIT",
// 		"ORDER_TYPE_SELL_LIMIT",
// 		"ORDER_TYPE_BUY_STOP",
// 		"ORDER_TYPE_SELL_STOP",
// 	}

// 	var command string
// 	if len(symbol) == 0 && !utils.Contains(actions, actionType) {
// 		id := string(time.Now().Unix())
// 		expiration := 0 // int(time.time()) + 60 * 60 * 24  # 1 day
// 		command = "TRADE|id=" + id + "|actionType=" + actionType + "|symbol=" + symbol + "|volume=" + strconv.FormatFloat(volume, 'f', -1, 64) + "|price=" + strconv.FormatFloat(price, 'f', -1, 64) + "|stoploss=" + strconv.FormatFloat(stoploss, 'f', -1, 64) + "|takeprofit=" + strconv.FormatFloat(takeprofit, 'f', -1, 64) + "|expiration=" + strconv.Itoa(expiration) + "|deviation=" + strconv.FormatFloat(deviation, 'f', -1, 64)
// 		// return mt.API.SendCommand("TRADE|id=" + id + "|actionType=" + actionType + "|symbol=" + symbol + "|volume=" + strconv.FormatFloat(volume, 'f', -1, 64) + "|price=" + strconv.FormatFloat(price, 'f', -1, 64) + "|stoploss=" + strconv.FormatFloat(stoploss, 'f', -1, 64) + "|takeprofit=" + strconv.FormatFloat(takeprofit, 'f', -1, 64) + "|deviation=" + strconv.FormatFloat(deviation, 'f', -1, 64))
// 	}

// 	return mt.API.SendCommand(command)
// }

// func (mt *MetaTrader) CancelOrderByTicketID(id int) (*models.TradeResponse, error) {
// 	symbol := ""
// 	volume := 0.0
// 	price := 0.0
// 	stoploss := 0.0
// 	takeprofit := 0.0
// 	// expiration := 0
// 	deviation := 0.0
// 	comment := "cancel order"

// 	return mt.trade(symbol, "ORDER_CANCEL", volume, stoploss, takeprofit, price, deviation, comment, id)
// }

// func (mt *MetaTrader) ClosePositionByTicketID(id int) (*models.TradeResponse, error) {
// 	symbol := ""
// 	volume := 0.0
// 	price := 0.0
// 	stoploss := 0.0
// 	takeprofit := 0.0
// 	// expiration := 0
// 	deviation := 0.0
// 	comment := "close position"

// 	return mt.trade(symbol, "POSITION_CLOSE_ID", volume, stoploss, takeprofit, price, deviation, comment, id)
// }

// func (mt *MetaTrader) ClosePositionBySymbol(symbol string) (*models.TradeResponse, error) {
// 	id := ""
// 	volume := 0.0
// 	price := 0.0
// 	stoploss := 0.0
// 	takeprofit := 0.0
// 	// expiration := 0
// 	deviation := 0.0
// 	comment := "close position"

// 	return mt.trade(symbol, "POSITION_CLOSE_SYMBOL", volume, stoploss, takeprofit, price, deviation, comment, id)
// }

// func (mt *MetaTrader) ClosePartialPosition(positionID int, volume float64) (*models.TradeResponse, error) {
// 	symbol := ""
// 	price := 0.0
// 	stoploss := 0.0
// 	takeprofit := 0.0
// 	// expiration := 0
// 	deviation := 0.0
// 	comment := "close position"

// 	return mt.trade(symbol, "POSITION_PARTIAL", volume, stoploss, takeprofit, price, deviation, comment, positionID)
// }

// func (mt *MetaTrader) CancelAllOrders() (*models.TradeResponse, error) {
// 	orders, err := mt.GetOrders()
// 	if err != nil {
// 		return nil, err
// 	}

// 	for _, order := range orders.Orders {
// 		_, err := mt.CancelOrderByTicketID(order.ID)
// 		if err != nil {
// 			return nil, err
// 		}
// 	}

// 	return nil, nil
// }

// func (mt *MetaTrader) CloseAllPositions() (*models.TradeResponse, error) {
// 	positions, err := mt.GetPositions()
// 	if err != nil {
// 		return nil, err
// 	}

// 	for _, position := range positions.Positions {
// 		_, err := mt.ClosePositionByTicketID(position.ID)
// 		if err != nil {
// 			return nil, err
// 		}
// 	}

// 	return nil, nil
// }
