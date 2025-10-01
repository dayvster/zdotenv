const std = @import("std");
const Dotenv = @import("dotenv").Dotenv;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var dotenv = Dotenv.init(allocator);
    defer dotenv.deinit();
    const env_path = "./examples/example.env";
    try dotenv.load(&[_][]const u8{env_path});

    var it = dotenv.env_map.iterator();
    std.debug.print("Found keys/values in env file:\n", .{});
    while (it.next()) |entry| {
        std.debug.print("  {s} = {s}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }

    const expected = [_][]const u8{ "FOO", "BAZ", "NOTFOUND" };
    for (expected) |key| {
        if (dotenv.get(key)) |val| {
            std.debug.print("Key '{s}' found: {s}\n", .{ key, val });
        } else {
            std.debug.print("Key '{s}' NOT found\n", .{key});
        }
    }
}
