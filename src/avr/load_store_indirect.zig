const std = @import("std");
const bstr = @import("bit-string");

const InstrFn = @import("../avr.zig").InstrFn;
const Cpu = @import("../avr.zig").Cpu;

const log = std.log.scoped(.avr_load_store_indirect);

pub fn handler(comptime s: bool, comptime y: bool, comptime k: u6) InstrFn {
    return struct {
        fn inner(cpu: *Cpu, opcode: u16) void {
            // TODO: care about RAMPY / RAMPX
            const ret = bstr.extract("10-0---ddddd----", opcode);
            const pair = if (y) .y else .z;

            if (s) {
                // STD
                const rr = ret.d;
                log.debug("std {s}+{}, r{}", .{ [_]u8{@tagName(pair)[0] ^ 0x20}, k, rr });

                cpu.bus.write(u8, .data, cpu.pair(pair) + k, cpu.r[rr]);
            } else {
                // LDD
                const rd = ret.d;
                log.debug("ldd r{}, {s}+{}", .{ rd, [_]u8{@tagName(pair)[0] ^ 0x20}, k });

                cpu.r[rd] = cpu.bus.read(u8, .data, cpu.pair(pair) + k);
            }

            // FIXME: I wrote this code in the wrong handler. Try to salvage this?
            // if (y) {
            //     // ST
            //     const rr = ret.d;
            //     log.debug("st{s} {s}Y{s}{s}, r{}", .{
            //         if (ret.s == 0b0) "d" else "",
            //         if (ret.s == 0b1 and k & 0x3 == 0b10) "-" else "",
            //         if (ret.s == 0b0 or (ret.s == 0b1 and k & 0x3 == 0b01)) "+" else "",
            //         if (ret.s == 0b0) "q" else "",
            //         rr,
            //     });

            //     if (ret.s == 0b1) {
            //         if (k & 0x3 == 0b10) cpu.setPair(.y, cpu.pair(.y) - 1);

            //         cpu.bus.write(u8, .data, cpu.pair(.y), cpu.r[rr]);

            //         if (k & 0x3 == 0b01) cpu.setPair(.y, cpu.pair(.y) + 1);
            //     } else {
            //         cpu.bus.write(u8, .data, cpu.pair(.y) + k, cpu.r[rr]);
            //     }
            // } else {
            //     // LD
            //     const rd = ret.d;
            //     log.debug("ld{s} r{}, {s}Z{s}{s}", .{
            //         if (ret.s == 0b0) "d" else "",
            //         rd,
            //         if (ret.s == 0b1 and k & 0x3 == 0b10) "-" else "",
            //         if (ret.s == 0b0 or (ret.s == 0b1 and k & 0x3 == 0b01)) "+" else "",
            //         if (ret.s == 0b0) "q" else "",
            //     });

            //     if (ret.s == 0b1) {
            //         if (k & 0x3 == 0b10) cpu.setPair(.z, cpu.pair(.z) - 1);

            //         cpu.r[rd] = cpu.bus.read(u8, .data, cpu.pair(.z));

            //         if (k & 0x3 == 0b01) cpu.setPair(.z, cpu.pair(.z) + 1);
            //     } else {
            //         cpu.r[rd] = cpu.bus.read(u8, .data, cpu.pair(.z) + k);
            //     }
            // }
        }
    }.inner;
}
