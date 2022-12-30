package main

import (
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/gorilla/mux"
)

const HTTP_LISTENNING_ADDR = "0.0.0.0:8080"

func main() {
	r := mux.NewRouter()
	r.HandleFunc("/", HomeHandler)
	r.HandleFunc("/q", QueryDBHandler)

	http.Handle("/", r)

	srv := &http.Server{
		Handler:      r,
		Addr:         HTTP_LISTENNING_ADDR,
		WriteTimeout: 15 * time.Second,
		ReadTimeout:  15 * time.Second,
	}

	fmt.Println("Running BESS Go server on port 8080")

	log.Fatal(srv.ListenAndServe())
}

func HomeHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "Hey from BESS server !")
}

func QueryDBHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "Receive commande to query DB")
}
