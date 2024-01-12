#!/usr/bin/env bash
function _check_status {
  if [ $? -ne 0 ]; then
    echo "something went wrong :c"
    exit 1
  fi
}
NODE_OPTIONS=--openssl-legacy-provider vue-cli-service build >> /dev/null
_check_status
cd dist && zip -r -FS ../betaprotection.zip * --exclude '*.git*' >> /dev/null
_check_status
echo "all done! :3"
exit 0