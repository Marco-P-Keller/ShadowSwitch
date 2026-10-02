#!/bin/bash
# usage: tools/shots.sh scene:delay ...   -> marketing/raw/<scene>.png (landscape)
SIM=${SIM:-F72681A9-B3C5-40DA-ABF4-3CAE8AE7ACD6}
cd "$(dirname "$0")/.."
for spec in "$@"; do
  scene=${spec%%:*}; delay=${spec##*:}
  xcrun simctl terminate $SIM com.connexa.shadowswitch >/dev/null 2>&1
  xcrun simctl launch $SIM com.connexa.shadowswitch -demo $scene >/dev/null
  sleep $delay
  xcrun simctl io $SIM screenshot marketing/raw/$scene.png >/dev/null 2>&1
  sips -r 270 marketing/raw/$scene.png >/dev/null
  echo "$scene ok"
done
