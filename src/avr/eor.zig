const std = @import("std");

const InstrFn = @import("../avr.zig").InstrFn;
const Cpu = @import("../avr.zig").Cpu;

const log = std.log.scoped(.avr_eor);

pub fn handler(comptime rr: u5) InstrFn {
    return struct {
        fn inner(cpu: *Cpu, opcode: u16) void {
            const rd = opcode >> 4 & 0x1F;
            log.debug("eor r{}, r{}", .{ rd, rr });

            const value = cpu.r[rd] ^ cpu.r[rr];
            cpu.r[rd] = value;

            cpu.sreg.zero = value == 0x00;
            cpu.sreg.negative = value >> 7 == 0b1;
            cpu.sreg.overflow = false;
            cpu.sreg.sign = cpu.sreg.negative != cpu.sreg.overflow;
        }
    }.inner;
}
