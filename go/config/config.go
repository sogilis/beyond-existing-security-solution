package config

import (
	"github.com/spf13/viper"
)

func Load() {
	viper.AutomaticEnv()
	viper.SetDefault("DB_HOST", "localhost")
	viper.SetDefault("HTTP_LISTENNING_ADDR", "0.0.0.0:8080")
	viper.SetDefault("BESS_VAULT_ADDR", "localhost")
	viper.SetDefault("BESS_VAULT_SERVICE_TOKEN", "")
}

func GetDBHost() string {
	return viper.GetString("DB_HOST")
}

func GetHTTPListenningAddr() string {
	return viper.GetString("HTTP_LISTENNING_ADDR")
}

func GetVaultAddr() string {
	return viper.GetString("BESS_VAULT_ADDR")
}

func GetVaultToken() string {
	return viper.GetString("BESS_VAULT_SERVICE_TOKEN")
}
