// Package datamodels as a model of ClickHouse cluster/database.
// It describes tables so they can be used in queries and data generators.
// The model can be either load from a file or introspected from running
// clickhouse instance.
package datamodels

import (
	"fmt"
	"strings"
)

// ColumnType represents a ClickHouse column type.
type ColumnType string

// ColumnType represents a ClickHouse column type.
func (ct ColumnType) String() string {
	return string(ct)
}

// List of possible ClickHouse column types.
const (
	Int8                    ColumnType = "Int8"
	Int16                   ColumnType = "Int16"
	Int32                   ColumnType = "Int32"
	Int64                   ColumnType = "Int64"
	UInt8                   ColumnType = "UInt8"
	UInt16                  ColumnType = "UInt16"
	UInt32                  ColumnType = "UInt32"
	UInt64                  ColumnType = "UInt64"
	Float32                 ColumnType = "Float32"
	Float64                 ColumnType = "Float64"
	String                  ColumnType = "String"
	FixedString             ColumnType = "FixedString"
	Date                    ColumnType = "Date"
	DateTime                ColumnType = "DateTime"
	DateTime64              ColumnType = "DateTime64"
	UUID                    ColumnType = "UUID"
	Bool                    ColumnType = "Bool"
	Enum8                   ColumnType = "Enum8"
	Enum16                  ColumnType = "Enum16"
	LowCardinality          ColumnType = "LowCardinality"
	Array                   ColumnType = "Array"
	Tuple                   ColumnType = "Tuple"
	Map                     ColumnType = "Map"
	Decimal                 ColumnType = "Decimal"
	Decimal32               ColumnType = "Decimal32"
	Decimal64               ColumnType = "Decimal64"
	Decimal128              ColumnType = "Decimal128"
	IPv4                    ColumnType = "IPv4"
	IPv6                    ColumnType = "IPv6"
	Nullable                ColumnType = "Nullable"
	AggregateFunction       ColumnType = "AggregateFunction"
	SimpleAggregateFunction ColumnType = "SimpleAggregateFunction"
	Nothing                 ColumnType = "Nothing"
	JSON                    ColumnType = "JSON"
)

// Table represents a table in ClickHouse.
type Table struct {
	Name    string
	Columns []Column
	Engine  string
}

// Column represents a column in a table.
type Column struct {
	Name     string
	Type     ColumnType
	Nullable bool
}

// String returns a string representation of a table.
func (t Table) String() string {
	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("Table: %s\n", t.Name))
	sb.WriteString(fmt.Sprintf("Engine: %s\n", t.Engine))
	sb.WriteString("Columns:\n")
	for _, c := range t.Columns {
		sb.WriteString(fmt.Sprintf("  - %s %s", c.Name, string(c.Type)))
		if c.Nullable {
			sb.WriteString(" Nullable")
		}
		sb.WriteString("\n")
	}
	return sb.String()
}

// String returns a string representation of a column.
func (c Column) String() string {
	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("%s %s", c.Name, string(c.Type)))
	if c.Nullable {
		sb.WriteString(" Nullable")
	}
	return sb.String()
}

// Database represents a database in ClickHouse.
type Database struct {
	Name   string
	Tables []Table
}

// String returns a string representation of a database.
func (d Database) String() string {
	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("Database: %s\n", d.Name))
	sb.WriteString("Tables:\n")
	for _, t := range d.Tables {
		sb.WriteString(fmt.Sprintf("  - %s\n", t.Name))
	}
	return sb.String()
}

// Cluster represents a ClickHouse cluster.
type Cluster struct {
	Name      string
	Databases []Database
}

// String returns a string representation of a cluster.
func (c Cluster) String() string {
	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("Cluster: %s\n", c.Name))
	sb.WriteString("Databases:\n")
	for _, d := range c.Databases {
		sb.WriteString(fmt.Sprintf("  - %s\n", d.Name))
	}
	return sb.String()
}

// GetTable returns a table by name.
func (d Database) GetTable(tableName string) (*Table, error) {
	for _, t := range d.Tables {
		if t.Name == tableName {
			return &t, nil
		}
	}
	return nil, fmt.Errorf("table %s not found in database %s", tableName, d.Name)
}

// GetDatabase returns a database by name.
func (c Cluster) GetDatabase(databaseName string) (*Database, error) {
	for _, d := range c.Databases {
		if d.Name == databaseName {
			return &d, nil
		}
	}
	return nil, fmt.Errorf("database %s not found in cluster %s", databaseName, c.Name)
}

// GetColumn returns a column by name.
func (t Table) GetColumn(columnName string) (*Column, error) {
	for _, c := range t.Columns {
		if c.Name == columnName {
			return &c, nil
		}
	}
	return nil, fmt.Errorf("column %s not found in table %s", columnName, t.Name)
}

// GetTable returns a table by name.
func (c Cluster) GetTable(databaseName, tableName string) (*Table, error) {
	db, err := c.GetDatabase(databaseName)
	if err != nil {
		return nil, err
	}
	return db.GetTable(tableName)
}

// GetColumn returns a column by name.
func (c Cluster) GetColumn(databaseName, tableName, columnName string) (*Column, error) {
	table, err := c.GetTable(databaseName, tableName)
	if err != nil {
		return nil, err
	}
	return table.GetColumn(columnName)
}
