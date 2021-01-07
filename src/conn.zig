const std = @import("std");
const Allocator = std.mem.Allocator;
const builtin = std.builtin;
const io = @import("io");
const headers = @import("header.zig");

const Error = error{InvalidProtocolVersion};

fn Conn(conn: anytype) type {
    return struct {
        pub const Underlying = conn;
        pub const file = conn.file;
        pub const address = conn.address;

        const Self = @This();
        const re = file.Reader;
        const wr = file.Writer;

        pub fn acceptHello(self: Self, allocator: *Allocator, dst: *headers.Client.Hello) !void {
            const client_version = try re.readIntLittle(u8);
            if (client_version != headers.protocol_version) {
                return Error.InvalidProtocolVersion;
            }
            const num_auth_methods = try re.readIntLittle(u8);
            var auth_methods: [num_auth_methods]headers.Client.AuthMethod = undefined;
            while (num_auth_methods > 0) : (num_auth_methods -= 1) {
                const method = try re.readEnum(headers.Client.AuthMethod, builtin.Endian.Little);
                auth_methods[num_auth_methods - 1] = method;
            }
            dst.* = .{
                .version = client_version,
                .n_methods = num_auth_method,
                .methods = &auth_methods,
            };
        }

        pub fn write(self: Self, bytes: []const u8) Error!usize {
            return self.file.write(bytes);
        }
    };
}
