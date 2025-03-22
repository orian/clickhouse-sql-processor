package main

import (
	"fmt"
	"log"
	"log/slog"

	"clickhouse-sql-processor/visitors"
	"github.com/AfterShip/clickhouse-sql-parser/parser"
)

func main() {
	slog.SetLogLoggerLevel(slog.LevelDebug)
	sql := "SELECT * FROM movie_rentals.rentals WHERE customer_id > 12 AND movie_id = 13 GROUP BY customer_id HAVING count(*) > 1"
	//sql := "SELECT * FROM movie_rentals.rentals"

	p := parser.NewParser(sql)
	node, err := p.ParseStmts()
	if err != nil {
		log.Fatal(err)
	}

	columns, err := visitors.RunFindPredicateColumns(node[0])
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Columns in predicates:", columns)
}
