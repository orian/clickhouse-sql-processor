module clickhouse-sql-processor

go 1.24

require (
	github.com/AfterShip/clickhouse-sql-parser v0.4.4
	github.com/davecgh/go-spew v1.1.1
	github.com/stretchr/testify v1.10.0
)

require (
	github.com/ClickHouse/ch-go v0.65.1 // indirect
	github.com/ClickHouse/clickhouse-go/v2 v2.33.1 // indirect
	github.com/andybalholm/brotli v1.1.1 // indirect
	github.com/go-faster/city v1.0.1 // indirect
	github.com/go-faster/errors v0.7.1 // indirect
	github.com/google/uuid v1.6.0 // indirect
	github.com/klauspost/compress v1.17.11 // indirect
	github.com/paulmach/orb v0.11.1 // indirect
	github.com/pierrec/lz4/v4 v4.1.22 // indirect
	github.com/pkg/errors v0.9.1 // indirect
	github.com/pmezard/go-difflib v1.0.0 // indirect
	github.com/segmentio/asm v1.2.0 // indirect
	github.com/shopspring/decimal v1.4.0 // indirect
	go.opentelemetry.io/otel v1.35.0 // indirect
	go.opentelemetry.io/otel/trace v1.35.0 // indirect
	golang.org/x/sys v0.30.0 // indirect
	gopkg.in/yaml.v3 v3.0.1 // indirect
)

// go list -m -json github.com/orian/clickhouse-sql-parser@refactor-visitor
replace github.com/AfterShip/clickhouse-sql-parser => github.com/orian/clickhouse-sql-parser v0.0.0-20250320231029-26b1c0c67bfb
