// Package routes contains all routes of the application
package routes

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// WelcomeRoutes is a function that contains all routes of the user
func WelcomeRoutes(router *gin.RouterGroup) {
	routerAuth := router.Group("/")
	{
		routerAuth.GET("/", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{"message": "Hello, Welcome to the Wisefinance MT Server!"})
		})
	}

}
