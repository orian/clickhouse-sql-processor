package main

import (
	"clickhouse-sql-processor/datamodels"
	"context"
	"database/sql"
	"fmt"
	_ "github.com/ClickHouse/clickhouse-go/v2"
	"log"
	"log/slog"
)

func main() {
	slog.SetLogLoggerLevel(slog.LevelDebug)
	// Replace with your ClickHouse connection details
	dsn := "clickhouse://default:@localhost:9000/movie_rentals"

	db, err := sql.Open("clickhouse", dsn)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	// Test the connection
	if err := db.Ping(); err != nil {
		log.Fatal(err)
	}

	cluster, err := datamodels.IntrospectCluster(context.Background(), db, "my_cluster")
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println(cluster)
	for _, database := range cluster.Databases {
		fmt.Println(database)
		for _, table := range database.Tables {
			fmt.Println(table)
		}
	}
}
