// Package assetprice contains the business logic for the assetprice entity
package assetprice

// Service is the interface that provides tick and bar data methods
type Service interface {
	GetAllTicks() ([]*TickData, error)
	GetTickByID(string) (*TickData, error)
	GetOneTickByMap(map[string]interface{}) map[string]interface{}
	DeleteTick(string) error
	UpdateTick(string, map[string]interface{}) (*TickData, error)
	CreateTick(*TickData) (*TickData, error)

	// bar
	GetAllBars() ([]*BarData, error)
	GetBarByID(string) (*BarData, error)
	GetOneBarByMap(map[string]interface{}) map[string]interface{}
	DeleteBar(string) error
	UpdateBar(string, map[string]interface{}) (*BarData, error)
	CreateBar(*BarData) (*BarData, error)
}
