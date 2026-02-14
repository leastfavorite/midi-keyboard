#!/bin/sh
set -ex

ROOTDIR=$(git rev-parse --show-toplevel)
[[ -n "$ROOTDIR" ]]

python3 -m venv $ROOTDIR/.venv
source $ROOTDIR/.venv/bin/activate
pip3 install west

west update

pip3 install -r deps/zephyr/scripts/requirements.txt
pip3 install -r deps/nrf/scripts/requirements.txt
pip3 install -r deps/bootloader/mcuboot/scripts/requirements.txt
