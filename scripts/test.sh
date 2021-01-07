#!/usr/bin/env bash

zig_files=(src/*.zig)

for file in "${zig_files[@]}"
do
    zig test "$file"
done