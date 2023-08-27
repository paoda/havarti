const std = @import("std");
const bstr = @import("bit-string");

pub const InstrFn = *const fn (cpu: *Cpu, opcode: u16) void;
pub const Cpu = @import("Cpu.zig");

const multiply = @import("avr/multiply.zig").handler;
const rjmp = @import("avr/rjmp.zig").handler;
const jmp = @import("avr/jmp.zig").handler;
const eor = @import("avr/eor.zig").handler;
const inout = @import("avr/inout.zig").handler;
const ldi = @import("avr/ldi.zig").handler;
const no_operand = @import("avr/no_operand.zig").handler;

const log = std.log.scoped(.avr);

pub fn und(cpu: *Cpu, opcode: u16) void {
    const fmt_str =
        \\an undefined instruction was run!
        \\opcode: 0x{X:0>4}
        \\index: 0x{X:0>3} (0b{b:0>10})
    ;

    const opcode_index = index(opcode);
    cpu.panic(fmt_str, .{ opcode, opcode_index, opcode_index });
}

pub const lut = blk: {
    const table_len = std.math.maxInt(u10);

    var table: [table_len]InstrFn = undefined;
    for (&table, 0..) |*ptr, _i| {
        const i: u10 = @intCast(_i); // TODO: remove this when I resolve 64-bit `PEXT` issue in bit-string lib

        if (bstr.match("1001011000", i)) {
            ptr.* = no_operand();
            continue;
        }

        if (bstr.matchExtract("10010111ck", i)) |ret| {
            ptr.* = jmp(ret.c == 0b1, ret.k == 0b1);
            continue;
        }

        if (bstr.matchExtract("000000rrrr", i)) |ret| {
            ptr.* = multiply(ret.r);
            continue;
        }

        if (bstr.matchExtract("001001rrrr", i)) |ret| {
            ptr.* = eor(ret.r);
            continue;
        }

        if (bstr.match("1110kkkkkk", i)) {
            // only 2 bits from k are missing, don't think it's worth monomorphization :\
            ptr.* = ldi();
            continue;
        }

        if (bstr.matchExtract("1011s-----", i)) |ret| {
            ptr.* = inout(ret.s == 0b1);
            continue;
        }

        if (bstr.matchExtract("110c------", i)) |ret| {
            ptr.* = rjmp(ret.c == 0b1);
            continue;
        }

        ptr.* = und;
    }

    break :blk table;
};

pub inline fn index(opcode: u16) u12 {
    // could use pext here (just sayin')
    const lhs = opcode & 0b1111_1100_0000_0000;
    const rhs = opcode & 0b0000_0000_0000_1111;

    return @intCast(lhs >> 6 | rhs);
}
