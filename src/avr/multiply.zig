const std = @import("std");
const bstr = @import("bit-string");

const InstrFn = @import("../avr.zig").InstrFn;
const Cpu = @import("../avr.zig").Cpu;

const log = std.log.scoped(.avr_multiply);

pub fn handler(comptime op: u2, comptime rr: u4) InstrFn {
    return struct {
        fn inner(cpu: *Cpu, opcode: u16) void {
            const ret = bstr.extract("000000--dddd----", opcode);

            switch (op) {
                0b00 => cpu.panic("0x{X:0>4} is an invalid AVR instruction", .{opcode}),
                0b01 => cpu.panic("TODO: implement movw rd, rr", .{}),
                0b10 => cpu.panic("TODO: implement muls rd, rr", .{}),
                0b11 => {
                    const op2: u2 = @intCast((ret.d >> 3) << 1 | rr >> 3);
                    switch (op2) {
                        0b00 => cpu.panic("TODO: implement mulsu rd, rr", .{}),
                        0b01 => cpu.panic("TODO: implement fmul rd, rr", .{}),
                        0b10, 0b11 => cpu.panic("TODO: implement fmuls(u) rd, rr", .{}),
                    }
                },
            }
        }
    }.inner;
}
