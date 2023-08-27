const std = @import("std");

const InstrFn = @import("../avr.zig").InstrFn;
const Cpu = @import("../avr.zig").Cpu;

const log = std.log.scoped(.avr_multiply);

pub fn handler(comptime rr: u4) InstrFn {
    return struct {
        fn inner(cpu: *Cpu, opcode: u16) void {
            _ = cpu;
            const op = opcode >> 7 & 0b111;

            switch (op) {
                0b000 => {
                    // NOP
                    log.debug("nop", .{});
                },
                0b110 => switch (@as(u1, @intCast(rr >> 3))) {
                    0b0 => {
                        // MULSU Rd, Rr
                        const rd = opcode >> 4 & 0x7;
                        log.debug("mulsu r{}, r{}", .{ rd, rr & 0x7 });
                    },
                    0b1 => {
                        // FMUL Rd, Rr
                        const rd = opcode >> 4 & 0x7;
                        log.debug("fmul r{}, r{}", .{ rd, rr & 0x7 });
                    },
                },
                0b111 => {
                    // FMULS(U) Rd, Rr
                    const U = rr >> 3 == 1;
                    const rd = opcode >> 4 & 0x7;

                    if (U) {
                        log.debug("fmulsu r{}, r{}", .{ rd, rr & 0x7 });
                    } else {
                        log.debug("fmuls r{}, r{}", .{ rd, rr & 0x7 });
                    }
                },
                else => switch (@as(u1, @intCast(opcode >> 8))) {
                    0b0 => {
                        // MULS Rd, Rr
                        const rd = opcode >> 4 & 0xF;
                        log.debug("muls r{}, r{}", .{ rd, rr });
                    },
                    0b1 => {
                        // MOVW Rd, Rr
                        const rd = opcode >> 4 & 0xF;
                        log.debug("movw r{}, r{}", .{ rd, rr });

                        // cpu.r[rd + 1] = cpu.r[rr + 1];
                        // cpu.r[rr + 0] = cpu.r[rr + 0];
                    },
                },
            }
        }
    }.inner;
}
