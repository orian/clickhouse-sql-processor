package visitors

import "github.com/AfterShip/clickhouse-sql-parser/parser"

// FindPredicateColumns finds all columns that are used in a WHERE, HAVING, GROUP BY clause,
// it's purpose is to find which columns of the tables matter for this query result set.
// Columns are in general used either in filters (WHERE, GROUP BY's HAVING), aggregates (COUNT, MAX, SUM),
// or expressions (e.g. JSONExtractString(log_comment, 'somefiled')).
type FindPredicateColumns struct {
	parser.DefaultASTVisitor

	Columns []string
	Names   []string
}
