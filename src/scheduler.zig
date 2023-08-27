const std = @import("std");

const Cpu = @import("Cpu.zig");
const Bus = @import("Bus.zig");

const Order = std.math.Order;
const PriorityQueue = std.PriorityQueue;
const Allocator = std.mem.Allocator;
const log = std.log.scoped(.scheduler);

pub const Scheduler = struct {
    const Self = @This();

    tick: u64 = 0,
    queue: PriorityQueue(Event, void, lessThan),

    pub fn init(allocator: Allocator) Self {
        var scheduler = .{ .queue = PriorityQueue(Event, void, lessThan).init(allocator, {}) };
        scheduler.queue.add(.{ .kind = .heat_death, .tick = std.math.maxInt(u64) }) catch unreachable;

        return scheduler;
    }

    pub fn deinit(self: Self) void {
        self.queue.deinit();
    }

    pub inline fn now(self: *const Self) u64 {
        return self.tick;
    }

    pub fn push(self: *Self, kind: Event.Kind, end: u64) void {
        self.queue.add(.{ .kind = kind, .tick = self.tick + end }) catch unreachable;
    }

    pub fn nextEventTick(self: *const Self) u64 {
        return self.queue.items[0].tick;
    }
};

fn lessThan(_: void, left: Event, right: Event) Order {
    return std.math.order(left.tick, right.tick);
}

const Event = struct {
    kind: Kind,
    tick: u64,

    const Kind = enum { heat_death };
};
