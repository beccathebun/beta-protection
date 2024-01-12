#!/usr/bin/env bash
source ./.env

function _check_status {
  if [ $? -ne 0 ]; then
    echo "something went wrong :c"
    exit 1
  fi
}
MANIFEST_LOCATION="manifests/manifest.prod.json"
ARCHIVE_NAME="betaprotection.zip"


if [ "$BUILD_MODE" = "develop" ]; then
  MANIFEST_LOCATION="manifests/manifest.devel.json"
  ARCHIVE_NAME="betaprotection-devel.zip"
  echo "building with dev id"
else
echo "building with prod id"

fi

rm "src/manifest.json" && cp "$MANIFEST_LOCATION" "src/manifest.json"
NODE_OPTIONS=--openssl-legacy-provider vue-cli-service build
_check_status
cd dist && zip -r -FS "../$ARCHIVE_NAME" * --exclude '*.git*' >> /dev/null
_check_status
echo "all done! :3"
exit 0