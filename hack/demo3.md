# Demo #3 - Buildpacks

1. Build the Base Run Image
```bash
export BASE_IMAGE_AMD64=$REGISTRY/buildpack/base:$VERSION-amd64
export BASE_IMAGE_ARM64=$REGISTRY/buildpack/base:$VERSION-arm64
export BASE_IMAGE_MULTI=$REGISTRY/buildpack/base:$VERSION

podman build -t $BASE_IMAGE_AMD64 \
  --build-arg TARGET_PLATFORM="linux/amd64" \
  --format docker \
  -f $BASE_DIR/build/run.Containerfile .
podman push --tls-verify=false $BASE_IMAGE_AMD64

podman build -t $BASE_IMAGE_ARM64 \
  --build-arg TARGET_PLATFORM="linux/arm64" \
  --format docker \
  -f $BASE_DIR/build/run.Containerfile .
podman push --tls-verify=false $BASE_IMAGE_ARM64

crane index append \
  -m $BASE_IMAGE_AMD64 \
  -m $BASE_IMAGE_ARM64 \
  -t $BASE_IMAGE_MULTI
```

2. Pack Build
```bash
export BUILDPACK_IMAGE=$REGISTRY/buildpack/$EXECUTABLE:$VERSION

bash -c "cd $BASE_DIR && pack build $BUILDPACK_IMAGE \
    --descriptor $BASE_DIR/build/project.toml \
    --builder heroku/builder:24 \
    --run-image $BASE_IMAGE_MULTI \
    --publish \
    --default-process "cow-say" \
    --network host"
```

3. Run The Image
```bash
podman run --rm $REGISTRY/buildpack/$EXECUTABLE:$VERSION "This was made with buildpacks"
```

5. Observe layers
```bash
crane manifest $BASE_IMAGE_ARM64 | jq '.layers[].digest'
crane manifest $BUILDPACK_IMAGE | jq '.layers[].digest'
```

4. Build a new Base Image
```bash
export OLD_BASE_IMAGE=$REGISTRY/buildpack/base@$(crane digest $BASE_IMAGE_ARM64)

podman build -t $BASE_IMAGE_AMD64 \
  --build-arg TARGET_PLATFORM="linux/amd64" \
  --format docker \
  -f $BASE_DIR/build/run2.Containerfile .
podman push --tls-verify=false $BASE_IMAGE_AMD64

podman build -t $BASE_IMAGE_ARM64 \
  --build-arg TARGET_PLATFORM="linux/arm64" \
  --format docker \
  -f $BASE_DIR/build/run2.Containerfile .
podman push --tls-verify=false $BASE_IMAGE_ARM64

crane index append \
  -m $BASE_IMAGE_AMD64 \
  -m $BASE_IMAGE_ARM64 \
  -t $BASE_IMAGE_MULTI
```

6. Rebase the image
```bash
pack rebase $BUILDPACK_IMAGE --publish
```

7. Run The Image
```bash
podman run --rm $BUILDPACK_IMAGE "This was just rebased"
```

8. Observe layers
```bash
crane manifest $OLD_BASE_IMAGE | jq '.layers[].digest'
crane manifest $BUILDPACK_IMAGE | jq '.layers[].digest'
```
```bash
crane manifest $BASE_IMAGE_ARM64 | jq '.layers[].digest'
crane manifest $BUILDPACK_IMAGE | jq '.layers[].digest'
```

9. Inspect Top Layers
```bash
pack inspect $BUILDPACK_IMAGE
crane config $BUILDPACK_IMAGE | jq '.config.Labels' | jq -r '.["io.buildpacks.lifecycle.metadata"]' | jq -r '.runImage.topLayer'
crane config $BUILDPACK_IMAGE | jq '.config.Labels' | jq -r '.["io.buildpacks.lifecycle.metadata"]' | jq -r '.runImage.reference'
```
