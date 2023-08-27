const std = @import("std");

const InstrFn = @import("../avr.zig").InstrFn;
const Cpu = @import("../avr.zig").Cpu;

const sext = @import("../util.zig").sext;
const log = std.log.scoped(.avr_rjmp);

pub fn handler(comptime c: bool) InstrFn {
    return struct {
        fn inner(cpu: *Cpu, opcode: u16) void {
            const PcT = @TypeOf(cpu.pc);

            const k: u12 = @intCast(opcode & 0x0FFF);
            log.debug("r{s} {}", .{ if (c) "call" else "jmp", @sizeOf(u16) * @as(i12, @bitCast(k)) });

            if (c) {
                const ret_addr = cpu.pc + 1;

                cpu.bus.write(PcT, .data, cpu.sp, ret_addr);
                cpu.sp -= @sizeOf(PcT);
            }

            cpu.pc +%= sext(PcT, u12, k) +% 1;

            cpu.pipeline.flushed = true; // guaranteed branch here
        }
    }.inner;
}
