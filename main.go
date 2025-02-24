package main

import (
	"clickhouse-sql-processor/visitors"
	"flag"
	clickhouse "github.com/AfterShip/clickhouse-sql-parser/parser"
	"log"
	"log/slog"
	"os"
)

func main() {
	slog.SetLogLoggerLevel(slog.LevelDebug)

	queryFile := flag.String("query", "testdata/query_0.sql", "SQL query file")
	flag.Parse()

	data, err := os.ReadFile(*queryFile)
	if err != nil {
		log.Fatal(err)
	}

	parser := clickhouse.NewParser(string(data))
	statements, err := parser.ParseStmts()
	if err != nil {
		slog.Error("parse statements error", err)
		return
	}
	slog.Info("parsed and printing statements")
	for _, statement := range statements {
		slog.Debug("statement", "stmt", statement)
		tables, err := visitors.RunFindTables(statement)
		if err != nil {
			slog.Error("visitors.RunFindTables error", "err", err)
		}
		slog.Info("visitors.RunFindTables", "tables", tables)
	}
}
