package visitors

import (
	"fmt"
	"github.com/AfterShip/clickhouse-sql-parser/parser"
	"github.com/davecgh/go-spew/spew"
	"log/slog"
)

type FindTables struct {
	parser.DefaultASTVisitor

	Columns []string
	Names   []string
}

func (f *FindTables) VisitColumnIdentifier(expr *parser.ColumnIdentifier) error {
	slog.Info("", "db", expr.Database, "table", expr.Table.Name, "column", expr.Column.Name)
	//expr.Database.Name
	//expr.Table.Name
	//expr.Column.Name

	return nil
}

func (f *FindTables) VisitSelectItem(expr *parser.SelectItem) error {
	fmt.Printf("column expr: %s as %s\n", expr.Expr, expr.Alias)
	return nil
}

func (f *FindTables) VisitAliasExpr(expr *parser.AliasExpr) error {
	fmt.Printf("I am an alias: %s\n", spew.Sdump(expr))
	return nil
}

func (f *FindTables) VisitTableExpr(expr *parser.TableExpr) error {
	//fmt.Println()
	fmt.Println(spew.Sdump(expr))
	return nil
}

func (f *FindTables) VisitFromExpr(expr *parser.FromClause) error {
	fmt.Println(expr.String())
	return nil
}

func NewFindTables() *FindTables {
	return &FindTables{}
}

func RunFindTables(node parser.Expr) ([]string, error) {
	v := NewFindTables()
	err := node.Accept(v)
	return v.Names, err
}
