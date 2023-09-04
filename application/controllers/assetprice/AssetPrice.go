package assetprice

import (
	"fmt"
	"net/http"

	errorsModel "github.com/FortesenseLabs/wisefinance-mtservices/application/models/errors"
	AssetPrice "github.com/FortesenseLabs/wisefinance-mtservices/application/services/assetprice"

	"github.com/FortesenseLabs/wisefinance-mtservices/application/utils/logger"
	"github.com/gin-gonic/gin"
)

// Controller is a struct that contains the asset price service
type Controller struct {
	Name       string
	AssetPrice AssetPrice.Service
	Logger     *logger.Logger
}

func (c *Controller) TickPriceDataController(ctx *gin.Context) {
	var payload *TickEvent
	if err := ctx.ShouldBindJSON(&payload); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
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

	tick, err := c.AssetPrice.CreateTick(mapToModelfromTickDataRequest(payload))
	if err != nil {
		appError := errorsModel.NewAppError(c.Logger, err, errorsModel.ExternalServiceError)
		_ = ctx.Error(appError)
		return
	}

	response := gin.H{
		"message": "Data Received",
		"symbol":  tick.Symbol,
		"time":    tick.Time,
		"bid":     tick.Bid,
		"ask":     tick.Ask,
		"command": "", //  send command through either a get request route or the ticks price data route
	}

	c.Logger.Info(fmt.Sprintf("[TICK] Data Received: %v\n", response))

	// time_msc, _ := payload.Data.Tick[0].(string)
	// i, err := strconv.ParseInt(time_msc, 10, 64)
	// if err != nil {
	// 	panic(err)
	// }
	// timestamp := time.Unix(i, 0)
	c.Logger.Info(fmt.Sprintf("Original Timestamp: %v | Processed Time: %v\n", payload.Data.Tick[0], payload.Data.Tick[0]))

	ctx.JSON(http.StatusOK, response)
}

func (c *Controller) BarPriceDataController(ctx *gin.Context) {
	var payload BarEvent

	if err := ctx.ShouldBindJSON(&payload); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
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

	c.Logger.Info(fmt.Sprintf("[BAR] Data Received: %v\n", response))

	// time_msc, _ := payload.Data.Bar[0][0].(string)
	// i, err := strconv.ParseInt(time_msc, 10, 64)
	// if err != nil {
	// 	panic(err)
	// }
	// timestamp := time.Unix(i, 0)
	c.Logger.Info(fmt.Sprintf("Original Timestamp: %v | Processed Time: %v\n", payload.Data.Bar[0][0], payload.Data.Bar[0][0]))

	ctx.JSON(http.StatusOK, response)
}
