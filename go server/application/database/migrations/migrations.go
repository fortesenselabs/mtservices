package migrations

import (
	"fmt"

	barPriceRepository "github.com/FortesenseLabs/wisefinance-mtservices/application/database/barprice"
	tickPriceRepository "github.com/FortesenseLabs/wisefinance-mtservices/application/database/tickprice"

	"github.com/FortesenseLabs/wisefinance-mtservices/application/utils/logger"
	"gorm.io/gorm"
)

func RunAutoMigrations(logger *logger.Logger, db *gorm.DB) {
	// List of models to migrate
	models := []interface{}{
		&tickPriceRepository.TickData{},
		&barPriceRepository.BarData{}, // Add BarData model here
	}

	// Auto-migrate the list of models here
	for _, model := range models {
		err := db.AutoMigrate(model)
		if err != nil {
			logger.Fatal(fmt.Errorf("failed to auto-migrate model: %v", err))
		}
	}

	logger.Info("Auto-migrations completed successfully.")
}
