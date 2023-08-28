const std = @import("std");
const bstr = @import("bit-string");

const InstrFn = @import("../avr.zig").InstrFn;
const Cpu = @import("../avr.zig").Cpu;

const log = std.log.scoped(.avr_ldi);

pub fn handler(comptime k: u8) InstrFn {
    return struct {
        fn inner(cpu: *Cpu, opcode: u16) void {
            const ret = bstr.extract("1110----dddd----", opcode);
            const rd = @as(u5, 0x10) + ret.d;
            log.debug("ldi r{}, 0x{X:0>2}", .{ rd, k });

            cpu.r[rd] = k;
        }
    }.inner;
}
