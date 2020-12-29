const std = @import("std");
const Allocator = std.mem.Allocator;
const net = std.net;
const fs = std.fs;
const os = std.os;
const fmt = std.fmt;

pub const io_mode = .evented;

pub fn main() anyerror!void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &general_purpose_allocator.allocator;

    var server = net.StreamServer.init(.{});
    defer server.deinit();

    var proxy = Proxy(1024).init(allocator);

    try server.listen(net.Address.parseIp("127.0.0.1", 34329) catch unreachable);
    std.debug.warn("listening at {}\n", .{server.listen_address});

    while (true) {
        const conn = try server.accept();
        var client = try proxy.NewClient(allocator, conn);
        std.debug.print("new client {}\n", .{proxy.n_clients});
    }
}

fn Proxy(n: usize) type {
    return struct {
        clients: std.AutoHashMap(*Client, void),
        n_clients: i32,
        allocator: *Allocator,

        const Self = @This();

        fn init(allocator: *Allocator) Self {
            const proxy = Self{
                .clients = std.AutoHashMap(*Client, void).init(allocator),
                .allocator = allocator,
                .n_clients = 0,
            };
            return proxy;
        }

        fn deinit(proxy: *Self) void {
            var it = proxy.clients.iterator();
            while (it.next()) |client| {
                _ = client.conn.file.close();
                proxy.allocator.destroy(client);
            }
        }

        fn broadcast(proxy: *Self, msg: []const u8, sender: *Client) void {
            var it = proxy.clients.iterator();
            while (it.next()) |entry| {
                const client = entry.key;
                if (client == sender) {
                    continue;
                }
                client.conn.file.writeAll(msg) catch |e| std.debug.warn("unable to send: {}\n", .{e});
            }
        }

        const ProxyT = @This();
        const Client = struct {
            id: i32,
            conn: net.StreamServer.Connection,
            handle_frame: @Frame(handle),
            proxy: *ProxyT,

            fn handle(self: *Client) !void {
                try fmt.format(self.conn.file.writer(), "client {}\n", .{self.id});
                var buf: [n]u8 = undefined;
                while (true) {
                    std.debug.print("loop iteration {}\n", .{self.id});
                    const amt = try self.conn.file.read(&buf);
                    const msg = buf[0..amt];
                    std.debug.print("broadcasting {}\n", .{self.id});
                    self.proxy.broadcast(msg, self);
                }
            }
        };

        fn NewClient(proxy: *Self, allocator: *Allocator, conn: net.StreamServer.Connection) !*Client {
            const client = try allocator.create(Client);
            client.conn = conn;
            proxy.n_clients += 1;
            client.id = proxy.n_clients;
            std.debug.print("starting handler\n", .{});
            client.handle_frame = async client.handle();
            std.debug.print("registering\n", .{});
            client.proxy = proxy;
            try proxy.clients.putNoClobber(client, {});
            return client;
        }
    };
}
