const std = @import("std");
const data = @embedFile("data/day6.txt");

fn solve(t: isize, d: isize) isize {
    const det = std.math.sqrt(@as(f64, @floatFromInt(t * t - 4 * d)));
    const s = @ceil((@as(f64, @floatFromInt(-t)) - det) / -2) - @floor((@as(f64, @floatFromInt(-t)) + det) / -2) - 1;
    return @intFromFloat(s);
}

pub fn main() !void {
    var lineSplit = std.mem.splitScalar(u8, data, '\n');
    const timeLine = lineSplit.next().?;
    const distanceLine = lineSplit.rest();
    var times: [4]isize = undefined;
    var distances: [4]isize = undefined;
    var timeSplit = std.mem.tokenizeScalar(u8, timeLine, ' ');
    _ = timeSplit.next();
    var distanceSplit = std.mem.tokenizeScalar(u8, distanceLine, ' ');
    _ = distanceSplit.next();
    var timeTotal: isize = 0;
    var distanceTotal: isize = 0;

    var i: usize = 0;
    while (i < 4) : (i += 1) {
        const timeT = try std.fmt.parseInt(isize, timeSplit.next().?, 10);
        times[i] = timeT;
        const distT = try std.fmt.parseInt(isize, distanceSplit.next().?, 10);
        distances[i] = distT;

        timeTotal = (timeTotal * 100) + timeT;
        distanceTotal = (distanceTotal * std.math.pow(isize, 10, 1 + std.math.log10_int(@as(usize, @intCast(distT))))) + distT;
    }

    var solution1: usize = 1;
    for (times, distances) |t, d| {
        solution1 *= @intCast(solve(t, d));
    }
    const solution2 = solve(timeTotal, distanceTotal);

    try std.io.getStdOut().writer().print("Solution 1: {}, Solution 2: {}\n", .{ solution1, solution2 });
}
