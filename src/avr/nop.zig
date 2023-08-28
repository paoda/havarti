const std = @import("std");

const InstrFn = @import("../avr.zig").InstrFn;
const Cpu = @import("../avr.zig").Cpu;

const log = std.log.scoped(.avr_nop);

pub fn handler() InstrFn {
    return struct {
        fn inner(_: *Cpu, _: u16) void {
            log.debug("nop", .{});
        }
    }.inner;
}
