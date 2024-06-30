EXECUTABLE := mycowsay
VERSION := $(shell git describe --tags --always --long --dirty)

LINUX := linux
DARWIN := darwin
AMD64 := amd64
ARM64 := arm64

all: linux-amd64 linux-arm64 darwin-amd64 darwin-arm64

linux-amd64:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -v -o ./bin/$(EXECUTABLE)_$(LINUX)_$(AMD64) -ldflags="-s -w -X main.version=$(VERSION)" ./cmd/cow-say/main.go
linux-arm64:
	GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -v -o ./bin/$(EXECUTABLE)_$(LINUX)_$(ARM64) -ldflags="-s -w -X main.version=$(VERSION)" ./cmd/cow-say/main.go
darwin-amd64:
	GOOS=darwin GOARCH=amd64 CGO_ENABLED=0 go build -v -o ./bin/$(EXECUTABLE)_$(DARWIN)_$(AMD64) -ldflags="-s -w -X main.version=$(VERSION)" ./cmd/cow-say/main.go
darwin-arm64:
	GOOS=darwin GOARCH=arm64 CGO_ENABLED=0 go build -v -o ./bin/$(EXECUTABLE)_$(DARWIN)_$(ARM64) -ldflags="-s -w -X main.version=$(VERSION)" ./cmd/cow-say/main.go
