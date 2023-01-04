package vault

import (
	"fmt"

	"bess/config"

	vault_api "github.com/hashicorp/vault/api"
)

type VaultClient struct {
	c *vault_api.Client
}

func NewVaultClient() (*VaultClient, error) {
	cfg := vault_api.DefaultConfig()
	cfg.Address = config.GetVaultAddr()

	client, err := vault_api.NewClient(cfg)
	if err != nil {
		return nil, err
	}

	client.SetToken(config.GetVaultToken())

	return &VaultClient{c: client}, nil
}

func (vc *VaultClient) GetDBCredentials() (string, error) {
	secret, err := vc.c.Logical().Read("database/creds/readonly")
	if err != nil {
		return "", err
	}

	fmt.Printf("Vault DB credentials = %v", secret)
	return "", nil
}
