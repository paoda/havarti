const std = @import("std");
const bstr = @import("bit-string");

const InstrFn = @import("../avr.zig").InstrFn;
const Cpu = @import("../avr.zig").Cpu;

const log = std.log.scoped(.avr_zero_operand);

pub fn handler() InstrFn {
    return struct {
        fn inner(cpu: *Cpu, opcode: u16) void {
            const PcT = @TypeOf(cpu.pc);

            const ret = bstr.extract("--------oooo----", opcode);
            const op = ret.o;

            switch (op) {
                0b0000 => {
                    log.debug("ret", .{});

                    cpu.sp += @sizeOf(PcT);
                    cpu.pc = cpu.bus.read(PcT, .data, cpu.sp);

                    cpu.pipeline.flushed = true;
                }, // RET
                0b0001 => cpu.panic("TODO: implement reti", .{}), // RETI
                0b1000 => cpu.panic("TODO: implement sleep", .{}), // SLEEP
                0b1001 => cpu.panic("TODO: implement break", .{}), // BREAK
                0b1010 => cpu.panic("TODO: implement wdr", .{}), // WDR
                0b1100, 0b1101 => cpu.panic("TODO: implement (e)lpm", .{}), // LPM, ELPM
                0b1110 => cpu.panic("TODO: implement spm", .{}),
                0b1111 => cpu.panic("TODO: implement spm Z+ (0x{X:0>4})", .{opcode}),
                else => cpu.panic("op 0b{b:0>4} is reserved in 0x{X:0>4}", .{ op, opcode }),
            }
        }
    }.inner;
}
