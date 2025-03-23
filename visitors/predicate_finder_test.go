package visitors

import (
	"testing"

	"github.com/AfterShip/clickhouse-sql-parser/parser"
	"github.com/stretchr/testify/assert"
)

func TestFindPredicateColumns_RunFindPredicateColumns(t *testing.T) {
	testCases := []struct {
		name               string
		sql                string
		expectedColumns    []string
		expectedPredicates []Predicate
		expectedError      bool
	}{
		{
			name:            "Simple WHERE clause",
			sql:             "SELECT * FROM table1 WHERE col1 > 10",
			expectedColumns: []string{"col1"},
			expectedPredicates: []Predicate{
				{Column: "col1", Operator: ">", Value: "10"},
			},
			expectedError: false,
		},
		{
			name:            "WHERE clause with AND",
			sql:             "SELECT * FROM table1 WHERE col1 > 10 AND col2 = 5",
			expectedColumns: []string{"col1", "col2"},
			expectedPredicates: []Predicate{
				{Column: "col1", Operator: ">", Value: "10"},
				{Column: "col2", Operator: "=", Value: "5"},
			},
			expectedError: false,
		},
		{
			name:            "WHERE clause with OR",
			sql:             "SELECT * FROM table1 WHERE col1 > 10 OR col2 = 5",
			expectedColumns: []string{"col1", "col2"},
			expectedPredicates: []Predicate{
				{Column: "col1", Operator: ">", Value: "10"},
				{Column: "col2", Operator: "=", Value: "5"},
			},
			expectedError: false,
		},
		{
			name:            "HAVING clause",
			sql:             "SELECT col1 FROM table1 GROUP BY col1 HAVING col2 > 10",
			expectedColumns: []string{"col1"},
			expectedPredicates: []Predicate{
				{Column: "col2", Operator: ">", Value: "10"},
			},
			expectedError: false,
		},
		{
			name:               "GROUP BY clause",
			sql:                "SELECT col1 FROM table1 GROUP BY col1",
			expectedColumns:    []string{"col1"},
			expectedPredicates: []Predicate{},
			expectedError:      false,
		},
		{
			name:               "No predicates",
			sql:                "SELECT * FROM table1",
			expectedColumns:    nil,
			expectedPredicates: nil,
			expectedError:      false,
		},
		{
			name:               "Invalid SQL",
			sql:                "SELECT * FROM",
			expectedColumns:    []string{},
			expectedPredicates: []Predicate{},
			expectedError:      true,
		},
		{
			name:            "Complex query",
			sql:             "SELECT * FROM table1 WHERE col1 > 10 AND col2 = 5 GROUP BY col3 HAVING col4 > 20",
			expectedColumns: []string{"col1", "col2", "col3", "col4"},
			expectedPredicates: []Predicate{
				{Column: "col1", Operator: ">", Value: "10"},
				{Column: "col2", Operator: "=", Value: "5"},
				{Column: "col4", Operator: ">", Value: "20"},
			},
			expectedError: false,
		},
		{
			name:            "Complex query with multiple tables",
			sql:             "SELECT * FROM table1 JOIN table2 ON table1.id = table2.id WHERE table1.col1 > 10 AND table2.col2 = 5 GROUP BY table1.col3 HAVING table2.col4 > 20",
			expectedColumns: []string{"col1", "col2", "col3", "col4"},
			expectedPredicates: []Predicate{
				{Column: "col1", Operator: ">", Value: "10"},
				{Column: "col2", Operator: "=", Value: "5"},
				{Column: "col4", Operator: ">", Value: "20"},
			},
			expectedError: false,
		},
		{
			name:            "Complex query with multiple tables and functions",
			sql:             "SELECT count(*) FROM table1 JOIN table2 ON table1.id = table2.id WHERE table1.col1 > 10 AND table2.col2 = 5 GROUP BY table1.col3 HAVING count(*) > 20",
			expectedColumns: []string{"col1", "col2", "col3"},
			expectedPredicates: []Predicate{
				{Column: "col1", Operator: ">", Value: "10"},
				{Column: "col2", Operator: "=", Value: "5"},
			},
			expectedError: false,
		},
		{
			name:            "Complex query with multiple tables and functions and unary",
			sql:             "SELECT count(*) FROM table1 JOIN table2 ON table1.id = table2.id WHERE table1.col1 > 10 AND table2.col2 = 5 AND NOT table1.col3 = 10 GROUP BY table1.col3 HAVING count(*) > 20",
			expectedColumns: []string{"col1", "col2", "col3"},
			expectedPredicates: []Predicate{
				{Column: "col1", Operator: ">", Value: "10"},
				{Column: "col2", Operator: "=", Value: "5"},
			},
			expectedError: false,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			p := parser.NewParser(tc.sql)
			statements, err := p.ParseStmts()
			if tc.expectedError {
				assert.Error(t, err)
				return
			}
			assert.NoError(t, err)
			columns, predicates, err := RunFindPredicateColumns(statements[0])
			if tc.expectedError {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
				_ = columns
				//assert.Equal(t, tc.expectedColumns, columns)
				assert.Equal(t, tc.expectedPredicates, predicates)
			}
		})
	}
}
