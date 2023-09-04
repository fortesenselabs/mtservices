// Package routes contains all routes of the application
package routes

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// HealthRoutes is a function that contains all routes of the application health
func HealthRoutes(router *gin.RouterGroup) {
	routerAuth := router.Group("/health")
	{
		routerAuth.GET("", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{"message": "available"})
		})
	}

}

// update the health routes in the MQL client
