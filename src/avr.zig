const std = @import("std");
const bstr = @import("bit-string");

pub const InstrFn = *const fn (cpu: *Cpu, opcode: u16) void;
pub const Cpu = @import("Cpu.zig");

const nop = @import("avr/nop.zig").handler;
const status_clear_set = @import("avr/status_clear_set.zig").handler;
const multiply = @import("avr/multiply.zig").handler;
const rjmp = @import("avr/rjmp.zig").handler;
const jmp = @import("avr/jmp.zig").handler;
const alu = @import("avr/alu.zig").handler;
const inout = @import("avr/inout.zig").handler;
const ldi = @import("avr/ldi.zig").handler;
const zero_operand = @import("avr/zero_operand.zig").handler;
const load_store = @import("avr/load_store.zig").handler;
const load_store_indirect = @import("avr/load_store_indirect.zig").handler;
const add_sub_imm_word = @import("avr/add_sub_imm_word.zig").handler;
const cond_branch = @import("avr/cond_branch.zig").handler;

const log = std.log.scoped(.avr);

pub fn und(cpu: *Cpu, opcode: u16) void {
    const fmt_str =
        \\an undefined instruction was run!
        \\opcode: 0x{X:0>4}
        \\index: 0x{X:0>3} (0b{b:0>12})
    ;

    const opcode_index = index(opcode);
    cpu.panic(fmt_str, .{ opcode, opcode_index, opcode_index });
}

pub const lut = blk: {
    var table: [std.math.maxInt(u12)]InstrFn = undefined;

    for (&table, 0..) |*ptr, idx| {
        const i: u12 = @intCast(idx);

        // 12 constant bits

        if (i == 0b000000000000) {
            ptr.* = nop();
            continue;
        }

        if (i == 0b100101011000) {
            ptr.* = zero_operand();
            continue;
        }

        if (i == 0b100101001000) {
            ptr.* = status_clear_set();
            continue;
        }

        // 9 constant bits

        if (bstr.matchExtract("1001010-11c-", i)) |ret| {
            // can extract 2 bits of k at comptime, choose not to
            ptr.* = jmp(ret.c == 0b1);
            continue;
        }

        // 8 constant bits

        if (bstr.matchExtract("1001011s----", i)) |ret| {
            ptr.* = add_sub_imm_word(ret.s == 0b1);
            continue;
        }

        // 6 constant bits

        if (bstr.matchExtract("000000oorrrr", i)) |ret| {
            ptr.* = multiply(ret.o, ret.r);
            continue;
        }

        if (bstr.matchExtract("100100s-oooo", i)) |ret| {
            ptr.* = load_store(ret.s == 0b1, ret.o);
            continue;
        }

        // 5 constant bits

        if (bstr.matchExtract("11110c---bbb", i)) |ret| {
            ptr.* = cond_branch(ret.c, ret.b);
            continue;
        }

        // 4 constant bits

        if (bstr.matchExtract("1110kkkkkkkk", i)) |ret| {
            ptr.* = ldi(ret.k);
            continue;
        }

        if (bstr.matchExtract("1011saa-aaaa", i)) |ret| {
            ptr.* = inout(ret.s == 0b1, ret.a);
            continue;
        }

        // 3 constant bits

        if (bstr.matchExtract("10k0kks-ykkk", i)) |ret| {
            ptr.* = load_store_indirect(ret.s == 0b1, ret.y == 0b1, ret.k);
            continue;
        }

        if (bstr.matchExtract("110c--------", i)) |ret| {
            ptr.* = rjmp(ret.c == 0b1);
            continue;
        }

        // 2 constant bits

        if (bstr.matchExtract("00oooor-rrrr", i)) |ret| {
            ptr.* = alu(ret.o, ret.r);
            continue;
        }

        ptr.* = und;
    }

    break :blk table;
};

pub inline fn index(opcode: u16) u12 {
    // could use pext here (just sayin')
    const lhs = opcode & 0b1111_1111_0000_0000;
    const rhs = opcode & 0b0000_0000_0000_1111;

    return @intCast(lhs >> 4 | rhs);
}
