#!/bin/zsh
set -euo pipefail

device_id="$1"
output_path="$2"
shift 2

xcrun simctl launch --terminate-running-process "$device_id" devplaceholder.AGOFCAKT.JYH "$@" >/dev/null
sleep 3
xcrun simctl io "$device_id" screenConfig power on >/dev/null
sleep 2
xcrun simctl io "$device_id" screenConfig power on >/dev/null
sleep 2
xcrun simctl io "$device_id" screenshot "$output_path" >/dev/null
