const std = @import("std");
const Allocator = std.mem.Allocator;
const mem = std.mem;
const testing = std.testing;
const testutils = @import("./testing.zig");
const fmt = std.fmt;

pub const protocol_version: u8 = 5;

const UnmarshalError = error{NotEnoughBytes};

const Client = struct {
    pub const AuthMethod = packed enum(u8) {
        NoAuth = 0x00,
        GSSAPI = 0x01,
        UsernamePassword = 0x02,
        NoMethods = 0xFF,
    };

    const Hello = struct {
        version: u8 = protocol_version,
        n_methods: u8,
        methods: []AuthMethod,
    };

    const Request = packed struct {
        version: u8 = protocol_version,
        cmd: Cmd,
        _: u8,
        address_type: AddressType,
        dst_address: Address,
        dst_port: Port,
    };
};

const Server = struct {
    const AuthWith = packed struct {
        version: u8 = protocol_version,
        method: AuthMethod,
    };
};

const Cmd = enum(u8) {
    connect = 1,
    bind = 2,
    udp_associate = 3,
};

const AddressType = enum(u8) {
    IPv4 = 1,
    DomainName = 3,
    IPv6 = 5,

    pub fn format(value: @This(), comptime f: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        const str = switch (value) {
            AddressType.IPv4 => "IPv4",
            AddressType.DomainName => "domain name",
            AddressType.IPv6 => "IPv6",
        };
        _ = try writer.write(str);
    }
};

// we really don't need any special format tests, I just want to learn how to write zig testing.
test "format address type" {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &general_purpose_allocator.allocator;

    const test_cases = .{
        .{ .aty = AddressType.IPv4, .expected = "IPv4" },
        .{ .aty = AddressType.DomainName, .expected = "domain name" },
        .{ .aty = AddressType.IPv6, .expected = "IPv6" },
    };

    inline for (test_cases) |test_case| {
        const got = try fmt.allocPrint(allocator, "{}", .{test_case.aty});
        defer allocator.free(got);
        testing.expect(mem.eql(u8, got, test_case.expected));
    }
}

const Addr = []const u8;

const Port = u16;
