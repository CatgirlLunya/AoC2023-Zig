const std = @import("std");
const data = @embedFile("data/day4.txt");
const lines = blk: {
    @setEvalBranchQuota(100000);
    break :blk std.mem.count(u8, data, "\n");
} + 1;
// 10, 25 for real; 5, 8 for test
const winningnums = 10;
const cards = 25;

pub fn main() !void {
    var split = std.mem.splitAny(u8, data, "\n");
    var solution1: usize = 0;
    var winnings: [lines]usize = [_]usize{0} ** lines;
    var row: usize = 0;
    while (split.next()) |line| {
        var parser = std.fmt.Parser{ .buf = line };
        var numbers: [1 + winningnums + cards]usize = undefined;
        var num: usize = 0;
        while (num < 1 + winningnums + cards) {
            while (!std.ascii.isDigit(parser.char() orelse break)) {}
            parser.pos -= 1;
            numbers[num] = parser.number() orelse {
                std.log.err("Expected number at pos {} line {}, got null!", .{ parser.pos, num });
                return;
            };
            num += 1;
        }

        var score: usize = 1;
        for (numbers[winningnums + 1 ..]) |number| {
            for (numbers[1 .. winningnums + 1]) |win| {
                if (number == win) {
                    winnings[row] += 1;
                    score *= 2;
                    break;
                }
            }
        }
        score /= 2;
        solution1 += score;
        row += 1;
    }

    var solution2: usize = 0;
    var backed: [lines]usize = [_]usize{1} ** lines;
    for (0..lines) |i| {
        for (0..winnings[i]) |win| {
            backed[i + win + 1] += backed[i];
        }
        solution2 += backed[i];
    }

    try std.io.getStdOut().writer().print("Solution 1: {}, Solution 2: {}\n", .{ solution1, solution2 });
}
