// Package config provides the database connection
package config

import (
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
	"gorm.io/plugin/dbresolver"
)

// GormOpen is a function that returns a gorm database connection using  initial configuration
func GormOpen() (gormDB *gorm.DB, err error) {
	var infoDatabase infoDatabaseSQL

	var allConfigs = GetAllConfigs()

	err = infoDatabase.getDiverConn(allConfigs.Databases.MySQL.WiseFinanceDB)
	if err != nil {
		return nil, err
	}
	gormDB, err = gorm.Open(mysql.Open(infoDatabase.DriverConn), &gorm.Config{
		PrepareStmt: true,
		Logger:      logger.Default.LogMode(logger.Silent),
	})
	if err != nil {
		return
	}

	dialector := mysql.New(mysql.Config{
		DSN: infoDatabase.DriverConn,
	})

	err = gormDB.Use(dbresolver.Register(dbresolver.Config{
		Replicas: []gorm.Dialector{dialector},
	}))
	if err != nil {
		return nil, err
	}
	var result int

	// Test the connection by executing a simple query
	if err = gormDB.Raw("SELECT 1").Scan(&result).Error; err != nil {
		return nil, err
	}

	return
}
