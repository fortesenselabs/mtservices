package assetprice

import (
	tickPriceModel "github.com/FortesenseLabs/wisefinance-mtservices/application/models/assetprice"
)

func mapToModelfromTickDataRequest(tickEvent *TickEvent) (tickData *tickPriceModel.TickData) {
	tickData = &tickPriceModel.TickData{
		Symbol:    tickEvent.Data.Symbol,
		Timeframe: tickEvent.Data.Timeframe,
		Time:      tickEvent.Data.Tick[0].(string),
		Bid:       tickEvent.Data.Tick[1].(float64),
		Ask:       tickEvent.Data.Tick[2].(float64)}

	return
}
