package datamodels

import (
	"context"
	"database/sql"
	"fmt"
	"log/slog"
	"strings"

	_ "github.com/ClickHouse/clickhouse-go/v2" // Import the ClickHouse driver
)

// IntrospectCluster introspects a ClickHouse cluster and returns a Cluster object.
func IntrospectCluster(ctx context.Context, db *sql.DB, clusterName string) (*Cluster, error) {
	slog.Info("Introspecting ClickHouse cluster", "cluster", clusterName)

	databases, err := introspectDatabases(ctx, db)
	if err != nil {
		return nil, fmt.Errorf("failed to introspect databases: %w", err)
	}

	cluster := &Cluster{
		Name:      clusterName,
		Databases: databases,
	}

	slog.Info("Finished introspecting ClickHouse cluster", "cluster", clusterName)
	return cluster, nil
}

func introspectDatabases(ctx context.Context, db *sql.DB) ([]Database, error) {
	slog.Info("Introspecting ClickHouse databases")

	rows, err := db.QueryContext(ctx, "SHOW DATABASES")
	if err != nil {
		return nil, fmt.Errorf("failed to query databases: %w", err)
	}
	defer rows.Close()

	var databases []Database
	for rows.Next() {
		var dbName string
		if err := rows.Scan(&dbName); err != nil {
			return nil, fmt.Errorf("failed to scan database name: %w", err)
		}

		if dbName == "system" {
			continue // skip system database
		}

		slog.Info("Found database", "database", dbName)
		tables, err := introspectTables(ctx, db, dbName)
		if err != nil {
			return nil, fmt.Errorf("failed to introspect tables in database %s: %w", dbName, err)
		}

		databases = append(databases, Database{
			Name:   dbName,
			Tables: tables,
		})
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating over database rows: %w", err)
	}

	slog.Info("Finished introspecting ClickHouse databases")
	return databases, nil
}

func introspectTables(ctx context.Context, db *sql.DB, dbName string) ([]Table, error) {
	slog.Info("Introspecting ClickHouse tables", "database", dbName)

	rows, err := db.QueryContext(ctx, "SHOW TABLES FROM "+dbName)
	if err != nil {
		return nil, fmt.Errorf("failed to query tables in database %s: %w", dbName, err)
	}
	defer rows.Close()

	var tables []Table
	for rows.Next() {
		var tableName string
		if err := rows.Scan(&tableName); err != nil {
			return nil, fmt.Errorf("failed to scan table name: %w", err)
		}

		slog.Info("Found table", "database", dbName, "table", tableName)
		table, err := introspectTable(ctx, db, dbName, tableName)
		if err != nil {
			return nil, fmt.Errorf("failed to introspect table %s in database %s: %w", tableName, dbName, err)
		}
		tables = append(tables, *table)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating over table rows: %w", err)
	}

	slog.Info("Finished introspecting ClickHouse tables", "database", dbName)
	return tables, nil
}

func introspectTable(ctx context.Context, db *sql.DB, dbName, tableName string) (*Table, error) {
	slog.Info("Introspecting ClickHouse table", "database", dbName, "table", tableName)

	rows, err := db.QueryContext(ctx, fmt.Sprintf("DESCRIBE TABLE %s.%s", dbName, tableName))
	if err != nil {
		return nil, fmt.Errorf("failed to describe table %s.%s: %w", dbName, tableName, err)
	}
	defer rows.Close()

	var columns []Column
	var engine string
	for rows.Next() {
		var columnName, columnType, columnDefaultType, columnComment, codecExpression string
		var columnNullable string
		if err := rows.Scan(&columnName, &columnType, &columnDefaultType, &columnNullable, &columnComment, &codecExpression); err != nil {
			return nil, fmt.Errorf("failed to scan column description: %w", err)
		}
		if columnName == "engine" {
			engine = columnType
			continue
		}

		var nullable bool
		if strings.Contains(columnType, "Nullable") {
			nullable = true
			columnType = strings.ReplaceAll(columnType, "Nullable(", "")
			columnType = strings.ReplaceAll(columnType, ")", "")
		}

		columns = append(columns, Column{
			Name:     columnName,
			Type:     ColumnType(columnType),
			Nullable: nullable,
		})
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating over column rows: %w", err)
	}

	slog.Info("Finished introspecting ClickHouse table", "database", dbName, "table", tableName)
	return &Table{
		Name:    tableName,
		Columns: columns,
		Engine:  engine,
	}, nil
}
