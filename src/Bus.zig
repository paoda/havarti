const std = @import("std");
const Cpu = @import("Cpu.zig");

const Allocator = std.mem.Allocator;
const log = std.log.scoped(.bus);

const Space = enum { prog, data, io };
const Bus = @This();

const prog_size = 32 * KiB;
const data_size = 2 * KiB;
const KiB = 0x400;

prog: *const [prog_size]u8,
data: *[data_size]u8,

// TODO: Maybe rename text? (see call sites as well)
pub fn init(allocator: Allocator, text: []const u8) !Bus {
    const prog_buf = try allocator.create([prog_size]u8);
    @memcpy(prog_buf[0..text.len], text);

    const data_buf = try allocator.create([data_size]u8);

    return .{
        .prog = prog_buf,
        .data = data_buf,
    };
}

pub fn deinit(self: Bus, allocator: Allocator) void {
    allocator.free(self.prog);
    allocator.free(self.data);
}

pub fn read(self: *Bus, comptime T: type, comptime space: Space, address: u22) T {
    const readInt = std.mem.readIntLittle;
    const byte_count = @divExact(@typeInfo(T).Int.bits, 8);
    const cpu = @fieldParentPtr(Cpu, "bus", self);

    return switch (space) {
        .prog => switch (address) {
            0x0000...(prog_size - 1) => readInt(T, self.prog[address..][0..byte_count]),
            else => std.debug.panic("0x{X:0>6} exceeds the program bus address space", .{address}),
        },
        .data => switch (address) {
            0x0000...0x001F => cpu.r[address],
            0x0020...0x005F => io.read(self, @intCast(address - 0x20)),
            0x0060...0x00FF => @panic("TODO: 160 Ext I/O Registers"),
            0x0100...(0x0100 + data_size - 1) => readInt(T, self.data[address - 0x100 ..][0..byte_count]),
            else => cpu.panic("0x{X:0>6} exceeds the data bus address space", .{address}),
        },
        .io => io.read(self, @intCast(address)),
    };
}

pub fn write(self: *Bus, comptime T: type, comptime space: Space, address: u22, value: T) void {
    const writeInt = std.mem.writeIntLittle;
    const byte_count = @divExact(@typeInfo(T).Int.bits, 8);
    const cpu = @fieldParentPtr(Cpu, "bus", self);

    switch (space) {
        .data => switch (address) {
            0x0000...0x001F => cpu.r[address] = @intCast(value),
            0x0020...0x005F => io.write(self, @intCast(address - 0x20), @intCast(value)),
            0x0060...0x00FF => @panic("TODO: 160 Ext I/O Registers"),
            0x0100...(0x0100 + data_size - 1) => writeInt(T, self.data[address - 0x100 ..][0..byte_count], value),
            else => cpu.panic("tried to write 0x{X:} to 0x{X:0>6}", .{ value, address }),
        },
        .io => io.write(self, @intCast(address), value),
        .prog => unreachable, // Program Memory is Read-Only
    }
}

const io = struct {
    pub fn read(bus: *Bus, address: u8) u8 {
        const cpu = @fieldParentPtr(Cpu, "bus", bus);

        return switch (address) {
            0x3F => @bitCast(cpu.sreg),
            0x3E => @intCast(cpu.sp >> 8),
            0x3D => @intCast(cpu.sp & 0xFF),
            else => blk: {
                log.err("(I/O) Tried to read from 0x{X:0>2}", .{address});
                break :blk 0xFF;
            },
        };
    }

    pub fn write(bus: *Bus, address: u8, value: u8) void {
        const cpu = @fieldParentPtr(Cpu, "bus", bus);

        switch (address) {
            0x3F => cpu.sreg = @bitCast(value),
            0x3E => cpu.sp = (cpu.sp & 0x00FF) | @as(u16, value) << 8,
            0x3D => cpu.sp = (cpu.sp & 0xFF00) | value,
            else => log.err("(I/O) Tried to write 0x{X:0>2} to 0x{X:0>2}", .{ value, address }),
        }
    }
};
