const std = @import("std");
const actions = @import("actions.zig");
const ActionPreviewList = @This();
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Actor = @import("Actor.zig");

list: std.ArrayList(actions.ActionPreview),
allocator: Allocator,

pub fn init(allocator: Allocator) ActionPreviewList {
    return .{
        .list = ArrayList(actions.ActionPreview).init(allocator),
        .allocator = allocator,
    };
}

pub fn deinit(self: *ActionPreviewList) void {
    self.list.deinit();
}

pub fn clear(self: *ActionPreviewList) !void {
    for (self.list.items) |preview| {
        try preview.deinit();
    }
    self.list.clearAndFree();
}

pub fn feed(self: *ActionPreviewList, actors: ArrayList(*Actor)) !void {
    try self.clear();

    for (actors.items) |actor| {
        if (actor.next_action) |action| {
            try self.list.append(try action.preview(self.allocator));
        }
    }
}
