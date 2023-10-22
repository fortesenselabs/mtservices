package assetprice

import "time"

// MessageResponse is a struct that contains the response body for the message
type MessageResponse struct {
	Message string `json:"message"`
}

// ResponseTick is a struct that contains the response body for the tick data
type ResponseTick struct {
	CurrencyCode  string    `json:"currencyCode" example:"USD"`
	Balance       float64   `json:"balance" example:"0.00"`
	AccountNumber string    `json:"accountNumber" example:"2504201765"`
	CreatedAt     time.Time `json:"createdAt,omitempty" example:"2021-02-24 20:19:39" gorm:"autoCreateTime:mili"`
	UpdatedAt     time.Time `json:"updatedAt,omitempty" example:"2021-02-24 20:19:39" gorm:"autoUpdateTime:mili"`
}
