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
