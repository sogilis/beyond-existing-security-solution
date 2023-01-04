package db

import (
	"context"
	"fmt"
	"os"

	"github.com/jackc/pgx/v5"
)

const PG_DEFAULT_PORT = "5432"
const DB_DEFAULT_HOST = "localhost"
const DEFAULT_DB_NAME = "bess"

type DBConnection struct {
	Username string
	Password string
	URL      string
}

func NewDBConnection(user, pass string) DBConnection {
	return DBConnection{
		Username: user,
		Password: pass,
		URL:      generatePGURL(user, pass),
	}
}

// ConnectAndQuery opens a connection to the database,
// then query it, prints results and closes the connection.
func ConnectAndQuery() error {
	conn, err := pgx.Connect(context.Background(), os.Getenv("DATABASE_URL"))
	if err != nil {
		return err
	}
	defer conn.Close(context.Background())

	// var name string
	// var weight int64
	// err = conn.QueryRow(context.Background(), "select name, weight from widgets where id=$1", 42).Scan(&name, &weight)
	// if err != nil {
	// 	fmt.Fprintf(os.Stderr, "QueryRow failed: %v\n", err)
	// 	os.Exit(1)
	// }

	fmt.Println("here's the databse query result !")
	return nil
}

func generatePGURL(user, pass string) string {
	return fmt.Sprintf("postgres://%s:%s@%s:%s/%s", user, pass, DB_DEFAULT_HOST, PG_DEFAULT_PORT, DEFAULT_DB_NAME)
}
