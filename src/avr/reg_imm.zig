const std = @import("std");
const bstr = @import("bit-string");

const InstrFn = @import("../avr.zig").InstrFn;
const Cpu = @import("../avr.zig").Cpu;

const halfCarry = @import("../util.zig").sub.halfCarry;
const overflow = @import("../util.zig").sub.overflow;
const carry = @import("../util.zig").sub.carry;

const log = std.log.scoped(.avr_reg_imm);

pub fn handler(comptime op: u2, comptime k: u8) InstrFn {
    return struct {
        fn inner(cpu: *Cpu, opcode: u16) void {
            const rd = 0x10 + opcode >> 4 & 0xF;

            switch (op) {
                0b00, 0b01 => {
                    const cy = op & 1 != 1;
                    log.debug("{s}i r{}, {}", .{ if (cy) "sbc" else "sub", rd, k });

                    const value = cpu.r[rd] -% k -% if (cy) @intFromBool(cpu.sreg.carry) else 0;

                    // should have the same flac calculations as cpi
                    cpu.sreg.carry = carry(cpu.r[rd], k, value);
                    cpu.sreg.zero = value == 0x00;
                    cpu.sreg.negative = value >> 7 == 0b1;
                    cpu.sreg.overflow = overflow(cpu.r[rd], k, value);
                    cpu.sreg.sign = cpu.sreg.negative != cpu.sreg.overflow;
                    cpu.sreg.half_carry = halfCarry(cpu.r[rd], k, value);

                    cpu.r[rd] = value;
                },
                0b10 => {
                    log.debug("ori r{}, {}", .{ rd, k });

                    const value = cpu.r[rd] | k;

                    cpu.sreg.zero = value == 0x00;
                    cpu.sreg.negative = value >> 7 == 0b1;
                    cpu.sreg.overflow = false;
                    cpu.sreg.sign = cpu.sreg.negative != cpu.sreg.overflow;

                    cpu.r[rd] = value;
                },
                0b11 => {
                    log.debug("andi r{}, {}", .{ rd, k });

                    const value = cpu.r[rd] & k;

                    cpu.sreg.zero = value == 0x00;
                    cpu.sreg.negative = value >> 7 == 0b1;
                    cpu.sreg.overflow = false;
                    cpu.sreg.sign = cpu.sreg.negative != cpu.sreg.overflow;

                    cpu.r[rd] = value;
                },
            }
        }
    }.inner;
}
