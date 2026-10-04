// #region Namespace imports
const std = @import("std");
const builtin = @import("builtin");
// #endregion

pub const Timer = struct {
    last_time: u64 = 0,

    fn getWinPerformanceCounter() i64 {
        var pf: i64 = 0;
        const win = std.os.windows.ntdll;
        if (!win.RtlQueryPerformanceFrequency(&pf).toBool()) {
            std.debug.panic("Failed to query Windows performance frequency",.{});
        }
        return pf;
    }

    pub fn start(self: *Timer) u64 {
        if (self.last_time != 0) {
            std.debug.panic("Cannot start timer twice !", .{});
        }
        self.last_time = Timer.getNs();
        return self.last_time;
    }

    pub fn lap(self: *Timer) u64 {
        const now = Timer.getNs();
        const diff = now - self.last_time;
        self.last_time = now;
        return @intFromFloat(@as(f64, @floatFromInt(diff)) / @as(f32, @floatFromInt(std.time.ns_per_s)));
    }

    pub fn getNs() u64 {
        if (builtin.os.tag == .windows) {
            const pc= getWinPerformanceCounter();
            return @intCast((@as(u128, @intCast(pc)) * std.time.ns_per_s / @as(u128, @intCast(pc))));
        } else {
            var ts: std.c.timespec = undefined;
            std.c.clock_gettime(std.c.CLOCK.MONOTONIC, &ts);
            return @as(u64, @intCast(ts.tv_sec)) * std.time.ns_per_s + @as(u64, @intCast(ts.tv_nsec));
        }
    }
};
