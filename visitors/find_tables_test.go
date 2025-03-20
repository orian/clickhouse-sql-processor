package visitors

import (
	"github.com/AfterShip/clickhouse-sql-parser/parser"
	"github.com/stretchr/testify/assert"
	"testing"
)

func TestFindTables_VisitTableIdentifier(t *testing.T) {
	testCases := []struct {
		name          string
		tableExpr     *parser.TableIdentifier
		expectedNames []string
	}{
		{
			name: "Single table",
			tableExpr: &parser.TableIdentifier{
				Table: &parser.Ident{Name: "table1"},
			},
			expectedNames: []string{"table1"},
		},
		{
			name: "Database and table",
			tableExpr: &parser.TableIdentifier{
				Database: &parser.Ident{Name: "db1"},
				Table:    &parser.Ident{Name: "table2"},
			},
			expectedNames: []string{"db1.table2"},
		},
		{
			name: "Empty table name",
			tableExpr: &parser.TableIdentifier{
				Table: &parser.Ident{Name: ""},
			},
			expectedNames: []string{""},
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			v := NewFindTables()
			err := v.VisitTableIdentifier(tc.tableExpr)
			assert.NoError(t, err)
			assert.Equal(t, tc.expectedNames, v.Names)
		})
	}
}

func TestFindTables_RunFindTables(t *testing.T) {
	testCases := []struct {
		name          string
		sql           string
		expectedNames []string
		expectedError bool
	}{
		{
			name:          "Simple SELECT",
			sql:           "SELECT * FROM table1",
			expectedNames: []string{"table1"},
			expectedError: false,
		},
		{
			name:          "SELECT with database",
			sql:           "SELECT * FROM db1.table2",
			expectedNames: []string{"db1.table2"},
			expectedError: false,
		},
		{
			name:          "SELECT with alias",
			sql:           "SELECT * FROM table1 AS t",
			expectedNames: []string{"table1"},
			expectedError: false,
		},
		{
			name:          "SELECT with join",
			sql:           "SELECT * FROM table1 JOIN table2 ON table1.id = table2.id",
			expectedNames: []string{"table1", "table2"},
			expectedError: false,
		},
		{
			name:          "SELECT with subquery",
			sql:           "SELECT * FROM (SELECT * FROM table1)",
			expectedNames: []string{"table1"},
			expectedError: false,
		},
		{
			name:          "SELECT with multiple tables",
			sql:           "SELECT * FROM table1, table2",
			expectedNames: []string{"table1", "table2"},
			expectedError: false,
		},
		{
			name:          "Empty query",
			sql:           "",
			expectedNames: []string{},
			expectedError: false,
		},
		{
			name:          "Invalid query",
			sql:           "SELECT * FROM",
			expectedNames: []string{},
			expectedError: true,
		},
		{
			name:          "insert query",
			sql:           "INSERT INTO table1 (col1, col2) VALUES (1, 2)",
			expectedNames: []string{"table1"},
			expectedError: false,
		},
		{
			name:          "insert query with db",
			sql:           "INSERT INTO db1.table1 (col1, col2) VALUES (1, 2)",
			expectedNames: []string{"db1.table1"},
			expectedError: false,
		},
		{
			name:          "alter table",
			sql:           "ALTER TABLE table1 ADD COLUMN col1 Int",
			expectedNames: []string{"table1"},
			expectedError: false,
		},
		{
			name:          "alter table with db",
			sql:           "ALTER TABLE db1.table1 ADD COLUMN col1 Int",
			expectedNames: []string{"db1.table1"},
			expectedError: false,
		},
		{
			name:          "create table",
			sql:           "CREATE TABLE table1 (col1 Int)",
			expectedNames: []string{"table1"},
			expectedError: false,
		},
		{
			name:          "create table with db",
			sql:           "CREATE TABLE db1.table1 (col1 Int)",
			expectedNames: []string{"db1.table1"},
			expectedError: false,
		},
		{
			name:          "drop table",
			sql:           "DROP TABLE table1",
			expectedNames: []string{"table1"},
			expectedError: false,
		},
		{
			name:          "drop table with db",
			sql:           "DROP TABLE db1.table1",
			expectedNames: []string{"db1.table1"},
			expectedError: false,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			parser := parser.NewParser(tc.sql)
			statements, err := parser.ParseStmts()
			if tc.expectedError {
				assert.Error(t, err)
				return
			}
			assert.NoError(t, err)
			if len(statements) == 0 {
				assert.Equal(t, tc.expectedNames, []string{})
				return
			}

			names, err := RunFindTables(statements[0])
			if tc.expectedError {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
				assert.Equal(t, tc.expectedNames, names)
			}
		})
	}
}
