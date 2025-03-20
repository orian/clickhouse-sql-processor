package visitors

import (
	"fmt"
	"github.com/AfterShip/clickhouse-sql-parser/parser"
	"github.com/davecgh/go-spew/spew"
	"log/slog"
)

type ColumnRef struct {
	Name      string
	SourceRef Source
}

type Source interface {
	Name() string
	Available() []string
	Selected() []string
}

type FuncSource struct{}

type TableSource struct {
	Name string
}

type JoinSource struct{}

type SelectSource struct{}

type FindTables struct {
	parser.DefaultASTVisitor

	Columns []string
	Names   []string
}

func (f *FindTables) VisitColumnIdentifier(expr *parser.ColumnIdentifier) error {
	err := f.DefaultASTVisitor.VisitColumnIdentifier(expr)
	slog.Info("", "db", expr.Database, "table", expr.Table.Name, "column", expr.Column.Name)
	if err != nil {
		return err
	}
	//expr.Database.Name
	//expr.Table.Name
	//expr.Column.Name

	return nil
}

func (f *FindTables) VisitSelectItem(expr *parser.SelectItem) error {
	err := f.DefaultASTVisitor.VisitSelectItem(expr)
	fmt.Printf("column expr: %s as %s\n", expr.Expr, expr.Alias)
	if err != nil {
		return err
	}
	return nil
}

func (f *FindTables) VisitAliasExpr(expr *parser.AliasExpr) error {
	err := f.DefaultASTVisitor.VisitAliasExpr(expr)
	fmt.Printf("I am an alias: %s\n", spew.Sdump(expr))
	if err != nil {
		return err
	}
	return nil
}

func (f *FindTables) VisitTableIdentifier(expr *parser.TableIdentifier) error {
	err := f.DefaultASTVisitor.VisitTableIdentifier(expr)
	if err == nil {
		f.Names = append(f.Names, expr.String())
	}
	return err
}

func (f *FindTables) VisitTableExpr(expr *parser.TableExpr) error {
	err := f.DefaultASTVisitor.VisitTableExpr(expr)
	fmt.Println("table expression", spew.Sdump(expr))
	return err
}

func (f *FindTables) VisitFromExpr(expr *parser.FromClause) error {
	err := f.DefaultASTVisitor.VisitFromExpr(expr)
	fmt.Println(expr.String())
	return err
}

func NewFindTables() *FindTables {
	v := &FindTables{}
	v.Self = v
	return v
}

func RunFindTables(node parser.Expr) ([]string, error) {
	v := NewFindTables()
	err := node.Accept(v)
	return v.Names, err
}
