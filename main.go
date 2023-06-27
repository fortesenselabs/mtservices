package main

import (
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/FortesenseLabs/wisefinance-mtservices/application"
	"github.com/FortesenseLabs/wisefinance-mtservices/application/utils/logger"
	limit "github.com/aviddiviner/gin-limit"
	"github.com/gin-gonic/gin"
)

// var allConfigs = config.GetAllConfigs()

func main() {
	// logger.InitLog(allConfigs.Services.GCP.ProjectID, "backend-log")
	logger.Info("Wisefinance MetaTrader Backend Server...")

	// const HOST = "127.0.0.1"
	const PORT = 9090

	router := gin.Default()
	router.Use(limit.MaxAllowed(200))

	router.GET("/", application.IndexController)
	router.GET("/health", application.HealthStatusController)
	router.POST("/api/price/stream/bar", application.BarPriceDataController)
	router.POST("/api/price/stream/tick", application.TickPriceDataController)

	logger.Info("Starting Server!!!")
	startServer(router, fmt.Sprintf(":%v", PORT))

}

func startServer(router http.Handler, serverPort string) {
	s := &http.Server{
		Addr:           serverPort,
		Handler:        router,
		ReadTimeout:    18000 * time.Second,
		WriteTimeout:   18000 * time.Second,
		MaxHeaderBytes: 1 << 20,
	}
	if err := s.ListenAndServe(); err != nil {
		_ = fmt.Errorf("fatal error description: %s", strings.ToLower(err.Error()))
		panic(err)

	}
}

// https://stackoverflow.com/questions/24987131/how-to-parse-unix-timestamp-to-time-time
