package config

import (
	"time"

	"gorm.io/gorm"
)

// Repository represents the repository using gorm
type Repository struct {
	DB *gorm.DB
}

// DBConfig represents db configuration
type DBConfig struct {
	Host     string
	Port     int
	User     string
	DBName   string
	Password string
}

type infoDatabaseSQL struct {
	Hostname   string
	Name       string
	Username   string
	Password   string
	Port       string
	Parameter  string
	DriverConn string
	UseSocket  bool
	SocketPath string
}

// All Configs

type Config struct {
	Environment string `mapstructure:"Environment"`
	Timezone    string `mapstructure:"Timezone"`
	ServerPort  int    `mapstructure:"ServerPort"`
	Secure      struct {
		Username    string          `mapstructure:"Username"`
		Password    string          `mapstructure:"Password"`
		IPWhiteList map[string]bool `mapstructure:"IPWhiteList"`
	} `mapstructure:"Secure"`
	Databases struct {
		MySQL struct {
			WiseFinanceDB struct {
				Hostname   string `mapstructure:"Hostname"`
				Name       string `mapstructure:"Name"`
				Username   string `mapstructure:"Username"`
				Password   string `mapstructure:"Password"`
				Port       string `mapstructure:"Port"`
				Parameter  string `mapstructure:"Parameter"`
				UseSocket  bool   `mapstructure:"UseSocket"`
				SocketPath string `mapstructure:"SocketPath"`
			} `mapstructure:"WiseFinanceDB"`
		} `mapstructure:"MySQL"`
	} `mapstructure:"Databases"`
	CronJobs struct {
		TaskWaitTimeMinute time.Duration `mapstructure:"TaskWaitTimeMinute"`
	} `mapstructure:"CronJobs"`
}
