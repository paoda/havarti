const std = @import("std");

const InstrFn = @import("../avr.zig").InstrFn;
const Cpu = @import("../avr.zig").Cpu;

const sext = @import("../util.zig").sext;
const log = std.log.scoped(.avr_rjmp);

pub fn handler(comptime c: bool) InstrFn {
    return struct {
        fn inner(cpu: *Cpu, opcode: u16) void {
            const PcT = @TypeOf(cpu.pc);
            if (c) cpu.panic("TODO: implement RCALL", .{});

            const k: u12 = @intCast(opcode & 0x0FFF);
            log.debug("rjmp {}", .{@sizeOf(u16) * @as(i12, @bitCast(k))});

            cpu.pc +%= sext(PcT, u12, k) +% 1;

            cpu.pipeline.flushed = true; // guaranteed branch here
        }
    }.inner;
}
