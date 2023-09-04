// Package assetprice contains the business logic for the assetprice entity
package assetprice

import (
	"time"
)

// BarData is a struct that contains the BarData information
type BarData struct {
	ID         string
	Symbol     string
	Timeframe  string
	Time       string
	Open       float64
	High       float64
	Low        float64
	Close      float64
	TickVolume float64
	RealVolume float64
	Spread     float64
	CreatedAt  time.Time
	UpdatedAt  time.Time
}
