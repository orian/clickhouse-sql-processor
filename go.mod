module clickhouse-sql-processor

go 1.24

require (
	github.com/AfterShip/clickhouse-sql-parser v0.4.4
	github.com/davecgh/go-spew v1.1.1
	github.com/stretchr/testify v1.8.4
)

require (
	github.com/pmezard/go-difflib v1.0.0 // indirect
	gopkg.in/yaml.v3 v3.0.1 // indirect
)

replace github.com/AfterShip/clickhouse-sql-parser => github.com/orian/clickhouse-sql-parser v0.0.0-20250301225821-9825d50f553f
