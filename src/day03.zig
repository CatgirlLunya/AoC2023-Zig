const std = @import("std");
const mem = std.mem;

fn getXY(x: usize, y: usize, lineSize: usize) usize {
    return x + y * (lineSize + 1);
}

fn solution1(data: []const u8) usize {
    const lineSize = std.mem.indexOf(u8, data, "\n").?;
    const lines = std.mem.count(u8, data, "\n") + 1;

    var solution: usize = 0;

    for (0..lines) |y| {
        var x: usize = 0;
        while (x < lineSize) : (x += 1) {
            var parser = std.fmt.Parser{ .buf = data[getXY(x, y, lineSize)..] };
            const number = parser.number() orelse continue;
            const numberSize = std.math.log10_int(number) + 1;
            defer x += numberSize - 1; // Advance to end of number, while loop will add 1 more

            const preStart = if (x == 0) x else x - 1;
            const postStart = if (x + numberSize == lineSize) x + numberSize else x + numberSize + 1;
            const preLine = if (y == 0) y else y - 1;
            const postLine = if (y + 1 == lines) y else y + 1;
            for (preLine..postLine + 1) |checky| {
                for (preStart..postStart) |checkx| {
                    switch (data[getXY(checkx, checky, lineSize)]) {
                        '0'...'9', '.' => {},
                        else => {
                            solution += number;
                        },
                    }
                }
            }
        }
    }

    return solution;
}

fn solution2(data: []const u8) !usize {
    const Point = struct {
        x: usize,
        y: usize,
    };
    const Value = struct {
        val: usize = 1,
        amount: usize = 0,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var map = std.AutoHashMap(Point, Value).init(gpa.allocator());

    const lineSize = std.mem.indexOf(u8, data, "\n").?;
    const lines = std.mem.count(u8, data, "\n") + 1;
    for (0..lines) |y| {
        var x: usize = 0;
        while (x < lineSize) : (x += 1) {
            var parser = std.fmt.Parser{ .buf = data[getXY(x, y, lineSize)..] };
            const number = parser.number() orelse continue;
            const numberSize = std.math.log10_int(number) + 1;
            defer x += numberSize - 1; // Advance to end of number, while loop will add 1 more

            const preStart = if (x == 0) x else x - 1;
            const postStart = if (x + numberSize == lineSize) x + numberSize else x + numberSize + 1;
            const preLine = if (y == 0) y else y - 1;
            const postLine = if (y + 1 == lines) y else y + 1;
            for (preLine..postLine + 1) |checky| {
                for (preStart..postStart) |checkx| {
                    if (data[getXY(checkx, checky, lineSize)] == '*') {
                        const point = Point{
                            .x = checkx,
                            .y = checky,
                        };
                        if (map.get(point) == null) {
                            try map.put(point, .{});
                        }
                        var ptr = map.getPtr(point).?;
                        ptr.val *= number;
                        ptr.amount += 1;
                    }
                }
            }
        }
    }

    var solution: usize = 0;
    var iterator = map.valueIterator();
    while (iterator.next()) |entry| {
        if (entry.amount >= 2) {
            solution += entry.val;
        }
    }

    map.deinit();
    if (gpa.deinit() != .ok) {
        return error.Leaked;
    }

    return solution;
}

pub fn main() !void {
    const data = @embedFile("data/day3.txt");

    // Can't be comptime because I don't want to use setEvalBranchQuota
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part 1: {}, Part 2: {}\n", .{ solution1(data), try solution2(data) });
}

test {
    const testData =
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
    ;
    const testSolution1 = solution1(testData);
    const testSolution2 = try solution2(testData);
    std.testing.expect(testSolution1 == 4361) catch {
        std.log.err("Failed part 1 with result {}", .{testSolution1});
    };

    std.testing.expect(testSolution2 == 467835) catch {
        std.log.err("Failed part 2 with result {}", .{testSolution2});
    };
}
