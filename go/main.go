package main

import (
	"log"

	"bess/config"
	"bess/vault"
)

func main() {
	config.Load()

	vc, err := vault.NewVaultClient()
	if err != nil {
		log.Fatal(err)
	}

	s := NewHTTPServer(vc)

	log.Fatal(s.Listen())
}
