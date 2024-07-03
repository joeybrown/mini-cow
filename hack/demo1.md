# Demo #1 - Containerfiles

1. Export some ENV vars
```bash
export REGISTRY=localhost:8000
export VERSION=$(git describe --tags --always --long --dirty)
export BASE_VERSION=v0.1.0
export BASE_DIR="$HOME/Dev/presentations/mini-cow"
export EXECUTABLE=mycowsay
```

2. Build the Base Image
```bash
export BASE_IMAGE_AMD64=$REGISTRY/podman-build/base:$VERSION-amd64
export BASE_IMAGE_ARM64=$REGISTRY/podman-build/base:$VERSION-arm64
export BASE_IMAGE_MULTI=$REGISTRY/podman-build/base:$VERSION

podman build -f $BASE_DIR/build/base.Containerfile \
  --build-arg TARGET_PLATFORM="linux/amd64" \
  -t $BASE_IMAGE_AMD64 $BASE_DIR
podman push --tls-verify=false $BASE_IMAGE_AMD64

podman build -f $BASE_DIR/build/base.Containerfile \
  --build-arg TARGET_PLATFORM="linux/arm64" \
  -t $BASE_IMAGE_ARM64 $BASE_DIR
podman push --tls-verify=false $BASE_IMAGE_ARM64

crane index append \
  -m $BASE_IMAGE_AMD64 \
  -m $BASE_IMAGE_ARM64 \
  -t $BASE_IMAGE_MULTI
  
```

3. Build the App Image
```bash
export APP_IMAGE_AMD64=$REGISTRY/containerfile/$EXECUTABLE:$VERSION-amd64
export APP_IMAGE_ARM64=$REGISTRY/containerfile/$EXECUTABLE:$VERSION-arm64
export APP_IMAGE_MULTI=$REGISTRY/containerfile/$EXECUTABLE:$VERSION

podman build -f $BASE_DIR/build/Containerfile \
  --build-arg TARGET_PLATFORM="linux/amd64" \
  --build-arg BASE_IMAGE_REF=$BASE_IMAGE_MULTI  \
  -t $APP_IMAGE_AMD64 $BASE_DIR
podman push --tls-verify=false $APP_IMAGE_AMD64

podman build -f $BASE_DIR/build/Containerfile \
  --build-arg TARGET_PLATFORM="linux/arm64" \
  --build-arg BASE_IMAGE_REF=$BASE_IMAGE_MULTI  \
  -t $APP_IMAGE_ARM64 $BASE_DIR
podman push --tls-verify=false $APP_IMAGE_ARM64

crane index append \
  -m $APP_IMAGE_AMD64 \
  -m $APP_IMAGE_ARM64 \
  -t $APP_IMAGE_MULTI 
```

4. Look at the App Image Index
```bash
crane manifest $APP_IMAGE_MULTI | jq
```

5. Look at the configs for the referenced manifests
```bash
ARM64_DIGEST=$(crane manifest $APP_IMAGE_MULTI | jq -r '.manifests[] | select(.platform.architecture == "arm64") | .digest')
crane manifest $REGISTRY/containerfile/$EXECUTABLE@$ARM64_DIGEST | jq
crane config $REGISTRY/containerfile/$EXECUTABLE@$ARM64_DIGEST | jq
CONTAINER_ID=$(podman pull $REGISTRY/containerfile/$EXECUTABLE@$ARM64_DIGEST)
dive $CONTAINER_ID
```

6. Dive into Image
```bash
ARM64_DIGEST=$(crane manifest $APP_IMAGE_MULTI | jq -r '.manifests[] | select(.platform.architecture == "arm64") | .digest')
CONTAINER_ID=$(podman pull $REGISTRY/containerfile/$EXECUTABLE@$ARM64_DIGEST)
dive $CONTAINER_ID
```

7. Export the Image Filesystem
```bash
ARM64_DIGEST=$(crane manifest $APP_IMAGE_MULTI | jq -r '.manifests[] | select(.platform.architecture == "arm64") | .digest')
mkdir -p $BASE_DIR/$EXECUTABLE-filesystem
crane export $REGISTRY/containerfile/$EXECUTABLE@$ARM64_DIGEST $BASE_DIR/$EXECUTABLE-filesystem/image.tar
tar -C $BASE_DIR/$EXECUTABLE-filesystem -xf $BASE_DIR/$EXECUTABLE-filesystem/image.tar
rm $BASE_DIR/$EXECUTABLE-filesystem/image.tar
tree -L 1 $BASE_DIR/$EXECUTABLE-filesystem
```

8. Export the OCI Layout
```bash
ARM64_DIGEST=$(crane manifest $APP_IMAGE_MULTI | jq -r '.manifests[] | select(.platform.architecture == "arm64") | .digest')
mkdir -p $BASE_DIR/$EXECUTABLE-oci-layout
oras copy --to-oci-layout $REGISTRY/containerfile/$EXECUTABLE@$ARM64_DIGEST $BASE_DIR/$EXECUTABLE-oci-layout

MANIFEST_DIGEST=$(cat $BASE_DIR/$EXECUTABLE-oci-layout/index.json | jq -r '.manifests[0].digest' | sed 's/sha256://')
CONFIG_DIGEST=$(cat $BASE_DIR/$EXECUTABLE-oci-layout/blobs/sha256/$MANIFEST_DIGEST | jq -r '.config.digest' | sed 's/sha256://')

LAYER_DIGEST=$(cat $BASE_DIR/$EXECUTABLE-oci-layout/blobs/sha256/$MANIFEST_DIGEST | jq -r '.layers[-1].digest' | sed 's/sha256://')
mv $BASE_DIR/$EXECUTABLE-oci-layout/blobs/sha256/$LAYER_DIGEST $BASE_DIR/$EXECUTABLE-oci-layout/blobs/sha256/$LAYER_DIGEST.tar.gz
mkdir -p $BASE_DIR/$EXECUTABLE-oci-layout/blobs/sha256/$LAYER_DIGEST
tar -C $BASE_DIR/$EXECUTABLE-oci-layout/blobs/sha256/$LAYER_DIGEST -xf $BASE_DIR/$EXECUTABLE-oci-layout/blobs/sha256/$LAYER_DIGEST.tar.gz

LAYER_DIGEST=$(cat $BASE_DIR/$EXECUTABLE-oci-layout/blobs/sha256/$MANIFEST_DIGEST | jq -r '.layers[-2].digest' | sed 's/sha256://')
mv $BASE_DIR/$EXECUTABLE-oci-layout/blobs/sha256/$LAYER_DIGEST $BASE_DIR/$EXECUTABLE-oci-layout/blobs/sha256/$LAYER_DIGEST.tar.gz
mkdir -p $BASE_DIR/$EXECUTABLE-oci-layout/blobs/sha256/$LAYER_DIGEST
tar -C $BASE_DIR/$EXECUTABLE-oci-layout/blobs/sha256/$LAYER_DIGEST -xf $BASE_DIR/$EXECUTABLE-oci-layout/blobs/sha256/$LAYER_DIGEST.tar.gz

cat $BASE_DIR/$EXECUTABLE-oci-layout/blobs/sha256/$MANIFEST_DIGEST | jq  > $BASE_DIR/$EXECUTABLE-oci-layout/blobs/sha256/$MANIFEST_DIGEST.json

cat $BASE_DIR/$EXECUTABLE-oci-layout/blobs/sha256/$CONFIG_DIGEST | jq  > $BASE_DIR/$EXECUTABLE-oci-layout/blobs/sha256/$CONFIG_DIGEST.json

```