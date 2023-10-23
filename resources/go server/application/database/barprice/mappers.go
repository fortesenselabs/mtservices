// Package barprice contains the business logic for the barprice entity
package barprice

import barPriceModel "github.com/FortesenseLabs/wisefinance-mtservices/application/models/assetprice"

func (barPrice *BarData) toDomainMapper() *barPriceModel.BarData {
	return &barPriceModel.BarData{
		ID:         barPrice.ID,
		Symbol:     barPrice.Symbol,
		Timeframe:  barPrice.Timeframe,
		Time:       barPrice.Time,
		Open:       barPrice.Open,
		High:       barPrice.High,
		Low:        barPrice.Low,
		Close:      barPrice.Close,
		TickVolume: barPrice.TickVolume,
		RealVolume: barPrice.RealVolume,
		Spread:     barPrice.Spread,
		CreatedAt:  barPrice.CreatedAt,
		UpdatedAt:  barPrice.UpdatedAt,
	}
}

func fromDomainMapper(barPrice *barPriceModel.BarData) *BarData {
	return &BarData{
		ID:         barPrice.ID,
		Symbol:     barPrice.Symbol,
		Timeframe:  barPrice.Timeframe,
		Time:       barPrice.Time,
		Open:       barPrice.Open,
		High:       barPrice.High,
		Low:        barPrice.Low,
		Close:      barPrice.Close,
		TickVolume: barPrice.TickVolume,
		RealVolume: barPrice.RealVolume,
		Spread:     barPrice.Spread,
		CreatedAt:  barPrice.CreatedAt,
		UpdatedAt:  barPrice.UpdatedAt,
	}
}

func arrayToDomainMapper(barPrices *[]BarData) *[]barPriceModel.BarData {
	barPricesModel := make([]barPriceModel.BarData, len(*barPrices))
	for i, barPrice := range *barPrices {
		barPricesModel[i] = *barPrice.toDomainMapper()
	}

	return &barPricesModel
}
