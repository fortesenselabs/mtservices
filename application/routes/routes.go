package routes

import (
	"github.com/FortesenseLabs/wisefinance-mtservices/application/adapter"
	"github.com/FortesenseLabs/wisefinance-mtservices/application/utils/logger"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func ApplicationV1Router(router *gin.Engine, db *gorm.DB, logger *logger.Logger) {
	routerV1 := router.Group("/api")
	{
		// Home
		WelcomeRoutes(routerV1)
		HealthRoutes(routerV1)

		AssetPriceRoutes(routerV1, adapter.AssetPriceAdapter(logger, db))

	}
}

// router.GET("/", application.IndexController)
// router.GET("/health", application.HealthStatusController)
// router.GET("/command", application.ClientCommandController)
