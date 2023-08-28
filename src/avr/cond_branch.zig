const std = @import("std");
const bstr = @import("bit-string");

const InstrFn = @import("../avr.zig").InstrFn;
const Cpu = @import("../avr.zig").Cpu;

const sext = @import("../util.zig").sext;
const log = std.log.scoped(.avr_cond_branch);

pub fn handler(comptime c: u1, comptime b: u3) InstrFn {
    return struct {
        fn inner(cpu: *Cpu, opcode: u16) void {
            const PcT = @TypeOf(cpu.pc);
            const ret = bstr.extract("11110-kkkkkkk---", opcode);
            const sreg: u8 = @bitCast(cpu.sreg);
            log.debug("{s} {}", .{ alias(c == 0b1, b), @sizeOf(u16) * @as(i7, @bitCast(ret.k)) });

            // when c == 0b0 we want the bit set
            // when c == 0b1 we want the bit cleared
            const did_pass = (sreg >> b & 1) ^ c == 0b1;

            if (did_pass) {
                cpu.pc +%= sext(PcT, u7, ret.k) +% 1;
                cpu.pipeline.flushed = true;
            }
        }
    }.inner;
}

fn alias(comptime c: bool, comptime b: u3) [4]u8 {
    return ("br" ++ switch (b) {
        0b000 => if (c) "sh" else "lo",
        0b001 => if (c) "ne" else "eq",
        0b010 => if (c) "pl" else "mi",
        0b011 => if (c) "vc" else "vs",
        0b100 => if (c) "ge" else "lt",
        0b101 => if (c) "hc" else "hs",
        0b110 => if (c) "tc" else "ts",
        0b111 => if (c) "id" else "ie",
    }).*;
}
