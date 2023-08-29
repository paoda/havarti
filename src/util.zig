const std = @import("std");

const Log2Int = std.math.Log2Int;

// Sign-Extend value of type `T` to type `U`
pub fn sext(comptime T: type, comptime U: type, value: T) T {
    // U must have less bits than T
    comptime std.debug.assert(@typeInfo(U).Int.bits <= @typeInfo(T).Int.bits);

    const iT = std.meta.Int(.signed, @typeInfo(T).Int.bits);
    const ExtU = if (@typeInfo(U).Int.signedness == .unsigned) T else iT;
    const shift_amt: Log2Int(T) = @intCast(@typeInfo(T).Int.bits - @typeInfo(U).Int.bits);

    return @bitCast(@as(iT, @bitCast(@as(ExtU, @as(U, @truncate(value))) << shift_amt)) >> shift_amt);
}

pub const sub = struct {
    pub fn halfCarry(left: u8, right: u8, result: u8) bool {

        // zig fmt: off
        return (~(left >> 3 & 1) & (right >> 3 & 1)
            | (right >> 3 & 1) & (result >> 3 & 1)
            | (result >> 3 & 1) & ~(left >> 3 & 1)) == 0b1;
        // zig fmt: on
    }

    pub fn carry(left: u8, right: u8, result: u8) bool {

        // zig fmt: off
        return (~(left >> 7) & (right >> 7)
            | (right >> 7) & (result >> 7) 
            | (result >> 7) & ~(left >> 7)) == 0b1;
        // zig fmt: on
    }

    pub fn overflow(left: u8, right: u8, result: u8) bool {

        // zig fmt: off
            return (left >> 7 & ~(right >> 7) & ~(result >> 7)
                | ~(left >> 7) & right >> 7 & result >> 7) == 0b1;
        // zig fmt: on
    }
};
