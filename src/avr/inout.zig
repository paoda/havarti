const std = @import("std");
const bstr = @import("bit-string");

const InstrFn = @import("../avr.zig").InstrFn;
const Cpu = @import("../avr.zig").Cpu;

const log = std.log.scoped(.avr_inout);

pub fn handler(comptime s: bool) InstrFn {
    return struct {
        fn inner(cpu: *Cpu, opcode: u16) void {
            const ret = bstr.extract("-----aadddddaaaa", opcode);
            const addr = ret.a;

            if (s) {
                // OUT
                const rr = ret.d;

                log.debug("out 0x{X:0>2}, r{}", .{ addr, rr });
                cpu.bus.write(u8, .io, addr, cpu.r[rr]);
            } else {
                // IN
                const rd = ret.d;

                log.debug("in r{}, 0x{X:0>2}", .{ rd, addr });
                cpu.r[rd] = cpu.bus.read(u8, .io, addr);
            }
        }
    }.inner;
}
