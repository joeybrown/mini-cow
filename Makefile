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

# make podman-run REGISTRY=localhost:8000
podman-run:
	podman run --rm $(REGISTRY)/containerfile/$(EXECUTABLE):$(VERSION) "This was made with podman (buildah)!"

# make crane-build REGISTRY=localhost:8000
crane-build:
	mkdir -p /tmp/app/bin
	cp bin/$(EXECUTABLE)_linux_arm64 /tmp/app/bin/mycowsay
	bash -c "crane append -f <(tar -c -f - -C /tmp app/bin/mycowsay) -t $(REGISTRY)/cranebuild/$(EXECUTABLE):$(VERSION) --base $(REGISTRY)/containerfile/base:arm64-$(BASE_VERSION)"
	crane mutate --entrypoint "/app/bin/mycowsay" $(REGISTRY)/cranebuild/$(EXECUTABLE):$(VERSION)
	@echo
	@echo "------------------------------------------------------------"
	@echo
	@echo "Crane \"build\" completed. Image pushed to $(REGISTRY)."
	@echo $(REGISTRY)/cranebuild/$(EXECUTABLE):$(VERSION)

# make ko-yaml REGISTRY=localhost:8000
ko-yaml:
	@echo "defaultBaseImage: ${REGISTRY}/containerfile/base:v0.1.0" > build/ko.yaml
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

# make ko-build REGISTRY=localhost:8000
ko-build:
	KO_DOCKER_REPO=$(REGISTRY)/kobuild/$(EXECUTABLE) KO_CONFIG_PATH=build/ko.yaml VERSION=$(VERSION) ko build --insecure-registry --bare -t $(VERSION) ./cmd/cow-say
	@echo
	@echo "------------------------------------------------------------"
	@echo
	@echo "Ko build completed. Image pushed to $(REGISTRY)."
	@echo $(REGISTRY)/kobuild/$(EXECUTABLE):$(VERSION)



