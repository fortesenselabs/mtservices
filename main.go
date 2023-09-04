package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/FortesenseLabs/wisefinance-mtservices/application/config"
	"github.com/FortesenseLabs/wisefinance-mtservices/application/database/migrations"

	"github.com/FortesenseLabs/wisefinance-mtservices/application/routes"
	"github.com/FortesenseLabs/wisefinance-mtservices/application/utils/logger"
	"github.com/gin-contrib/cors"

	limit "github.com/aviddiviner/gin-limit"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

var allConfigs = config.GetAllConfigs()

func main() {
	// Creates a logger.
	logger, err := logger.NewLogger("", "backend-log")
	if err != nil {
		logger.Fatal(fmt.Errorf("failed to initialize logger: %v", err))
	}

	// logger.InitLog(allConfigs.Services.GCP.ProjectID, "backend-log")
	logger.Info("Wisefinance MetaTrader Backend Server...")
	// Create a context for graceful shutdown
	_, cancel := context.WithCancel(context.Background())
	defer cancel()

	// const HOST = "127.0.0.1"
	// const PORT = 9090

	router := gin.Default()
	router.Use(limit.MaxAllowed(200))

	// Configure CORS
	// router.Use(cors.Default())
	corsConfig := cors.DefaultConfig()
	// corsConfig.AddAllowHeaders("Authorization")
	corsConfig.AllowAllOrigins = true
	router.Use(cors.New(corsConfig))

	logger.Info("Connecting to Database!!!")

	DB, err := config.GormOpen()
	if err != nil {
		logger.Fatal(fmt.Errorf("fatal error in database file: %s", err))
	}

	logger.Info("Running Auto Migrations...")
	migrations.RunAutoMigrations(logger, DB)

	logger.Info("Starting Server!!!")

	routes.ApplicationV1Router(router, DB, logger)

	// Start the server
	server := &http.Server{
		Addr:           fmt.Sprintf(":%v", allConfigs.ServerPort),
		Handler:        router,
		ReadTimeout:    18000 * time.Second,
		WriteTimeout:   18000 * time.Second,
		MaxHeaderBytes: 1 << 20,
	}

	go func() {
		startServer(logger, server, router)
	}()

	logger.Info("Server started")

	// Graceful shutdown
	gracefulShutdown(logger, server, cancel, DB)

}

func startServer(logger *logger.Logger, server *http.Server, router http.Handler) {
	if err := server.ListenAndServe(); err != nil {
		err = fmt.Errorf("fatal error description: %s", strings.ToLower(err.Error()))
		logger.Fatal(err)
	}
}

func gracefulShutdown(logger *logger.Logger, server *http.Server, cancel context.CancelFunc, dbConnection *gorm.DB) {
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)
	<-quit

	logger.Info("Server is shutting down...")

	// Set a timeout for graceful shutdown
	ctx, cancelShutdown := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancelShutdown()

	// Perform any cleanup or additional shutdown steps here

	// Close the database connection
	db, err := dbConnection.DB()
	if err != nil {
		logger.Error(fmt.Errorf("failed to get database connection: %v", err))
	}

	if err := db.Close(); err != nil {
		logger.Error(fmt.Errorf("failed to close database connection: %v", err))
	}

	// Shutdown the server
	if err := server.Shutdown(ctx); err != nil {
		logger.Error(fmt.Errorf("failed to gracefully shutdown server: %v", err))
	}

	cancel()

	logger.Info("Server has stopped")
}

// https://stackoverflow.com/questions/24987131/how-to-parse-unix-timestamp-to-time-time
// https://github.com/ejtraderLabs/ejtraderMT/
// https://learning-0mq-with-pyzmq.readthedocs.io/en/latest/pyzmq/patterns/pushpull.html
// https://github.com/ejtraderLabs/ejtraderMT/blob/master/ejtraderMT/api/mql.py
