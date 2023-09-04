// Package tickprice contains the business logic for the tickprice entity
package tickprice

import (
	"time"
)

// TickData is a struct that contains the tick price information
type TickData struct {
	ID        string    `json:"id" example:"d4c4d4a4-54c4-4d4c-a4d4-c454d4c4d4a4" gorm:"primaryKey"`
	Symbol    string    `json:"symbol" example:"EURUSD"`
	Timeframe string    `json:"timeframe" example:"1693776279131"`
	Time      string    `json:"time" example:"1693776279131"`
	Bid       float64   `json:"bid" example:"0.00"`
	Ask       float64   `json:"ask" example:"0.00"`
	CreatedAt time.Time `json:"created_at,omitempty" example:"2021-02-24 20:19:39" gorm:"autoCreateTime:mili"`
	UpdatedAt time.Time `json:"updated_at,omitempty" example:"2021-02-24 20:19:39" gorm:"autoUpdateTime:mili"`
}

// TableName overrides the table name used by Wallet to `wallets`
func (*TickData) TableName() string {
	return "ticks"
}
