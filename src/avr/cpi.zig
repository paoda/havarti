const std = @import("std");
const bstr = @import("bit-string");

const halfCarry = @import("../util.zig").sub.halfCarry;
const overflow = @import("../util.zig").sub.overflow;
const carry = @import("../util.zig").sub.carry;

const InstrFn = @import("../avr.zig").InstrFn;
const Cpu = @import("../avr.zig").Cpu;

const log = std.log.scoped(.avr_cpi);

pub fn handler(comptime k: u8) InstrFn {
    return struct {
        fn inner(cpu: *Cpu, opcode: u16) void {
            const ret = bstr.extract("0011----dddd----", opcode);
            const rd = @as(u5, 0x10) + ret.d;
            log.debug("cpi r{}, 0x{X:0>2}", .{ rd, k });

            const value = rd - k;

            cpu.sreg.carry = carry(cpu.r[rd], k, value);
            cpu.sreg.zero = value == 0x00;
            cpu.sreg.negative = value >> 7 == 0b1;
            cpu.sreg.overflow = overflow(cpu.r[rd], k, value);
            cpu.sreg.sign = cpu.sreg.negative != cpu.sreg.overflow;
            cpu.sreg.half_carry = halfCarry(cpu.r[rd], k, value);
        }
    }.inner;
}
