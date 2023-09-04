package command

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func ClientCommandController(c *gin.Context) {
	response := gin.H{
		"command": "ACCOUNT",
	}

	c.JSON(http.StatusOK, response)
}
