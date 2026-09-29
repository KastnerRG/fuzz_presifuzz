<!--
SPDX-FileCopyrightText: 2022 Intel Corporation

SPDX-License-Identifier: Apache-2.0
-->

# Fuzzing OpenTitan AES

This example fuzzes the OpenTitan AES IP with LibAFL and Verilator toggle coverage.
It builds and runs independently from this repository's Docker setup.

## Dependencies

Install Git, Make, a C++ compiler, Python 3 with `venv`, Rustup, and Verilator 5.038.
The example's `rust-toolchain.toml` selects Rust 1.90.0.
Its committed `Cargo.lock` and pinned upstream LibAFL revision include the TypeId alignment fix needed by this Rust version.

Install the tested Python tools in a virtual environment:

```sh
python3 -m venv "$HOME/.venvs/presifuzz"
source "$HOME/.venvs/presifuzz/bin/activate"
pip install setuptools==68.2.2 setuptools-scm==7.1.0 wheel
pip install --no-build-isolation \
  git+https://github.com/lowRISC/fusesoc.git@14dfc825ced58fe1fb343662fa80fc4fbd0fdc50 \
  git+https://github.com/lowRISC/edalize.git@5ae2c3e1ca306e27d81ce5fcc769f62cb7ac42d0 \
  hjson==3.1.0 Mako==1.4.3
```

Ensure `cargo`, `fusesoc`, and `verilator` are on `PATH` when building.
The first build downloads the pinned Rust dependencies and OpenTitan revision `c9262fc2964e47b80d2a2f652e58014c42b651d7`.

## Build and run

From the PreSiFuzz repository root:

```sh
cd fuzzers/opentitan-fuzzer-verilator-hw-cov
BUILD_JOBS=8 ./build.sh
./run.sh
```

`build.sh` builds both the Rust fuzzer and the AES simulator.
`run.sh` reuses that build entrypoint and starts fuzzing the bundled `seeds` directory.
Subsequent invocations preserve the downloaded RTL and build caches.
Pass a different corpus or fuzzer options as arguments to `run.sh`, or run `./target/debug/opentitan-fuzzer --help`.
Stop a campaign with Ctrl+C.

The example-owned `aes.core` selects the local AES replacement and testbench under `tb/`.
The build creates a FuseSoC overlay under `build/` and leaves the downloaded OpenTitan source unchanged.
The simulator is available as `build/Vaes_tb`.
Each completed simulation publishes its toggle coverage atomically to `logs/coverage.dat`.
See [Verilator's coverage documentation](https://verilator.org/guide/latest/exe_verilator_coverage.html) for aggregation options.

## Credits

This example adapts [Timothy Trippel et al.'s hardware fuzzing work](https://github.com/googleinterns/hw-fuzzing) to use Verilator hardware coverage as LibAFL feedback.
The seeds and C++ testbench originate from that project.
The RTL comes from the [OpenTitan team](https://opentitan.org/).

