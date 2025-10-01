# dotenv.zig

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![zig](https://img.shields.io/badge/zig-0.15%2B-orange)](https://ziglang.org/)
[![Docs](https://img.shields.io/badge/docs-generated-blue)](https://ziglang.org/documentation/)

A simple Zig library for loading environment variables from `.env` files.

## Installation

Fetch the package with Zig:
```sh
zig fetch https://github.com/YOUR_GITHUB_USERNAME/dotenv.zig
```
Then add it as a module in your `build.zig`:
```zig
const dotenv_mod = b.addModule("dotenv", .{
    .root_source_file = b.path("src/root.zig"),
    .target = target,
});
```

## Features
- Loads key-value pairs from one or more `.env` files
- Ignores comments and blank lines
- Provides easy access to environment variables via a hash map
- Memory-safe: all allocations are freed with `deinit`

## Usage

### Example
See [`examples/basic.zig`](examples/basic.zig):
```zig
const std = @import("std");
const Dotenv = @import("dotenv").Dotenv;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var dotenv = Dotenv.init(allocator);
    defer dotenv.deinit();
    try dotenv.load(&[_][]const u8{"./examples/example.env"});
    if (dotenv.get("FOO")) |val| {
        std.debug.print("FOO={s}\n", .{val});
    } else {
        std.debug.print("FOO not found\n", .{});
    }
}
```

With an `example.env` file:
```
FOO=bar
BAZ=qux
```

### API
- `Dotenv.init(allocator)` — create a new instance
- `Dotenv.load(paths)` — load one or more `.env` files
- `Dotenv.get(key)` — get the value for a key
- `Dotenv.deinit()` — free all memory

## Testing
Run all tests:
```sh
zig build test
```

## License
MIT
