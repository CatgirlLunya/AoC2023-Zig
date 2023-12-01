const std = @import("std");
const data = @embedFile("data/day1.txt");

pub fn main() !void {
    var split = std.mem.split(u8, data, "\n");
    var sum: usize = 0;
    while (split.next()) |line| {
        var first: i8 = -1;
        var last: i8 = -1;

        for (0..line.len) |i| {
            var digit = line[i] - '0';
            if (line.len - i > 3 and std.mem.eql(u8, line[i .. i + 4], "zero")) digit = 0;
            if (line.len - i > 2 and std.mem.eql(u8, line[i .. i + 3], "one")) digit = 1;
            if (line.len - i > 2 and std.mem.eql(u8, line[i .. i + 3], "two")) digit = 2;
            if (line.len - i > 4 and std.mem.eql(u8, line[i .. i + 5], "three")) digit = 3;
            if (line.len - i > 3 and std.mem.eql(u8, line[i .. i + 4], "four")) digit = 4;
            if (line.len - i > 3 and std.mem.eql(u8, line[i .. i + 4], "five")) digit = 5;
            if (line.len - i > 2 and std.mem.eql(u8, line[i .. i + 3], "six")) digit = 6;
            if (line.len - i > 4 and std.mem.eql(u8, line[i .. i + 5], "seven")) digit = 7;
            if (line.len - i > 4 and std.mem.eql(u8, line[i .. i + 5], "eight")) digit = 8;
            if (line.len - i > 3 and std.mem.eql(u8, line[i .. i + 4], "nine")) digit = 9;
            if (digit <= 9 and digit >= 0) {
                if (first == -1) first = @intCast(digit);
                last = @intCast(digit);
            }
        }

        sum += @intCast(first * 10 + last);
    }

    try std.io.getStdOut().writer().print("Solution: {}", .{sum});
}
