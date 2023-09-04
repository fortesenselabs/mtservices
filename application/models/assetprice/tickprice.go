// Package assetprice contains the business logic for the assetprice entity
package assetprice

import (
	"time"
)

// TickData is a struct that contains the TickData information
type TickData struct {
	ID        string
	Symbol    string
	Timeframe string
	Time      string
	Bid       float64
	Ask       float64
	CreatedAt time.Time
	UpdatedAt time.Time
}
