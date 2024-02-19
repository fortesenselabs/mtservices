package models

type BalanceResponse struct { // Balance response (correct this)
	Balance    float64 `json:"balance"`
	Equity     float64 `json:"equity"`
	Margin     float64 `json:"margin"`
	MarginFree float64 `json:"margin_free"`
}
