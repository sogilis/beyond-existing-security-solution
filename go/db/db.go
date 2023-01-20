package db

import (
	"bess/config"
	"context"
	"fmt"
	"os"

	"github.com/jackc/pgx/v5"
)

const PG_DEFAULT_PORT = "5432"
const DB_DEFAULT_HOST = "localhost"
const DEFAULT_DB_NAME = "bess"

type DBConnection struct {
	URL string
}

func NewDBConnection(user, pass string) DBConnection {
	return DBConnection{
		URL: generatePGURL(user, pass),
	}
}

// ConnectAndQuery opens a connection to the database,
// then query it, prints results and closes the connection.
func (dbc *DBConnection) ConnectAndQuery() (string, error) {
	conn, err := pgx.Connect(context.Background(), dbc.URL)
	if err != nil {
		return "", err
	}
	defer conn.Close(context.Background())

	var result string
	err = conn.QueryRow(context.Background(), "SELECT usename FROM pg_user;").Scan(&result)
	if err != nil {
		fmt.Fprintf(os.Stderr, "QueryRow failed: %v\n", err)
		return "", err
	}

	fmt.Printf("here's the databse query result: %v \n", result)
	return result, nil
}

func generatePGURL(user, pass string) string {
	return fmt.Sprintf("postgres://%s:%s@%s:%s/%s", user, pass, config.GetDBHost(), PG_DEFAULT_PORT, DEFAULT_DB_NAME)
}
