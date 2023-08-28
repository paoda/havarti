const std = @import("std");
const avr = @import("avr.zig");

const Bus = @import("Bus.zig");
const log = std.log.scoped(.cpu);

const Allocator = std.mem.Allocator;

const Word = u16;
const Cpu = @This();

// TODO: RAMPX, RAMPY, RAMPZ, RAMPD, and EIND
r: [32]u8 = [_]u8{0x00} ** 32,

/// AVR PC counts 16-bit words, not bytes
pc: u16 = 0x0000,
sp: u16 = 0x0000,
sreg: Status = @bitCast(@as(u8, 0x00)),

bus: Bus,

pipeline: Pipeline = .{},

pub fn init(allocator: Allocator, text: []const u8) !Cpu {
    return .{ .bus = try Bus.init(allocator, text) };
}

pub fn deinit(self: Cpu, allocator: Allocator) void {
    self.bus.deinit(allocator);
}

const Pair = union(enum) { x: void, y: void, z: void, r: u5 };

pub fn pair(self: *const Cpu, idx: Pair) u16 {
    const rr = switch (idx) {
        .x => 26,
        .y => 28,
        .z => 30,
        .r => |r| r,
    };
    std.debug.assert(rr & 1 == 0);

    // FIXME: Don't fully understand this. readIntLittle or readIntNative?
    return std.mem.readIntLittle(u16, self.r[rr..][0..@sizeOf(u16)]);
}

pub fn setPair(self: *Cpu, idx: Pair, value: u16) void {
    const rd = switch (idx) {
        .x => 26,
        .y => 28,
        .z => 30,
        .r => |r| r,
    };
    std.debug.assert(rd & 1 == 0);

    // FIXME: Don't fully understand this. readIntLittle or readIntNative?
    std.mem.writeIntLittle(u16, self.r[rd..][0..@sizeOf(u16)], value);
}

fn fetch(self: *Cpu) u16 {
    defer self.pc += 1;
    return self.bus.read(u16, .prog, self.pc * @sizeOf(Word));
}

pub fn step(self: *Cpu) void {
    if (self.pipeline.step(self)) |opcode| {
        // due to the 2-stage pipeline:
        // PC - 2: currently executing
        // PC - 1: will execute next cycle
        // PC + 0: will fetch next cycle
        //
        // However, from an instruction's point of view, PC + 0 == currently executing. The AVR ISA always makes this assumption, so
        // we need to ensure that it is true, at least temporarily.
        self.pc -= 2;
        defer {
            // The pipeline is flushed when PC has changed, so there's no reason to restore the above subtraction
            if (!self.pipeline.flushed) self.pc += 2;
        }

        avr.lut[avr.index(opcode)](self, opcode);
    }

    if (self.pipeline.flushed) {
        self.pipeline.stage = self.fetch();
        self.pipeline.flushed = false;
    }
}

pub fn panic(self: Cpu, comptime fmt: []const u8, args: anytype) noreturn {
    self.print();

    std.debug.print("\n", .{});
    std.debug.panic(fmt, args);
}

pub fn print(self: Cpu) void {
    const r = self.r;

    for (0..8) |i| {
        const ri = i * 4;
        log.err("r{: <2}: 0x{X:0>2}\tr{: <2}: 0x{X:0>2}\tr{: <2}: 0x{X:0>2}\tr{: <2}: 0x{X:0>2}", .{ ri, r[ri], ri + 1, r[ri + 1], ri + 2, r[ri + 2], ri + 3, r[ri + 3] });
    }
    log.err("pc: 0x{X:0>6}", .{self.pc * @sizeOf(u16)});
    log.err("sp: 0x{X:0>4}", .{self.sp});
    log.err("sreg: 0x{X:0>2} {s}", .{ @as(u8, @bitCast(self.sreg)), self.sreg.print() });

    if (self.pipeline.stage != null) log.err("next instr (in decoding stage): 0x{X:0>4}", .{self.pipeline.stage.?});
}

const Pipeline = struct {
    stage: ?u16 = null,
    flushed: bool = false,

    fn step(self: *@This(), cpu: *Cpu) ?u16 {
        const opcode = self.stage;
        self.stage = cpu.fetch();

        return opcode;
    }
};

const Status = packed struct(u8) {
    carry: bool,
    zero: bool,
    negative: bool,
    overflow: bool,
    sign: bool,
    half_carry: bool,
    bit_copy: bool,
    interrupt: bool,

    fn print(self: @This()) [10]u8 {
        var str: [10]u8 = "[--------]".*;

        if (self.interrupt) str[1] = 'I';
        if (self.bit_copy) str[2] = 'T';
        if (self.half_carry) str[3] = 'H';
        if (self.sign) str[4] = 'S';
        if (self.overflow) str[5] = 'V';
        if (self.negative) str[6] = 'N';
        if (self.zero) str[7] = 'Z';
        if (self.carry) str[8] = 'C';

        return str;
    }
};
