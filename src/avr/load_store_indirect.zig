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
        }
    }.inner;
}
