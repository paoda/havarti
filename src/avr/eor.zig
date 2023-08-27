const std = @import("std");

const InstrFn = @import("../avr.zig").InstrFn;
const Cpu = @import("../avr.zig").Cpu;

const log = std.log.scoped(.avr_eor);

pub fn handler(comptime r: u4) InstrFn {
    return struct {
        fn inner(cpu: *Cpu, opcode: u16) void {
            const rd = opcode >> 4 & 0x1F;
            const rr = (opcode >> 9 & 1) << 4 | r;
            log.debug("eor r{}, r{}", .{ rd, rr });

            cpu.r[rd] = cpu.r[rd] ^ cpu.r[rr];
        }
    }.inner;
}
