const std = @import("std");
const data = @embedFile("data/day2.txt");

const mem = std.mem;

const Game = struct {
    red: usize = 0,
    green: usize = 0,
    blue: usize = 0,
};

fn parseRow(row: []const u8) !Game {
    var splitRow = mem.splitBackwardsSequence(u8, row, ": ");
    var colors = splitRow.first();
    var pulls = mem.splitSequence(u8, colors, "; ");
    var game: Game = .{};
    while (pulls.next()) |pull| {
        var pullIterator = mem.splitSequence(u8, pull, ", ");
        while (pullIterator.next()) |color| {
            var colorSplit = mem.splitAny(u8, color, " ");
            var number = try std.fmt.parseInt(u32, colorSplit.next().?, 10);
            var col = colorSplit.next().?;
            if (std.mem.eql(u8, col, "red") and game.red < number) game.red = number;
            if (std.mem.eql(u8, col, "green") and game.green < number) game.green = number;
            if (std.mem.eql(u8, col, "blue") and game.blue < number) game.blue = number;
        }
    }

    return game;
}

pub fn main() !void {
    var solution1: usize = 0;
    var solution2: usize = 0;

    var splitter = mem.split(u8, data, "\n");
    var id: usize = 1;
    while (splitter.next()) |row| : (id += 1) {
        const game = try parseRow(row);
        if (game.red < 13 and game.green < 14 and game.blue < 15) solution1 += id;
        solution2 += (game.red * game.blue * game.green);
    }

    try std.io.getStdOut().writer().print("Solution 1: {}\n", .{solution1});
    try std.io.getStdOut().writer().print("Solution 2: {}\n", .{solution2});
}
