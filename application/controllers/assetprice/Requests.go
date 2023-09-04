package assetprice

// Tick Data
type TickData struct {
	Symbol    string        `json:"symbol"`
	Timeframe string        `json:"timeframe"`
	Tick      []interface{} `json:"tick"`
}

type TickEvent struct {
	Event string   `json:"event"`
	Data  TickData `json:"data"`
}

// Bar Data
type BarData struct {
	Bar       [][]interface{} `json:"bar"`
	Symbol    string          `json:"symbol"`
	Timeframe string          `json:"timeframe"`
}

type BarEvent struct {
	Event string  `json:"event"`
	Data  BarData `json:"data"`
}
