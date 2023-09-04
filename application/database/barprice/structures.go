// Package barprice contains the business logic for the barprice entity
package barprice

import (
	"time"
)

// BarData is a struct that contains the bar price information
type BarData struct {
	ID         string    `json:"id" example:"d4c4d4a4-54c4-4d4c-a4d4-c454d4c4d4a4" gorm:"primaryKey"`
	Symbol     string    `json:"symbol" example:"user@mail.com"`
	Timeframe  string    `json:"timeframe" example:"08029938477"`
	Time       string    `json:"time" example:"08029938477"`
	Open       float64   `json:"open" example:"0.00"`
	High       float64   `json:"high" example:"0.00"`
	Low        float64   `json:"low" example:"0.00"`
	Close      float64   `json:"close" example:"0.00"`
	TickVolume float64   `json:"tick_volume" example:"0.00"`
	RealVolume float64   `json:"real_volume" example:"0.00"`
	Spread     float64   `json:"spread" example:"0.00"`
	CreatedAt  time.Time `json:"created_at,omitempty" example:"2021-02-24 20:19:39" gorm:"autoCreateTime:mili"`
	UpdatedAt  time.Time `json:"updated_at,omitempty" example:"2021-02-24 20:19:39" gorm:"autoUpdateTime:mili"`
}

// TableName overrides the table name used by Wallet to `wallets`
func (*BarData) TableName() string {
	return "bars"
}
