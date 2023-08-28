const std = @import("std");
const bstr = @import("bit-string");

const InstrFn = @import("../avr.zig").InstrFn;
const Cpu = @import("../avr.zig").Cpu;

const log = std.log.scoped(.avr_jmp);

pub fn handler(comptime c: bool) InstrFn {
    return struct {
        fn inner(cpu: *Cpu, opcode: u16) void {
            const PcT = @TypeOf(cpu.pc);

            const ret = bstr.extract("-------kkkkk---k", opcode);
            const k = cpu.bus.read(u16, .prog, @sizeOf(u16) * (cpu.pc + 1));
            cpu.pc += 1; // this is immediately overwritten, but good practice anyways

            const offset = @typeInfo(PcT).Int.bits - @typeInfo(@TypeOf(ret.k)).Int.bits;
            const address = (@as(PcT, ret.k) << @intCast(offset)) | @as(PcT, @intCast(k));
            log.debug("{s} 0x{X:0>6}", .{ if (c) "call" else "jmp", address * @sizeOf(u16) });

            if (c) {
                const ret_addr = cpu.pc + 1;

                cpu.bus.write(PcT, .data, cpu.sp, ret_addr);
                cpu.sp -= @sizeOf(PcT);
            }

            cpu.pc = address;

            cpu.pipeline.flushed = true; // guaranteed branch here
        }
    }.inner;
}
