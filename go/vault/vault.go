package vault

import (
	"fmt"
	"log"

	"bess/config"

	vault_api "github.com/hashicorp/vault/api"
)

type VaultClient struct {
	c *vault_api.Client
}

func NewVaultClient(tk string) (*VaultClient, error) {
	cfg := vault_api.DefaultConfig()
	cfg.Address = config.GetVaultAddr()

	client, err := vault_api.NewClient(cfg)
	if err != nil {
		return nil, err
	}

	client.SetToken(tk)

	return &VaultClient{c: client}, nil
}

// GetDBCredentials returns vault credentials from
// 'database/creds/readonly' PATH.
// Return = user, password, error
func (vc *VaultClient) GetDBCredentials() (string, string, error) {
	secret, err := vc.c.Logical().Read("database/creds/readonly")
	if err != nil {
		return "", "", err
	}
	u := fmt.Sprintf("%s", secret.Data["username"])
	p := fmt.Sprintf("%s", secret.Data["password"])
	//NOTE: this prints are done for pedagical purpose
	// if you do this in production code, it is highly
	// probable that someone burns you at any point.
	log.Printf("DB user = %v\n", u)
	log.Printf("DB pwd = %v\n", p)

	return u, p, nil
}
