const vmstdlib = @import("vmstdlib.zig");

pub export fn initialize() void {
    _ = vmstdlib.abs(0);
}
