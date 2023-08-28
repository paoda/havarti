const std = @import("std");
const bstr = @import("bit-string");

const InstrFn = @import("../avr.zig").InstrFn;
const Cpu = @import("../avr.zig").Cpu;

const log = std.log.scoped(.avr_status_clear_set);

// FIXME: A decent amount of runtime decoding going on here... (increase LUT from 10 to 12 bits?)
pub fn handler() InstrFn {
    return struct {
        fn inner(cpu: *Cpu, opcode: u16) void {
            const ret = bstr.extract("10010100cbbb1000", opcode);
            const byte: u8 = @bitCast(cpu.sreg);

            if (ret.c == 0b1) {
                log.debug("cl{s}", .{[_]u8{bitChar(ret.b)}});

                const mask = @as(u8, 1) << ret.b;
                cpu.sreg = @bitCast(byte & ~mask);
            } else {
                log.debug("se{s}", .{[_]u8{bitChar(ret.b)}});

                const mask = @as(u8, 1) << ret.b;
                cpu.sreg = @bitCast(byte | mask);
            }
        }
    }.inner;
}

fn bitChar(bit: u3) u8 {
    const str: [8]u8 = "cznvshti".*;
    return str[bit];
}
