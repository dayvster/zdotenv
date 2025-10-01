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

test "load prints warning for missing file" {
    const allocator = std.testing.allocator;
    var dotenv = Dotenv.init(allocator);
    defer dotenv.deinit();

    // try to load a non-existent file and expect a warning
    try dotenv.load(&[_][]const u8{"test_missing.env"});
}

test "load handles malformed lines gracefully" {
    const allocator = std.testing.allocator;
    var dotenv = Dotenv.init(allocator);
    defer dotenv.deinit();

    const tmp_path = "malformed.env";
    const file = try std.fs.cwd().createFile(tmp_path, .{ .truncate = true });
    defer std.fs.cwd().deleteFile(tmp_path) catch {};
    try file.writeAll("VALID=ok\nMALFORMED_LINE\nANOTHER=good\n");
    try file.sync();
    file.close();

    // Print raw contents of malformed.env before parsing
    const read_file = try std.fs.cwd().openFile(tmp_path, .{});
    defer read_file.close();
    var buf: [128]u8 = undefined;
    const n = try read_file.readAll(&buf);
    std.debug.print("malformed.env contents: {s}\n", .{buf[0..n]});

    // Try to load and catch any error
    dotenv.load(&[_][]const u8{tmp_path}) catch |err| {
        std.debug.print("Caught expected error: {}\n", .{err});
    };
}

test "quoted values are parsed correctly" {
    const allocator = std.testing.allocator;
    var dotenv = Dotenv.init(allocator);
    defer dotenv.deinit();

    const tmp_path = "quoted.env";
    const file = try std.fs.cwd().createFile(tmp_path, .{ .truncate = true });
    defer std.fs.cwd().deleteFile(tmp_path) catch {};
    try file.writeAll("DB_URL=\"postgres://user:pass@localhost:5432/db\"\nSECRET='s3cr3t!'\nPLAIN=hello_world\nNAME=\"Dave P.\"\n");
    try file.sync();
    file.close();

    try dotenv.load(&[_][]const u8{tmp_path});
    std.debug.print("DB_URL: {s}\n", .{dotenv.get("DB_URL") orelse "<not found>"});
    std.debug.print("SECRET: {s}\n", .{dotenv.get("SECRET") orelse "<not found>"});
    std.debug.print("PLAIN: {s}\n", .{dotenv.get("PLAIN") orelse "<not found>"});
    std.debug.print("NAME: {s}\n", .{dotenv.get("NAME") orelse "<not found>"});
    try std.testing.expect(std.mem.eql(u8, dotenv.get("DB_URL") orelse "", "postgres://user:pass@localhost:5432/db"));
    try std.testing.expect(std.mem.eql(u8, dotenv.get("SECRET") orelse "", "s3cr3t!"));
    try std.testing.expect(std.mem.eql(u8, dotenv.get("PLAIN") orelse "", "hello_world"));
    try std.testing.expect(std.mem.eql(u8, dotenv.get("NAME") orelse "", "Dave S."));
}
