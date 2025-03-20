module clickhouse-sql-processor

go 1.24

require (
	github.com/AfterShip/clickhouse-sql-parser v0.4.4
	github.com/davecgh/go-spew v1.1.1
	github.com/stretchr/testify v1.10.0
)

require (
	github.com/pmezard/go-difflib v1.0.0 // indirect
	gopkg.in/yaml.v3 v3.0.1 // indirect
)

// go list -m -json github.com/orian/clickhouse-sql-parser@refactor-visitor
replace github.com/AfterShip/clickhouse-sql-parser => github.com/orian/clickhouse-sql-parser v0.0.0-20250320231029-26b1c0c67bfb
