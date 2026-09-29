#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
./build.sh
if (($# == 0)); then
    set -- ./seeds
fi
exec ./target/debug/opentitan-fuzzer "$@"
