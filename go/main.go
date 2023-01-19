package main

import (
	"log"

	"bess/config"
)

func main() {
	config.Load()

	s := NewHTTPServer()

	log.Fatal(s.Listen())
}
