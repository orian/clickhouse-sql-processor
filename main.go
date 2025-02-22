package main

import (
	"clickhouse-sql-processor/visitors"
	clickhouse "github.com/AfterShip/clickhouse-sql-parser/parser"
	"log/slog"
)

func main() {
	slog.SetLogLoggerLevel(slog.LevelDebug)
	query := "SELECT `ch`.`id` as i, timestamp FROM clickhouse as ch WHERE ch.timestamp > '2025.02.12 15:32' AND timestamp < '2025.02.13 01:12'"
	parser := clickhouse.NewParser(query)
	// Parse query into AST
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
