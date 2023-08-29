const std = @import("std");

const InstrFn = @import("../avr.zig").InstrFn;
const Cpu = @import("../avr.zig").Cpu;

const halfCarry = @import("../util.zig").sub.halfCarry;
const overflow = @import("../util.zig").sub.overflow;
const carry = @import("../util.zig").sub.carry;

const log = std.log.scoped(.avr_alu);

pub fn handler(comptime op: u4, comptime rr: u5) InstrFn {
    return struct {
        fn inner(cpu: *Cpu, opcode: u16) void {
            const rd = opcode >> 4 & 0x1F;

            switch (op) {
                0b0001, 0b0101 => {
                    const cy = op >> 2 & 1 != 1;
                    log.debug("cp{s} r{}, r{}", .{ if (cy) "c" else "", rd, rr });

                    const value = cpu.r[rd] - cpu.r[rr] - if (cy) @intFromBool(cpu.sreg.carry) else 0;

                    cpu.sreg.carry = carry(cpu.r[rd], cpu.r[rr], value);
                    cpu.sreg.zero = value == 0x00;
                    cpu.sreg.negative = value >> 7 == 0b1;
                    cpu.sreg.overflow = overflow(cpu.r[rd], cpu.r[rr], value);
                    cpu.sreg.sign = cpu.sreg.negative != cpu.sreg.overflow;
                    cpu.sreg.half_carry = halfCarry(cpu.r[rd], cpu.r[rr], value);
                },
                0b0010, 0b0110 => cpu.panic("TODO: implement SBC/SUB r{}, r{}", .{ rd, rr }),
                0b0011, 0b0111 => cpu.panic("TODO: implement add/adc/lsl/rol r{}, r{}", .{ rd, rr }),
                0b0100 => cpu.panic("TODO: implement cpse r{}, r{}", .{ rd, rr }),
                0b1000 => cpu.panic("TODO: implement and r{}, r{}", .{ rd, rr }),
                0b1001 => {
                    log.debug("eor r{}, r{}", .{ rd, rr });

                    const value = cpu.r[rd] ^ cpu.r[rr];
                    cpu.r[rd] = value;

                    cpu.sreg.zero = value == 0x00;
                    cpu.sreg.negative = value >> 7 == 0b1;
                    cpu.sreg.overflow = false;
                    cpu.sreg.sign = cpu.sreg.negative != cpu.sreg.overflow;
                },
                0b1010 => cpu.panic("TODO: implement or r{}, r{}", .{ rd, rr }),
                0b1011 => cpu.panic("TODO: implement mov r{}, r{}", .{ rd, rr }),
                else => cpu.panic("op 0b{b:0>4} in 0x{X:0>4} is undefined", .{ op, opcode }),
            }
        }
    }.inner;
}
