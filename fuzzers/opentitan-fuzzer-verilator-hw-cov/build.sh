#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
export BUILD_JOBS=${BUILD_JOBS:-8}
if [[ ! $BUILD_JOBS =~ ^[1-9][0-9]*$ ]]; then
    echo 'BUILD_JOBS must be a positive integer.' >&2
    exit 2
fi
for tool in cargo fusesoc verilator git make; do
    command -v "$tool" >/dev/null || {
        echo "Missing $tool; see README.md for dependencies." >&2
        exit 1
    }
done

cargo build --locked -j"$BUILD_JOBS"

opentitan="$PWD/fusesoc_libraries/opentitan"
revision=c9262fc2964e47b80d2a2f652e58014c42b651d7
if [[ ! -d "$opentitan" ]]; then
    git init "$opentitan"
    git -C "$opentitan" remote add origin https://github.com/timothytrippel/opentitan.git
    git -C "$opentitan" fetch --depth=1 origin "$revision"
    git -C "$opentitan" checkout --detach FETCH_HEAD
fi
if [[ $(git -C "$opentitan" rev-parse HEAD) != "$revision" ]]; then
    echo "Expected OpenTitan revision $revision in $opentitan." >&2
    echo 'Move the existing checkout aside before rebuilding.' >&2
    exit 1
fi

# Keep the example's modified AES core and testbench outside the downloaded RTL.
# Only these two library roots are scanned; user FuseSoC libraries stay separate.
overlay="$PWD/build/fusesoc-overlay"
mkdir -p "$overlay"
cp aes.core "$overlay/aes.core"
ln -sfn "$opentitan/hw/ip/aes/rtl" "$overlay/rtl"
ln -sfn "$opentitan/hw/ip/aes/lint" "$overlay/lint"
ln -sfn "$PWD/tb" "$overlay/tb"
printf '[main]\n' > build/fusesoc.conf

MAKEFLAGS="-j$BUILD_JOBS" fusesoc --config "$PWD/build/fusesoc.conf" \
    --cores-root "$overlay" --cores-root "$opentitan" \
    run --build --flag=fileset_ip --target=syn presifuzz:ip:aes:0.6 --SYNTHESIS \
    --verilator_options="+incdir+$PWD/tb -I$PWD/tb/include --coverage-toggle --timing --report-unoptflat --cc --exe $PWD/tb/src/ot_ip_fuzz_tb.cpp $PWD/tb/src/stdin_fuzz_tb.cpp $PWD/tb/src/tlul_host_tb.cpp $PWD/tb/src/verilator_tb.cpp $PWD/tb/src/main.cpp" \
    --make_options "CXXFLAGS=-I$PWD/tb/include"
ln -sfn presifuzz_ip_aes_0.6/syn-verilator/Vaes_tb build/Vaes_tb
test -x build/Vaes_tb
