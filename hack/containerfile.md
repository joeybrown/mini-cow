Create the base image
```bash
make podman-base REGISTRY=localhost:8000
```

Build the app image
```bash
make podman-build \
  REGISTRY=localhost:8000 \
  BASE_IMAGE_REF=localhost:8000/containerfile/base:v0.1.0
```

Look at app image index
```bash
crane manifest localhost:8000/containerfile/mycowsay:6d94bbb-dirty | jq
```

Look at amd64 app image manifest, config
```bash
crane manifest localhost:8000/containerfile/mycowsay-amd64:6d94bbb-dirty | jq
crane config localhost:8000/containerfile/mycowsay-amd64:6d94bbb-dirty | jq
```

Dive into the app image
```bash
dive localhost:8000/containerfile mycowsay-amd64:6d94bbb-dirty
```

Export the image filesystem
```bash
mkdir mycowsay-filesystem
crane export localhost:8000/containerfile/mycowsay-amd64:6d94bbb-dirty cowsay-filesystem/image.tar
tar -C mycowsay-amd64 -xf cowsay-filesystem/image.tar
rm cowsay-filesystem/image.tar
```

Export the OCI Layout
```bash
oras copy --to-oci-layout localhost:8000/containerfile/mycowsay-amd64:6d94bbb-dirty cowsay-oci-layout
```

Untar one of the layers
```bash
mkdir -p cowsay-layer
tar -C cowsay-layer -zxf cowsay-oci-layout/blobs/sha256/fa18d4ad267d2422e136cee039f21941e8fef2da5074d5f6595a9785bdeba102
```

Run sha256sum on the layer
```bash
sha256sum cowsay-oci-layout/blobs/sha256/fa18d4ad267d2422e136cee039f21941e8fef2da5074d5f6595a9785bdeba102
```

Compare layers
```bash
crane manifest localhost:8000/containerfile/mycowsay-amd64:6d94bbb-dirty | jq '.layers[].digest'
crane manifest localhost:8000/containerfile/mycowsay-amd64:6d94bbb-dirty | jq '.annotations'

base_image_name=$(crane manifest localhost:8000/containerfile/mycowsay-amd64:6d94bbb-dirty | jq -r '.annotations.["org.opencontainers.image.base.name"]')
base_image_digest=$(crane manifest localhost:8000/containerfile/mycowsay-amd64:6d94bbb-dirty | jq -r '.annotations.["org.opencontainers.image.base.digest"]')
crane manifest $base_image_name@$base_image_digest | jq '.layers[].digest'
```
