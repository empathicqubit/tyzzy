# tyzzy

A TI 83/84 Plus Z-Machine Interpreter. Based on [the TI C project template](https://github.com/empathicqubit/ti8xp-c-template).

It doesn't work yet! The game (HHGG) is set up and it prints text and stops at the first prompt.

![Preview](./preview.png)

Trust me. :) It's all there, it just renders weirdly.

## Build instructions

1. Clone down project
2. Install make
3. Load submodules `git submodule init && git submodule update --recursive`
4. Install z88dk 2.3+ on PATH
5. `make`
6. Get `ti83plus.rom` (Must manually download. Not included in project or curl'd for legal reasons) and put in gitroot
7. Get WabbitEmu `choco install wabbitemu --prerelease`
8. `make debug-emu`
