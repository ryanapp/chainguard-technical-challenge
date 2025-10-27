# hello-server

Go web server using Gin framework.

## Requirements

Go 1.18+

## Build
```bash
go mod download
CGO_ENABLED=0 go build -o hello-server .
```

Binary produced: `hello-server` (static, no external dependencies)

## Run
```bash
./hello-server
```

## Files

- `main.go` - Server implementation
- `go.mod` - Module definition
- `go.sum` - Dependency checksums
