const std = @import("std");
const bstr = @import("bit-string");

const InstrFn = @import("../avr.zig").InstrFn;
const Cpu = @import("../avr.zig").Cpu;

const log = std.log.scoped(.avr_load_store);

pub fn handler(comptime s: bool, comptime op: u4) InstrFn {
    return struct {
        fn inner(cpu: *Cpu, opcode: u16) void {
            const ret = bstr.extract("100100-ddddd----", opcode);

            switch (op) {
                0b1111 => {
                    log.debug("{s} r{}", .{ if (s) "push" else "pop", ret.d });

                    if (s) {
                        // PUSH
                        const rr = ret.d;

                        cpu.bus.write(u8, .data, cpu.sp, cpu.r[rr]);
                        cpu.sp -= 1;
                    } else {
                        // POP
                        const rd = ret.d;

                        cpu.sp += 1;
                        cpu.r[rd] = cpu.bus.read(u8, .data, cpu.sp);
                    }
                },
                else => cpu.panic("op 0b{b:0>4} in opcode 0x{X:0>4} is unhandled", .{ op, opcode }),
            }
        }
    }.inner;
}
