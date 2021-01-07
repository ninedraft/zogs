const std = @import("std");
const testing = std.testing;

pub fn testCodec(buf: []u8, v: anytype) !void {
    const expected = v;
    const n = expected.marshal(buf);
    var got = try @TypeOf(expected).unmarshal(buf[0..n]);
    testing.expect(got == expected);
}

pub fn testCodecs(comptime test_cases: anytype) !void {
    const t = @TypeOf(test_cases[0]);
    var buf: [t.marshal_size]u8 = undefined;
    inline for (test_cases) |test_case| {
        try testCodec(&buf, test_case);
    }
}
