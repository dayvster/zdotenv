//! By convention, root.zig is the root source file when making a library.

const std = @import("std");
pub const Dotenv = @import("dotenv.zig").Dotenv;
pub const detectDefaultPaths = @import("dotenv.zig").detectDefaultPaths;
