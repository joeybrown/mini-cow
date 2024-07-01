EXECUTABLE := mycowsay
VERSION := $(shell git describe --tags --always --long --dirty) # this is the version of the application

BASE_VERSION := v0.1.0 # this is the version of the base image

all: linux-amd64 linux-arm64 darwin-amd64 darwin-arm64

linux-amd64:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -v -o ./bin/$(EXECUTABLE)_linux_amd64 -ldflags="-s -w -X main.version=$(VERSION)" ./cmd/cow-say/main.go
linux-arm64:
	GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -v -o ./bin/$(EXECUTABLE)_linux_arm64 -ldflags="-s -w -X main.version=$(VERSION)" ./cmd/cow-say/main.go
darwin-amd64:
	GOOS=darwin GOARCH=amd64 CGO_ENABLED=0 go build -v -o ./bin/$(EXECUTABLE)_darwin_amd64 -ldflags="-s -w -X main.version=$(VERSION)" ./cmd/cow-say/main.go
darwin-arm64:
	GOOS=darwin GOARCH=arm64 CGO_ENABLED=0 go build -v -o ./bin/$(EXECUTABLE)_darwin_arm64 -ldflags="-s -w -X main.version=$(VERSION)" ./cmd/cow-say/main.go
current:
	go build -v -o ./bin/$(EXECUTABLE) -ldflags="-s -w -X main.version=$(VERSION)" ./cmd/cow-say/main.go

# make podman-base REGISTRY=localhost:8000
podman-base:
	podman build -t $(REGISTRY)/containerfile/base:amd64-$(BASE_VERSION) --build-arg TARGET_PLATFORM="linux/amd64" -f build/base.Containerfile .
	podman push --tls-verify=false $(REGISTRY)/containerfile/base:amd64-$(BASE_VERSION)
	podman build -t $(REGISTRY)/containerfile/base:arm64-$(BASE_VERSION) --build-arg TARGET_PLATFORM="linux/arm64" -f build/base.Containerfile .
	podman push --tls-verify=false $(REGISTRY)/containerfile/base:arm64-$(BASE_VERSION)
	crane index append -t $(REGISTRY)/containerfile/base:$(BASE_VERSION) -m $(REGISTRY)/containerfile/base:amd64-$(BASE_VERSION) -m $(REGISTRY)/containerfile/base:arm64-$(BASE_VERSION)
	@echo
	@echo "------------------------------------------------------------"
	@echo
	@echo "Podman base image build completed. Images pushed to $(REGISTRY)."
	@echo $(REGISTRY)/containerfile/base:amd64-$(BASE_VERSION)
	@echo $(REGISTRY)/containerfile/base:arm64-$(BASE_VERSION)
	@echo $(REGISTRY)/containerfile/base:$(BASE_VERSION)

# make podman-build REGISTRY=localhost:8000 BASE_IMAGE_REF=localhost:8000/containerfile/base:v0.1.0
podman-build:
	podman build -t $(REGISTRY)/containerfile/$(EXECUTABLE)-amd64:$(VERSION) --build-arg TARGET_PLATFORM="linux/amd64" --build-arg BASE_IMAGE_REF=$(BASE_IMAGE_REF) -f build/Containerfile .
	podman push --tls-verify=false $(REGISTRY)/containerfile/$(EXECUTABLE)-amd64:$(VERSION)
	podman build -t $(REGISTRY)/containerfile/$(EXECUTABLE)-arm64:$(VERSION) --build-arg TARGET_PLATFORM="linux/arm64" --build-arg BASE_IMAGE_REF=$(BASE_IMAGE_REF) -f build/Containerfile .
	podman push --tls-verify=false $(REGISTRY)/containerfile/$(EXECUTABLE)-arm64:$(VERSION)
	crane index append -t $(REGISTRY)/containerfile/$(EXECUTABLE):$(VERSION) -m $(REGISTRY)/containerfile/$(EXECUTABLE)-amd64:$(VERSION) -m $(REGISTRY)/containerfile/$(EXECUTABLE)-arm64:$(VERSION)
	@echo
	@echo "------------------------------------------------------------"
	@echo
	@echo "Podman build completed. Images pushed to $(REGISTRY)."
	@echo $(REGISTRY)/containerfile/$(EXECUTABLE)-amd64:$(VERSION)
	@echo $(REGISTRY)/containerfile/$(EXECUTABLE)-arm64:$(VERSION)
	@echo $(REGISTRY)/containerfile/$(EXECUTABLE):$(VERSION)

podman-run:
	podman run --rm containerfile/$(EXECUTABLE):$(VERSION) "Hello, Dev Memphis!"
podman-dive:
	dive containerfile/$(EXECUTABLE):$(VERSION)