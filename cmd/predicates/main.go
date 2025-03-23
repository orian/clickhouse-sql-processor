package main

import (
	"fmt"
	"log"
	"log/slog"
	"strconv"

	"clickhouse-sql-processor/visitors"
	"github.com/AfterShip/clickhouse-sql-parser/parser"
)

func main() {
	slog.SetLogLoggerLevel(slog.LevelDebug)
	sql := "SELECT * FROM movie_rentals.rentals WHERE customer_id > 12 AND movie_id = 13 GROUP BY customer_id HAVING count(*) > 1"
	//sql := "SELECT * FROM movie_rentals.rentals"

	p := parser.NewParser(sql)
	node, err := p.ParseStmts()
	if err != nil {
		log.Fatal(err)
	}

	columns, predicates, err := visitors.RunFindPredicateColumns(node[0])
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Columns in predicates:", columns)
	fmt.Println("Predicates:", predicates)

	// Generate dataset
	dataset := generateDataset(predicates)

	// Print the generated dataset
	fmt.Println("\nGenerated Dataset:")
	for _, row := range dataset {
		fmt.Println(row)
	}
}

// generateDataset generates a dataset that covers each possible combination of conditions.
func generateDataset(predicates []visitors.Predicate) []map[string]interface{} {
	if len(predicates) == 0 {
		return []map[string]interface{}{{}} // Return an empty row if no predicates
	}

	// Create a list of value sets for each predicate
	valueSets := make([][]interface{}, len(predicates))
	for i, predicate := range predicates {
		valueSets[i] = generateValueSets(predicate)
	}

	// Generate all combinations of values
	combinations := generateCombinations(valueSets)

	// Create the dataset
	dataset := make([]map[string]interface{}, len(combinations))
	for i, combination := range combinations {
		dataset[i] = make(map[string]interface{})
		for j, value := range combination {
			dataset[i][predicates[j].Column] = value
		}
	}

	return dataset
}

// generateValueSets generates a set of values for a given predicate.
func generateValueSets(predicate visitors.Predicate) []interface{} {
	var values []interface{}
	switch predicate.Operator {
	case ">":
		num, err := strconv.ParseFloat(predicate.Value, 64)
		if err != nil {
			log.Fatal(err)
		}
		values = append(values, num)
		values = append(values, num+1)
	case "=":
		num, err := strconv.ParseFloat(predicate.Value, 64)
		if err != nil {
			log.Fatal(err)
		}
		values = append(values, num)
		values = append(values, num+1)
	default:
		values = append(values, predicate.Value)
	}
	return values
}

// generateCombinations generates all combinations of values from the given value sets.
func generateCombinations(valueSets [][]interface{}) [][]interface{} {
	if len(valueSets) == 0 {
		return [][]interface{}{{}}
	}

	// Calculate the total number of combinations
	totalCombinations := 1
	for _, set := range valueSets {
		totalCombinations *= len(set)
	}

	// Create the combinations array
	combinations := make([][]interface{}, totalCombinations)
	for i := range combinations {
		combinations[i] = make([]interface{}, len(valueSets))
	}

	// Generate combinations
	for i := 0; i < totalCombinations; i++ {
		temp := i
		for j := len(valueSets) - 1; j >= 0; j-- {
			combinations[i][j] = valueSets[j][temp%len(valueSets[j])]
			temp /= len(valueSets[j])
		}
	}

	return combinations
}
