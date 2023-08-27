const std = @import("std");
const bstr = @import("bit-string");

const InstrFn = @import("../avr.zig").InstrFn;
const Cpu = @import("../avr.zig").Cpu;

const log = std.log.scoped(.avr_no_operand);

// FIXME: A decent amount of runtime decoding going on here... (increase LUT from 10 to 12 bits?)
pub fn handler() InstrFn {
    return struct {
        fn inner(cpu: *Cpu, opcode: u16) void {
            const PcT = @TypeOf(cpu.pc);

            if (bstr.matchExtract("10010100cbbb1000", opcode)) |ret| {
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

                return;
            }

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

fn bitChar(bit: u3) u8 {
    return switch (bit) {
        0b000 => 'c',
        0b001 => 'z',
        0b010 => 'n',
        0b011 => 'v',
        0b100 => 's',
        0b101 => 'h',
        0b110 => 't',
        0b111 => 'i',
    };
}
