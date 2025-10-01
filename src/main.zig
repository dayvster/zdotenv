const std = @import("std");
const Dotenv = @import("./dotenv.zig").Dotenv;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var dotenv = Dotenv.init(allocator);
    defer dotenv.deinit();
    if (dotenv.get("MY_KEY")) |val| {
        std.debug.print("MY_KEY={s}\n", .{val});
    } else {
        std.debug.print("MY_KEY not found in .env files\n", .{});
    }
}

test "dotenv loads and gets values" {
    const allocator = std.testing.allocator;
    var dotenv = Dotenv.init(allocator);
    defer dotenv.deinit();

    const tmp_path = "test.env";
    const file = try std.fs.cwd().createFile(tmp_path, .{ .truncate = true });
    defer std.fs.cwd().deleteFile(tmp_path) catch {};
    try file.writeAll("FOO=bar\nBAZ=qux\n");
    try file.sync();
    file.close();

    // Print raw contents of test.env before parsing
    const read_file = try std.fs.cwd().openFile(tmp_path, .{});
    defer read_file.close();
    var buf: [128]u8 = undefined;
    const n = try read_file.readAll(&buf);
    std.debug.print("test.env contents: {s}\n", .{buf[0..n]});

    try dotenv.load(&[_][]const u8{tmp_path});
    var it = dotenv.env_map.iterator();
    while (it.next()) |entry| {
        std.debug.print("Loaded: {s}={s}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }
    try std.testing.expect(std.mem.eql(u8, dotenv.get("FOO") orelse "", "bar"));
    try std.testing.expect(std.mem.eql(u8, dotenv.get("BAZ") orelse "", "qux"));
    try std.testing.expect(dotenv.get("NOTFOUND") == null);
}
