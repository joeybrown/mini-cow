# Demo #2 - Crane Append & Ko Build

1. Crane Append
```bash
export APP_IMAGE=$REGISTRY/cranebuild/$EXECUTABLE:$VERSION
mkdir -p $BASE_DIR/tmp/app/bin
make -C $BASE_DIR linux-arm64
cp $BASE_DIR/bin/${EXECUTABLE}_linux_arm64 $BASE_DIR/tmp/app/bin/mycowsay
crane append \
  --new_layer <(tar -c -f - -C $BASE_DIR/tmp app/bin/mycowsay) \
  --new_tag $APP_IMAGE \
  --base $BASE_IMAGE_ARM64
crane mutate --entrypoint "/app/bin/mycowsay" $APP_IMAGE
```

2. Run The Image
```bash
podman run --rm $REGISTRY/cranebuild/$EXECUTABLE:$VERSION "This was made with crane"
```

3. Ko Build
```bash
export KO_DOCKER_REPO=$REGISTRY/kobuild/$EXECUTABLE
export KO_CONFIG_PATH=$BASE_DIR/build/ko.yaml

make -C $BASE_DIR ko-yaml BASE_IMAGE_REF=$BASE_IMAGE_MULTI
bash -c "cd $BASE_DIR && ko build  --insecure-registry --bare -t $VERSION ./cmd/cow-say"
```

2. Run The Image
```bash
podman run --rm $REGISTRY/kobuild/$EXECUTABLE:$VERSION "This was made with ko"
```