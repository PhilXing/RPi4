#!/bin/bash
make -f Makefile \
    DEVEL_MODE=TRUE \
    DEST_DIR="~/AmpereR/RPi4" \
    DEBUG=0 VER=0.01 BUILD=100 \
    all
