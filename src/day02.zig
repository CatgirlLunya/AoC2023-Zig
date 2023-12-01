const std = @import("std");
const data = @embedFile("data/day2.txt");

const mem = std.mem;
const 

pub fn main() !void {
    var solution = 0;
    solution = 1;

    try std.io.getStdOut().writer().print("Solution: {}\n", .{solution});
}
