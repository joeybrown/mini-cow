EXECUTABLE := mycowsay
VERSION := $(shell git describe --tags --always --long --dirty)

LINUX := $(EXECUTABLE)_linux_amd64
DARWIN := $(EXECUTABLE)_darwin_amd64

all: linux darwin

linux:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -v -o ./bin/$(LINUX) -ldflags="-s -w -X main.version=$(VERSION)" ./cmd/cow-say/main.go
darwin:
	GOOS=darwin GOARCH=amd64 CGO_ENABLED=0 go build -v -o ./bin/$(DARWIN) -ldflags="-s -w -X main.version=$(VERSION)" ./cmd/cow-say/main.go