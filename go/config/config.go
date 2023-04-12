package config

import (
	"github.com/spf13/viper"
)

func Load() {
	viper.AutomaticEnv()
	viper.SetDefault("DB_HOST", "localhost")
	viper.SetDefault("HTTP_LISTENNING_ADDR", "0.0.0.0:8080")
	viper.SetDefault("BESS_VAULT_ADDR", "http://localhost:8200/")
	viper.SetDefault("BESS_VAULT_TOKEN_PATH", "./vault/tokens/bess")
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

func GetVaultTokenPath() string {
	return viper.GetString("BESS_VAULT_TOKEN_PATH")
}
