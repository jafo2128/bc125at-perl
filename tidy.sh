#!/bin/sh

set -x

for a in bc125at-perl lib/*.pm lib/Bc125At/*.pm lib/Bc125At/*/*.pm t/*.t; do
    perltidy -pt=2 -l=140 -b $a
done
