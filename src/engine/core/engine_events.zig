const std = @import("std");
const Allocator = std.mem.Allocator;
const EventEmitter = @import("../observer/observer.zig").EventEmitter;

pub const EngineEvents = enum {
    inputs,
    render,
    process,
};

pub var event_emitter: EventEmitter(EngineEvents) = undefined;

pub fn init(allocator: Allocator) !void {
    event_emitter = try EventEmitter(EngineEvents).init(allocator);
}
