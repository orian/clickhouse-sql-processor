package visitors

import (
	"clickhouse-sql-processor/datamodels"
	"encoding/json"
	"flag"
	"os"
	"sort"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func EqGen[T comparable](name string, value T) func() {
	return func() {

	}
}

type Pipe struct {
}

func NewPipe() *Pipe {
	return &Pipe{}
}

func (p *Pipe) Add(gen func()) {

}

type Row map[string]interface{}

// MarshalJSON ensures consistent serialization of Row
func (r Row) MarshalJSON() ([]byte, error) {
	// Sort keys to ensure consistent ordering
	keys := make([]string, 0, len(r))
	for k := range r {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	// Build ordered map
	orderedMap := make(map[string]interface{})
	for _, k := range keys {
		orderedMap[k] = r[k]
	}
	return json.Marshal(orderedMap)
}

func (p *Pipe) Generate() []Row {
	return nil
}

func AddSource() {

}

type Expr interface{}

func ExprAnd(exprs ...Generator) Generator {
	return &generatorAnd{
		exprs: exprs,
	}
}

func ExprOr(expr ...Expr) {}

func ExprEq(field string, ct datamodels.ColumnType, value interface{}) Generator {
	return &generatorEq{
		field: field,
		ct:    ct,
		value: value,
	}
}

type Generator interface {
	Generate() []Row
}

type generatorEq struct {
	field string
	ct    datamodels.ColumnType
	value interface{}
}

func generateValues(ct datamodels.ColumnType, value interface{}) []interface{} {
	switch v := value.(type) {
	case int:
		return []interface{}{v, v + 1}
	case float32:
		return []interface{}{v, v + 1.0}
	case float64:
		return []interface{}{v, v + 1.0}
	case string:
		if ct == datamodels.String {
			return []interface{}{v, v + "a"}
		} else if ct == datamodels.Date {
			date, err := time.Parse("2006-01-02", v)
			if err != nil {
				return []interface{}{v}
			}
			return []interface{}{v, date.AddDate(0, 0, 1).Format("2006-01-02")}
		}
	case bool:
		return []interface{}{v, !v}
	case time.Time:
		return []interface{}{v, v.Add(time.Hour * 24)}
	default:
		return []interface{}{v}
	}
	return nil
}

func (g *generatorEq) Generate() []Row {
	vals := generateValues(g.ct, g.value)
	var rows []Row
	for _, v := range vals {
		rows = append(rows, Row{
			g.field: v,
		})
	}
	return rows
}

type generatorAnd struct {
	exprs []Generator
}

func (g *generatorAnd) Generate() []Row {
	if len(g.exprs) == 0 {
		return nil
	}

	// Generate rows for each expression
	rowsList := make([][]Row, len(g.exprs))
	for i, expr := range g.exprs {
		rowsList[i] = expr.Generate()
	}

	// Create a cross product of all rows
	var crossProduct func([][]Row, int) []Row
	crossProduct = func(lists [][]Row, depth int) []Row {
		if depth == len(lists) {
			return []Row{{}}
		}

		subCross := crossProduct(lists, depth+1)
		var result []Row
		for _, row := range lists[depth] {
			for _, subRow := range subCross {
				newRow := make(Row)
				for k, v := range row {
					newRow[k] = v
				}
				for k, v := range subRow {
					newRow[k] = v
				}
				result = append(result, newRow)
			}
		}
		return result
	}

	return crossProduct(rowsList, 0)
}

// TestExprEqGenerator tests a generator for a simple query.
func TestExprEqGenerator(t *testing.T) {
	got := ExprEq("team_id", datamodels.Int64, 2).Generate()

	// Convert result to JSON for comparison
	gotJSON, err := json.MarshalIndent(got, "", "  ")
	require.NoError(t, err)

	// Update golden file if -update flag is provided
	golden := "testdata/expr_eq.golden"
	if *update {
		err := os.WriteFile(golden, gotJSON, 0644)
		require.NoError(t, err)
	}

	// Read golden file
	want, err := os.ReadFile(golden)
	require.NoError(t, err)

	assert.JSONEq(t, string(want), string(gotJSON))
}

func TestExprAndGenerator(t *testing.T) {
	got := ExprAnd(
		ExprEq("team_id", datamodels.Int64, 2),
		ExprEq("timestamp", datamodels.Date, "2025-02-15")).Generate()

	gotJSON, err := json.MarshalIndent(got, "", "  ")
	require.NoError(t, err)

	golden := "testdata/expr_and.golden"
	if *update {
		err := os.WriteFile(golden, gotJSON, 0644)
		require.NoError(t, err)
	}

	want, err := os.ReadFile(golden)
	require.NoError(t, err)

	assert.JSONEq(t, string(want), string(gotJSON))
}

// Add update flag for golden files
var update = flag.Bool("update", false, "update golden files")
