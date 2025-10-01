//! Dotenv provides loading and management of environment variables from .env files.
const std = @import("std");

/// Dotenv struct holds environment variables loaded from files.
pub const Dotenv = struct {
    /// Hash map storing environment variable key-value pairs.
    env_map: std.StringHashMap([]const u8),

    /// Parse a file and load its environment variables into the map.
    fn parseFile(self: *Dotenv, path: []const u8) !void {
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();
        var buf: [1024]u8 = undefined;
        var line_buf: [512]u8 = undefined;
        var line_len: usize = 0;
        while (true) {
            const n = try file.read(buf[0..]);
            if (n == 0) break;
            try self.processBuffer(buf[0..n], &line_buf, &line_len);
        }
        if (line_len > 0) {
            try self.parseLine(line_buf[0..line_len]);
        }
    }

    /// Load environment variables from multiple file paths.
    pub fn load(self: *Dotenv, paths: []const []const u8) !void {
        const cwd = std.fs.cwd();
        for (paths) |path| {
            if (cwd.access(path, .{})) {
                try self.parseFile(path);
            } else |err| {
                if (err == error.FileNotFound) {
                    std.debug.print("Warning: .env file not found: {s}\n", .{path});
                } else {
                    return err;
                }
            }
        }
    }

    /// Free all memory allocated for environment variables and clear the map.
    pub fn deinit(self: *Dotenv) void {
        var it = self.env_map.iterator();
        while (it.next()) |entry| {
            const allocator = self.env_map.allocator;
            allocator.free(entry.key_ptr.*);
            allocator.free(entry.value_ptr.*);
        }
        self.env_map.deinit();
    }

    /// Initialize a new Dotenv instance with the given allocator.
    pub fn init(allocator: std.mem.Allocator) Dotenv {
        return Dotenv{
            .env_map = std.StringHashMap([]const u8).init(allocator),
        };
    }

    /// Process a buffer of bytes, splitting into lines and parsing each line.
    fn processBuffer(self: *Dotenv, buf: []const u8, line_buf: *[512]u8, line_len: *usize) !void {
        for (buf) |b| {
            if (b == '\n' or b == '\r') {
                if (line_len.* > 0) {
                    try self.parseLine(line_buf.*[0..line_len.*]);
                    line_len.* = 0;
                }
            } else if (line_len.* < line_buf.*.len) {
                line_buf.*[line_len.*] = b;
                line_len.* += 1;
            }
        }
    }

    /// Parse a single line and insert key-value pair into the map if valid.
    fn parseLine(self: *Dotenv, line: []const u8) !void {
        const trimmed = std.mem.trim(u8, line, " \t\r\n");
        if (trimmed.len == 0 or trimmed[0] == '#') return;
        const eq_idx = std.mem.indexOfScalar(u8, trimmed, '=');
        if (eq_idx) |eq| {
            const key = std.mem.trim(u8, trimmed[0..eq], " \t");
            const value = std.mem.trim(u8, trimmed[eq + 1 ..], " \t");
            if (key.len == 0) return;
            const allocator = self.env_map.allocator;
            const key_copy = try allocator.alloc(u8, key.len);
            std.mem.copyForwards(u8, key_copy, key);
            const value_copy = try allocator.alloc(u8, value.len);
            std.mem.copyForwards(u8, value_copy, value);
            try self.env_map.put(key_copy, value_copy);
        }
    }

    /// Get the value for a given environment variable key, or null if not found.
    pub fn get(self: *Dotenv, key: []const u8) ?[]const u8 {
        return self.env_map.get(key);
    }
};
