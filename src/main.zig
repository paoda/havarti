const std = @import("std");
const avr = @import("avr.zig");

const Allocator = std.mem.Allocator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);

    const allocator = gpa.allocator();

    var args_it = try std.process.argsWithAllocator(allocator);
    defer args_it.deinit();

    _ = args_it.next(); // exe name
    const bin_path = args_it.next() orelse return error.missing_cli_argument;

    var exe = try std.fs.cwd().openFile(bin_path, .{});
    defer exe.close();

    const text = try code(allocator, exe);
    defer allocator.free(text);

    var cpu = try avr.Cpu.init(allocator, text);
    defer cpu.deinit(allocator);

    for (0..100) |_| {
        cpu.step();
    }
}

// TODO: rename
fn code(allocator: Allocator, file: std.fs.File) ![]const u8 {
    var header = try std.elf.Header.read(file);
    std.debug.assert(header.shstrndx != std.elf.SHN_UNDEF);

    const string_table: []const u8 = blk: {
        var section_it = header.section_header_iterator(file);

        // Section Header STRing TABle
        for (0..header.shstrndx) |_|
            _ = try section_it.next();

        const shstrtab_header = try section_it.next() orelse return error.unexpected_shstrndx_value;
        const shstrtab = try allocator.alloc(u8, shstrtab_header.sh_size);

        try file.seekTo(shstrtab_header.sh_offset);
        _ = try file.reader().readNoEof(shstrtab);

        break :blk shstrtab;
    };
    defer allocator.free(string_table);

    const text: []const u8 = blk: {
        var section_it = header.section_header_iterator(file);

        const text_header = inner: {
            while (try section_it.next()) |section| {
                const str = std.mem.sliceTo(string_table[section.sh_name..], 0);

                if (std.mem.eql(u8, str, ".text"))
                    break :inner section;
            }

            return error.text_section_header_missing;
        };

        const buf = try allocator.alloc(u8, text_header.sh_size);
        try file.seekTo(text_header.sh_offset);
        _ = try file.reader().readNoEof(buf);

        break :blk buf;
    };

    return text;
}
