const std = @import("std");
const Allocator = std.mem.Allocator;
const EventEmitter = @import("events.zig").EventEmitter;

pub const EngineEvents = enum {
    Inputs,
    Render,
    Process,
};

pub var event_emitter: EventEmitter(EngineEvents) = undefined;

pub fn init(allocator: Allocator) !void {
    event_emitter = try EventEmitter(EngineEvents).init(allocator);
}
