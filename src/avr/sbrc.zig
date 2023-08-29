// TODO: probably rename this file?

const std = @import("std");
const bstr = @import("bit-string");

const InstrFn = @import("../avr.zig").InstrFn;
const Cpu = @import("../avr.zig").Cpu;

const index = @import("../avr.zig").index;

const log = std.log.scoped(.avr_sbr);

pub fn handler(comptime s: u1, comptime b: u3) InstrFn {
    return struct {
        fn inner(cpu: *Cpu, opcode: u16) void {
            const rr = opcode >> 4 & 0x1F;
            log.debug("sbrc r{}, {}", .{ rr, b });

            const did_pass = cpu.r[rr] >> b & 1 == s;

            if (did_pass) {
                const prefetched = cpu.pipeline.stage orelse cpu.panic("sbrc {}, {} expected next opcode in pipeline but it was missing?", .{ rr, b });

                // note: as of this branch, only 1 cycle has been executed (instr fetch before/parallel to execution)
                if (isTwoWord(prefetched)) {
                    // + 0 | PC
                    // + 1 | Skip This Instr
                    // + 2 | Skip This Instr (pt 2)
                    // + 3 | Execute this Instr

                    // don't know the exact operation that happens here, but a read like this will take a cycle
                    _ = cpu.bus.read(u16, .prog, cpu.pc + 2);

                    cpu.pc += 3;
                    cpu.pipeline.flushed = true;
                } else {
                    //
                    // + 0 | PC
                    // + 1 | Skip This Instr
                    // + 2 | Execute this Instr

                    cpu.pc += 2;
                    cpu.pipeline.flushed = true; // this is + 1 cycle to make 2 cycles
                }
            }
        }
    }.inner;
}

// IIRC the only two-word instructions are JUMP/CALL and LDS/STS
fn isTwoWord(opcode: u16) bool {
    return bstr.match("1001010-----11--", opcode) or
        bstr.match("100100------0000", opcode);
}
