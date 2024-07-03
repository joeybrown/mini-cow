# Demo #3 - Artifacts & Attachments

1. Create Keys
```bash
export COSIGN_PASSWORD="mysecurep@ssw0rd"
mkdir -p $BASE_DIR/cosign
bash -c "cd $BASE_DIR/cosign && cosign generate-key-pair"
```

2. Sign Image
```bash
export IMAGE_REFERENCE=$REGISTRY/buildpack/$EXECUTABLE@$(crane digest $BUILDPACK_IMAGE)
cosign sign --key $BASE_DIR/cosign/cosign.key --tlog-upload=false $IMAGE_REFERENCE
```

3. Look at the Signature
```bash
export SIG_TAG=$(crane digest $BUILDPACK_IMAGE | sed 's/sha256:/sha256-/').sig
export SIG_REFERENCE=$REGISTRY/buildpack/$EXECUTABLE:$SIG_TAG 
crane manifest $SIG_REFERENCE | jq

export SIG_LAYER=$(crane manifest $SIG_REFERENCE | \
  jq -r '.layers[] | select(.mediaType == "application/vnd.dev.cosign.simplesigning.v1+json")')
export SIGNATURE=$(echo $SIG_LAYER | jq -r '.annotations."dev.cosignproject.cosign/signature"')  
export SIG_PAYLOAD_DIGEST=$(echo $SIG_LAYER | jq -r '.digest')
```

4. Verify the signature manually
```bash
export SIG_LAYER=$(crane manifest $SIG_REFERENCE | \
  jq -r '.layers[] | select(.mediaType == "application/vnd.dev.cosign.simplesigning.v1+json")')
export SIGNATURE=$(echo $SIG_LAYER | jq -r '.annotations."dev.cosignproject.cosign/signature"')  
export SIG_PAYLOAD_DIGEST=$(echo $SIG_LAYER | jq -r '.digest')
curl -fsSL -H "Accept: application/octet-stream" -o $BASE_DIR/cosign/sig_payload.json $REGISTRY/v2/buildpack/$EXECUTABLE/blobs/$SIG_PAYLOAD_DIGEST
echo $SIGNATURE | base64 -d > $BASE_DIR/cosign/signature.txt
openssl dgst -sha256 -verify $BASE_DIR/cosign/cosign.pub -signature $BASE_DIR/cosign/signature.txt $BASE_DIR/cosign/sig_payload.json
echo 'Note: this only verifies the signature. You should also check the content of the payload (claims)!'
```

5. Verify the Signature with cosign
```bash
cosign verify --key $BASE_DIR/cosign/cosign.pub --insecure-ignore-tlog=true $IMAGE_REFERENCE
```

6. Push some stuff with ORAS
```bash
ARTIFACT_DIGEST=$(bash -c "cd $BASE_DIR/hack && oras push $REGISTRY/artifacts/$EXECUTABLE --artifact-type application/vnd.joey.cow-say.v1 \
  demo1.md:application/vnd.joey.cow-say.v1+md \
  demo2.md:application/vnd.joey.cow-say.v1+md \
  demo3.md:application/vnd.joey.cow-say.v1+md \
  demo4.md:application/vnd.joey.cow-say.v1+md \
  --format json | jq -r '.digest'")
mkdir -p $BASE_DIR/oras

curl -fsSL -H "Accept: application/vnd.oci.image.manifest.v1+json" -o $BASE_DIR/oras/manifest.json $REGISTRY/v2/artifacts/$EXECUTABLE/manifests/$ARTIFACT_DIGEST

oras pull --output $BASE_DIR/oras $REGISTRY/artifacts/$EXECUTABLE@$ARTIFACT_DIGEST

```
