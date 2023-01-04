package main

import (
	"fmt"
	"log"
	"net/http"
	"time"

	"bess/config"
	"bess/vault"

	"github.com/gorilla/mux"
)

type HTTPServer struct {
	vc *vault.VaultClient
	r  *mux.Router
}

func NewHTTPServer(vc *vault.VaultClient) *HTTPServer {
	hs := HTTPServer{
		vc: vc,
		r:  mux.NewRouter(),
	}

	hs.r.HandleFunc("/", hs.homeHandler)
	hs.r.HandleFunc("/q", hs.queryDBHandler)
	hs.r.HandleFunc("/creds", hs.requestVaultCredsHandler)

	http.Handle("/", hs.r)

	return &hs
}

func (s *HTTPServer) Listen() error {
	srv := &http.Server{
		Handler:      s.r,
		Addr:         config.GetHTTPListenningAddr(),
		WriteTimeout: 15 * time.Second,
		ReadTimeout:  15 * time.Second,
	}

	log.Printf("BESS HTTP server listenning on %v\n", config.GetHTTPListenningAddr())

	return srv.ListenAndServe()
}

func (s *HTTPServer) homeHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "Hey from BESS server !")
}

func (s *HTTPServer) queryDBHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "Receive commande to query DB")
}

func (s *HTTPServer) requestVaultCredsHandler(w http.ResponseWriter, r *http.Request) {
	log.Printf("Receive command to request vault creds\n")

	_, err := s.vc.GetDBCredentials()
	if err != nil {
		msg := fmt.Sprintf("Unable to retrieve credentials on Vault: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, msg)
		return
	}

	fmt.Fprintf(w, "credentials sucessfully received")
	w.WriteHeader(http.StatusOK)
}
