EXECUTABLE := mycowsay
VERSION := $(shell git describe --tags --always --long --dirty) # this is the version of the application
REGISTRY := localhost:8000

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

ko-yaml:
	@echo "defaultBaseImage: ${BASE_IMAGE_REF}" > build/ko.yaml
	@echo "" >> build/ko.yaml
	@echo "defaultPlatforms:" >> build/ko.yaml
	@echo "  - linux/amd64" >> build/ko.yaml
	@echo "  - linux/arm64" >> build/ko.yaml
	@echo "" >> build/ko.yaml
	@echo "builds:" >> build/ko.yaml
	@echo "  - id: cowsay" >> build/ko.yaml
	@echo "    dir: ." >> build/ko.yaml
	@echo "    main: ./cmd/cow-say" >> build/ko.yaml
	@echo "    ldflags:" >> build/ko.yaml
	@echo "      - -s -w" >> build/ko.yaml
	@echo "      - -X main.version={{.Env.VERSION}}" >> build/ko.yaml

buildpack-build:
	pack build $(REGISTRY)/buildpack/$(EXECUTABLE):$(VERSION) \
		--descriptor build/project.toml \
		--builder heroku/builder:24 \
		--run-image $(REGISTRY)/buildpack/base:$(BASE_VERSION) \
		--publish \
		--default-process "cow-say" \
		--network host

buildpack-config-inspect:
	@crane config $(REGISTRY)/buildpack/$(EXECUTABLE):$(VERSION) | jq '.config.Labels' | jq -r '.["io.buildpacks.lifecycle.metadata"]' | jq -r '.runImage.topLayer'
	@crane config $(REGISTRY)/buildpack/$(EXECUTABLE):$(VERSION) | jq '.config.Labels' | jq -r '.["io.buildpacks.lifecycle.metadata"]' | jq -r '.runImage.reference'

# Create a buildpack base run image based on heroku:22
buildpack-new-base:
	podman build -t $(REGISTRY)/buildpack/base:amd64-$(BASE_VERSION) --build-arg TARGET_PLATFORM="linux/amd64" --format docker -f build/run2.Containerfile .
	podman push --tls-verify=false $(REGISTRY)/buildpack/base:amd64-$(BASE_VERSION)
	podman build -t $(REGISTRY)/buildpack/base:arm64-$(BASE_VERSION) --build-arg TARGET_PLATFORM="linux/arm64" --format docker -f build/run2.Containerfile .
	podman push --tls-verify=false $(REGISTRY)/buildpack/base:arm64-$(BASE_VERSION)
	crane index append --docker-empty-base -t $(REGISTRY)/buildpack/base:$(BASE_VERSION) -m $(REGISTRY)/buildpack/base:amd64-$(BASE_VERSION) -m $(REGISTRY)/buildpack/base:arm64-$(BASE_VERSION)
	@echo
	@echo "------------------------------------------------------------"
	@echo
	@echo "Buildpack base image build completed. Images pushed to $(BASE_VERSION)."
	@echo $(REGISTRY)/buildpack/base:amd64-$(BASE_VERSION)
	@echo $(REGISTRY)/buildpack/base:arm64-$(BASE_VERSION)
	@echo $(REGISTRY)/buildpack/base:$(BASE_VERSION)
