// Package tickprice contains the business logic for the tickprice entity
package tickprice

import tickPriceModel "github.com/FortesenseLabs/wisefinance-mtservices/application/models/assetprice"

func (tickPrice *TickData) toDomainMapper() *tickPriceModel.TickData {
	return &tickPriceModel.TickData{
		ID:        tickPrice.ID,
		Symbol:    tickPrice.Symbol,
		Timeframe: tickPrice.Timeframe,
		Time:      tickPrice.Time,
		Bid:       tickPrice.Bid,
		Ask:       tickPrice.Ask,
		CreatedAt: tickPrice.CreatedAt,
		UpdatedAt: tickPrice.UpdatedAt,
	}
}

func fromDomainMapper(tickPrice *tickPriceModel.TickData) *TickData {
	return &TickData{
		ID:        tickPrice.ID,
		Symbol:    tickPrice.Symbol,
		Timeframe: tickPrice.Timeframe,
		Time:      tickPrice.Time,
		Bid:       tickPrice.Bid,
		Ask:       tickPrice.Ask,
		CreatedAt: tickPrice.CreatedAt,
		UpdatedAt: tickPrice.UpdatedAt,
	}
}

func arrayToDomainMapper(tickPrices *[]TickData) *[]tickPriceModel.TickData {
	tickPricesModel := make([]tickPriceModel.TickData, len(*tickPrices))
	for i, tickPrice := range *tickPrices {
		tickPricesModel[i] = *tickPrice.toDomainMapper()
	}

	return &tickPricesModel
}
