const std = @import("std");
const bstr = @import("bit-string");

const InstrFn = @import("../avr.zig").InstrFn;
const Cpu = @import("../avr.zig").Cpu;

const log = std.log.scoped(.avr_load_store);

pub fn handler(comptime s: bool, comptime op: u4) InstrFn {
    return struct {
        fn inner(cpu: *Cpu, opcode: u16) void {
            const ret = bstr.extract("100100-ddddd----", opcode);
            // TODO: care about RAMPD

            switch (op) {
                0b0000 => {
                    // FIXME: determine the exact behaviour here
                    const k = cpu.pipeline.stage orelse cpu.panic("prefetcher stopped working...", .{});
                    cpu.pc += 2;
                    cpu.pipeline.flushed = true;

                    if (s) {
                        // STS
                        const rr = ret.d;
                        log.debug("sts 0x{X:0>4}, r{}", .{ k, rr });

                        cpu.bus.write(u8, .data, k, cpu.r[rr]);
                    } else {
                        // LDS
                        const rd = ret.d;
                        log.debug("lds r{}, 0x{X:0>4}", .{ rd, k });

                        cpu.r[rd] = cpu.bus.read(u8, .data, k);
                    }
                },
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
