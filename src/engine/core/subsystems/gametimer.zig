// #region Namespace imports
const std = @import("std");
const builtin = @import("builtin");
// #endregion

var pf: i64 = undefined;

pub const GameTimer = struct {
    last_time: u64,

    pub fn start() GameTimer {

        if (builtin.os.tag  == .windows) {
            const win = std.os.windows.ntdll;
            if (!win.RtlQueryPerformanceFrequency(&pf).toBool()) {
                @panic("Failed to query performance frequency");
            }
        }

        return .{ .last_time = getNs() };
    }

    pub fn lap(self: *GameTimer) u64 {
        const now = getNs();
        const diff = now - self.last_time;
        self.last_time = now;
        return @intFromFloat(@as(f64, @floatFromInt(diff)) / @as(f32, @floatFromInt(std.time.ns_per_s)));
    }

    fn getNs() u64 {
        if (builtin.os.tag  == .windows) {
            const win = std.os.windows.ntdll;
            var pc: i64 = undefined;
            if (!win.RtlQueryPerformanceCounter(&pc).toBool()) {
                @panic("Failed to query performance counter");
            }
            return @intCast( (@as(u128, @intCast(pc)) * std.time.ns_per_s / @as(u128, @intCast(pf))));
        } else {
            var ts: std.c.timespec = undefined;
            std.c.clock_gettime(std.c.CLOCK.MONOTONIC, &ts);
            return @as(u64, @intCast(ts.tv_sec)) * std.time.ns_per_s + @as(u64, @intCast(ts.tv_nsec));
        }
    }
};