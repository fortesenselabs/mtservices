// parse all configs
package config

import (
	"fmt"
	"log"

	"github.com/spf13/viper"
)

// Set Config
func (config *Config) Read() error {
	filename := "config.json"

	viper.SetConfigFile(filename)

	if err := viper.ReadInConfig(); err != nil {
		configErr := fmt.Errorf("failed to read config file: %s", err)
		log.Fatalf("%v", configErr)
		return configErr
	}

	if err := viper.Unmarshal(&config); err != nil {
		configErr := fmt.Errorf("failed to unmarshal config: %s", err)
		log.Fatalf("%v", configErr)
		return configErr
	}

	// log.Info(fmt.Sprintf("%+v\n", config))
	return nil
}

// Get All Configs
func GetAllConfigs() *Config {
	var config Config

	// check for development or production environment here
	err := config.Read()
	if err != nil {
		_ = fmt.Errorf("fatal error in config file: %s", err.Error())
		panic(err)
	}

	return &config
}
