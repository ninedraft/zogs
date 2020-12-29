const std = @import("std");
const builtin = std.builtin;
const expect = std.testing.expect;

const D = packed struct {
    v: u8,
    vads: i16,
};

test "resume from suspend" {
    const d = D{
        .v = 1,
        .vads = 213,
    };
    var xx: [@sizeOf(D)]u8 = undefined;
    marshalBinary(builtin.Endian.Little, &xx, d);
    std.debug.print("\n", .{});
    for (xx) |x| {
        std.debug.print("{}\n", .{x});
    }
    std.debug.print("\n", .{});
}

fn marshalBinary(comptime endianess: builtin.Endian, dst: anytype, v: anytype) void {
    const dst_t = @TypeOf(dst.*);
    const info = @typeInfo(dst_t).Array.child;
    dst.* = @bitCast(dst_t, v);
    if (endianess != builtin.cpu.arch.endian()) {
        dst.* = @byteSwap(info, dst.*);
    }
}
