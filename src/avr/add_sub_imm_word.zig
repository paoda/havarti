const std = @import("std");
const bstr = @import("bit-string");

const InstrFn = @import("../avr.zig").InstrFn;
const Cpu = @import("../avr.zig").Cpu;

const log = std.log.scoped(.avr_add_sub_imm_word);

pub fn handler(comptime s: bool) InstrFn {
    return struct {
        fn inner(cpu: *Cpu, opcode: u16) void {
            const ret = bstr.extract("1001011-kkppkkkk", opcode);
            const rp = 0x18 + @as(u5, ret.p) * 2;
            log.debug("{s}iw r{}, {}", .{ if (s) "sb" else "ad", rp, ret.k });

            const base = cpu.pair(.{ .r = rp });
            const value = if (s) base - ret.k else base + ret.k;

            cpu.sreg.carry = (~(value >> 15) & cpu.r[rp + 1] >> 7) == 0b1;
            if (s) cpu.sreg.carry = !cpu.sreg.carry;

            cpu.sreg.zero = value == 0x0000;
            cpu.sreg.negative = value >> 15 == 0b01;
            cpu.sreg.overflow = (value >> 15 & ~(cpu.r[rp + 1] >> 7)) == 0b1;
            cpu.sreg.sign = cpu.sreg.negative != cpu.sreg.overflow;

            cpu.setPair(.{ .r = rp }, value);
        }
    }.inner;
}
