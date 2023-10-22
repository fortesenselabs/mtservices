// Package adapter is a layer that connects the infrastructure with the application layer
package adapter

import (
	assetPriceController "github.com/FortesenseLabs/wisefinance-mtservices/application/controllers/assetprice"
	assetPriceService "github.com/FortesenseLabs/wisefinance-mtservices/application/services/assetprice"

	barPriceRepository "github.com/FortesenseLabs/wisefinance-mtservices/application/database/barprice"
	tickPriceRepository "github.com/FortesenseLabs/wisefinance-mtservices/application/database/tickprice"

	"github.com/FortesenseLabs/wisefinance-mtservices/application/utils/logger"
	"gorm.io/gorm"
)

// AssetPriceAdapter is a function that returns a asset price controller
func AssetPriceAdapter(logger *logger.Logger, db *gorm.DB) *assetPriceController.Controller {
	logger.Info("Attaching AssetPrice Adapter...")

	barRepository := barPriceRepository.Repository{
		Name:   "BarPriceRepository",
		DB:     db,
		Logger: logger}

	tickRepository := tickPriceRepository.Repository{
		Name:   "TickPriceRepository",
		DB:     db,
		Logger: logger}

	// logger.Info("Initialize Cache...")
	// cacheDuration := time.Minute * 1 // Cache duration, adjust as needed (1, 3, 5, 10)
	// c := cache.New(cacheDuration, cacheDuration)

	service := assetPriceService.Service{
		Name:                "AssetPriceService",
		BarPriceRepository:  barRepository,
		TickPriceRepository: tickRepository,
		Logger:              logger}
	return &assetPriceController.Controller{
		Name:       "AssetPriceController",
		AssetPrice: service,
		Logger:     logger}
}
