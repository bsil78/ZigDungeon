// #region Namespace imports
const std = @import("std");
// #endregion

pub fn LimitedQueue(comptime QUEUE_SIZE: u16, comptime ITEMS_TYPE: anytype) type {
    return struct {
        pub const TYPE = LimitedQueue(QUEUE_SIZE, ITEMS_TYPE);

        _head: u16 = 0,
        _tail: u16 = 0,
        _items: [QUEUE_SIZE]ITEMS_TYPE = undefined,

        pub const Error = error{ QueueIsFull, QueueIsEmpty };

        pub fn capacity() u16 {
            return QUEUE_SIZE;
        }
        pub fn size(self: TYPE) u16 {
            if (self._tail <= self._head) return self._head-self._tail;
            return self._head+(QUEUE_SIZE-self._tail)-1;
        }

        pub fn isEmpty(self: TYPE) bool {
            return self.size() == 0;
        }

        pub fn isFull(self: TYPE) bool {
            return self.size() == QUEUE_SIZE;
        }

        pub fn push(self: *TYPE, item: ITEMS_TYPE) Error!void {
            if (self.isFull()) {
                return Error.QueueIsFull;
            }
            self._items[self._head] = item;
            if (self._head == QUEUE_SIZE - 1) {
                self._head = 0;
            } else {
                self._head += 1;
            }
            //self.debug("PUSH");
        }

        pub fn pop(self: *TYPE) Error!ITEMS_TYPE {
            if (self.isEmpty()) {
                return Error.QueueIsEmpty;
            }
            const item = self._items[self._tail];
            if (self._tail == QUEUE_SIZE - 1) {
                self._tail = 0;
            } else {
                self._tail += 1;
            }
            //self.debug("POP");
            return item;
        }

        fn debug(self: *TYPE, op: []const u8) void {
            std.log.info("QUEUE {s} (size : {d})", .{ op, self.size() });
            if (self.size() == 0) return;
            std.log.info(" : {{ ", .{});

            for (0..QUEUE_SIZE) |i| {
                if (self.isInQueue(i)) {
                    std.log.info("<{d}>", .{i});
                    if (self._head == i) {
                        std.log.info("^", .{});
                    }
                    if (self._tail == i) {
                        std.log.info("$", .{});
                    }
                    std.log.info(":{any} ", .{self._items[i]});
                }
            }
            std.log.info("}}\n", .{});
        }

        fn isInQueue(self: *TYPE, index: usize) bool {
            if (self._head == self._tail) {
                return false;
            }
            if ( self._tail < self._head) {
                return self._tail < index and index < self._head;
            }
            return index < self._head or self._tail < index;
        }
    };
}
