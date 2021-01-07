ZIG_FILES=$(wildcard src/*.zig)
TARGET=target
BINS=${TARGET}/bin/zogs

.PHONY: build
build: ${BINS}

${BINS}: ${ZIG_FILES}
	zig build --prefix ${TARGET} 

.PHONY: test
test: ${ZIG_FILES}
	./scripts/test.sh

.PHONY: fmt
fmt: ${ZIG_FILES}
	zig fmt ${ZIG_FILES}