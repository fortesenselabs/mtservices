package application

import (
	"fmt"
	"net/http"

	"github.com/FortesenseLabs/wisefinance-mtservices/application/utils/logger"
	"github.com/gin-gonic/gin"
)

func IndexController(c *gin.Context) {
	response := gin.H{
		"message": "Hello, Welcome to the Wisefinance MT Server!",
	}

	c.JSON(http.StatusOK, response)
}

func HealthStatusController(c *gin.Context) {
	response := gin.H{
		"message": "available",
	}

	c.JSON(http.StatusOK, response)
}

func BarPriceDataController(c *gin.Context) {
	var payload BarEvent
	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// time(timestamp) => time(timestamp) * 1e9
	// for data.bar [time(timestamp), open, high, low, close, tick_volume, spread, real_volume]
	// data, ok := payload.Data.(map[string]BarData)
	// if !ok {
	// 	c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid data format"})
	// 	return
	// }

	// barData := BarData{}
	// barData.Symbol, _ = data["symbol"].(string)
	// barData.Timeframe, _ = data["timeframe"].(string)
	// barData.Bar, _ = data["bar"].([][]float64)

	response := gin.H{
		"message":   "Data Received",
		"symbol":    payload.Data.Symbol,
		"timeframe": payload.Data.Timeframe,
		"bar":       payload.Data.Bar,
	}

	logger.Info(fmt.Sprintf("[BAR] Data Received: %v\n", response))

	// time_msc, _ := payload.Data.Bar[0][0].(string)
	// i, err := strconv.ParseInt(time_msc, 10, 64)
	// if err != nil {
	// 	panic(err)
	// }
	// timestamp := time.Unix(i, 0)
	logger.Info(fmt.Sprintf("Original Timestamp: %v | Processed Time: %v\n", payload.Data.Bar[0][0], payload.Data.Bar[0][0]))

	c.JSON(http.StatusOK, response)
}

func TickPriceDataController(c *gin.Context) {
	var payload TickEvent
	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// time(timestamp) => time(timestamp) * 1e12
	// for data.tick [time(timestamp), bid, ask]
	// data, ok := payload.Data.(map[string]interface{})
	// if !ok {
	// 	c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid data format"})
	// 	return
	// }

	// tickData := TickData{}
	// tickData.Symbol, _ = data["symbol"].(string)
	// tickData.Timeframe, _ = data["timeframe"].(string)
	// tickData.Tick, _ = data["tick"].([]float64)

	response := gin.H{
		"message":   "Data Received",
		"symbol":    payload.Data.Symbol,
		"timeframe": payload.Data.Timeframe,
		"tick":      payload.Data.Tick,
	}

	logger.Info(fmt.Sprintf("[TICK] Data Received: %v\n", response))

	// time_msc, _ := payload.Data.Tick[0].(string)
	// i, err := strconv.ParseInt(time_msc, 10, 64)
	// if err != nil {
	// 	panic(err)
	// }
	// timestamp := time.Unix(i, 0)
	logger.Info(fmt.Sprintf("Original Timestamp: %v | Processed Time: %v\n", payload.Data.Tick[0], payload.Data.Tick[0]))

	c.JSON(http.StatusOK, response)
}
