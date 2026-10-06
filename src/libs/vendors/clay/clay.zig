const std = @import("std");
const raylib = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
    @cInclude("rlgl.h");
});

pub const clay = @import("zclay");

pub const Rect = @import("../../maths/maths.zig").geometry.shapes.Rect;

pub const clay_helper = struct {
    const max_text_length = 256;

    pub fn initialize(allocator: std.mem.Allocator, window_size: Rect(u32)) !void {
        _ = try clay.initializeAlloc(allocator, .{
            .w = @floatFromInt(window_size.w),
            .h = @floatFromInt(window_size.h),
        }, .{});
        clay.setMeasureTextFunction(void, {}, measureText);
    }

    pub fn measureText(text: []const u8, config: *clay.TextElementConfig, _: void) clay.Dimensions {
        var buffer: [max_text_length + 1]u8 = undefined;
        const c_text = nullTerminate(text, &buffer);
        return .{
            .w = @floatFromInt(raylib.MeasureText(c_text, @intCast(config.font_size))),
            .h = @floatFromInt(config.font_size),
        };
    }

    pub fn renderCommands(commands: []clay.RenderCommand) void {
        for (commands) |command| {
            const bounds = command.bounding_box;
            switch (command.command_type) {
                .rectangle => {
                    const data = command.render_data.rectangle;
                    raylib.DrawRectangleRec(.{
                        .x = bounds.x,
                        .y = bounds.y,
                        .width = bounds.width,
                        .height = bounds.height,
                    }, toRaylibColor(data.background_color));
                },
                .text => {
                    const data = command.render_data.text;
                    const text = data.string_contents.chars[0..@intCast(data.string_contents.length)];
                    var buffer: [max_text_length + 1]u8 = undefined;
                    const c_text = nullTerminate(text, &buffer);
                    raylib.DrawText(
                        c_text,
                        @intFromFloat(bounds.x),
                        @intFromFloat(bounds.y),
                        @intCast(data.font_size),
                        toRaylibColor(data.text_color),
                    );
                },
                else => {},
            }
        }
    }

    fn nullTerminate(text: []const u8, buffer: *[max_text_length + 1]u8) [:0]const u8 {
        if (text.len > max_text_length) @panic("Clay text exceeds the render buffer");
        @memcpy(buffer[0..text.len], text);
        buffer[text.len] = 0;
        return buffer[0..text.len :0];
    }

    fn toRaylibColor(color: clay.Color) raylib.Color {
        return .{
            .r = @intFromFloat(color[0]),
            .g = @intFromFloat(color[1]),
            .b = @intFromFloat(color[2]),
            .a = @intFromFloat(color[3]),
        };
    }
};
