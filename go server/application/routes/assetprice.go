// Package routes contains all routes of the application
package routes

import (
	assetPriceController "github.com/FortesenseLabs/wisefinance-mtservices/application/controllers/assetprice"
	"github.com/gin-gonic/gin"
)

// AssetPriceRoutes is a function that contains all routes of asset price
func AssetPriceRoutes(router *gin.RouterGroup, controller *assetPriceController.Controller) {
	routerAuth := router.Group("/price")

	routerAuth.POST("/stream/bar", controller.BarPriceDataController)
	routerAuth.POST("/stream/tick", controller.TickPriceDataController)
}

// router.POST("/api/price/stream/bar", application.BarPriceDataController)
// router.POST("/api/price/stream/tick", application.TickPriceDataController)
