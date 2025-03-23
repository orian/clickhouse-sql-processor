package visitors

import (
	"fmt"
	"github.com/AfterShip/clickhouse-sql-parser/parser"
	"log/slog"
)

// FindPredicateColumns finds all columns that are used in a WHERE, HAVING, GROUP BY clause,
// it's purpose is to find which columns of the tables matter for this query result set.
// Columns are in general used either in filters (WHERE, GROUP BY's HAVING), aggregates (COUNT, MAX, SUM),
// or expressions (e.g. JSONExtractString(log_comment, 'somefiled')).
//
// Let's say that a result is: greater(col_1, 12) based on: `col_1 > 12`,
// we will later want to generate 2 rows based on that, one with col_1 less or equal to 12,
// and another with col_1 > 12.
//
// If more than one predicate is found, let's say: [greater(col_1, 12), less(col_2, 3.14)],
// then we need to generate 4 rows (all possible combinations):
//
//	col_1, col_2
//	   12,   1.0
//	   12,   5.0
//	   15,   1.0
//	   15,   5.0
type FindPredicateColumns struct {
	parser.DefaultASTVisitor

	ctx ASTContext

	Columns    []string
	Names      []string
	Predicates []Predicate
}

type Predicate struct {
	Column   string
	Operator string
	Value    string
}

func (f *FindPredicateColumns) VisitColumnIdentifier(expr *parser.ColumnIdentifier) error {
	err := f.DefaultASTVisitor.VisitColumnIdentifier(expr)
	if err != nil {
		return err
	}
	slog.Info("Found column in predicate", "db", expr.Database, "table", expr.Table.Name, "column", expr.Column.Name)
	if expr.Column.Name != "" {
		f.Columns = append(f.Columns, expr.Column.Name)
	}
	return nil
}

func (f *FindPredicateColumns) VisitWhereExpr(expr *parser.WhereClause) error {
	slog.Info("Visiting WHERE clause")
	err := f.DefaultASTVisitor.VisitWhereExpr(expr)
	if err != nil {
		return err
	}
	return nil
}

func (f *FindPredicateColumns) VisitHavingExpr(expr *parser.HavingClause) error {
	slog.Info("Visiting HAVING clause")
	err := f.DefaultASTVisitor.VisitHavingExpr(expr)
	if err != nil {
		return err
	}
	return nil
}

func (f *FindPredicateColumns) VisitGroupByExpr(expr *parser.GroupByClause) error {
	slog.Info("Visiting GROUP BY clause")
	defer f.ctx.With(ContextKindGroupBy)
	err := f.DefaultASTVisitor.VisitGroupByExpr(expr)
	if err != nil {
		return err
	}
	return nil
}

func (f *FindPredicateColumns) VisitColumnExprList(expr *parser.ColumnExprList) error {
	err := f.DefaultASTVisitor.VisitColumnExprList(expr)
	if err != nil {
		return err
	}
	return nil
}

func (f *FindPredicateColumns) VisitFunctionExpr(expr *parser.FunctionExpr) error {
	slog.Info("Visiting Function", "name", expr.Name)
	err := f.DefaultASTVisitor.VisitFunctionExpr(expr)
	if err != nil {
		return err
	}
	return nil
}

func (f *FindPredicateColumns) VisitBinaryExpr(expr *parser.BinaryOperation) error {
	slog.Info("Visiting Binary Expression", "operator", expr.Operation)
	err := f.DefaultASTVisitor.VisitBinaryExpr(expr)
	if err != nil {
		return err
	}
	if column, ok := expr.LeftExpr.(*parser.Ident); ok {
		if number, ok := expr.RightExpr.(*parser.NumberLiteral); ok {
			f.Predicates = append(f.Predicates, Predicate{
				Column:   column.Name,
				Operator: string(expr.Operation),
				Value:    number.String(),
			})
		}
	}
	return nil
}

func (f *FindPredicateColumns) VisitUnaryExpr(expr *parser.UnaryExpr) error {
	slog.Info("Visiting Unary Expression", "operator", expr.Kind)
	err := f.DefaultASTVisitor.VisitUnaryExpr(expr)
	if err != nil {
		return err
	}
	return nil
}

func (f *FindPredicateColumns) VisitTableIdentifier(expr *parser.TableIdentifier) error {
	err := f.DefaultASTVisitor.VisitTableIdentifier(expr)
	if err == nil {
		f.Names = append(f.Names, expr.String())
	}
	return err
}

func NewFindPredicateColumns() *FindPredicateColumns {
	v := &FindPredicateColumns{}
	v.Self = v
	return v
}

func RunFindPredicateColumns(node parser.Expr) ([]string, []Predicate, error) {
	v := NewFindPredicateColumns()
	err := node.Accept(v)
	if err != nil {
		return nil, nil, fmt.Errorf("error running FindPredicateColumns: %w", err)
	}
	return v.Columns, v.Predicates, nil
}
