const std = @import("std");
const data = @embedFile("data/day9.txt");

fn arrayValid(arr: []isize) bool {
    for (arr) |num| {
        if (num != 0) return false;
    }
    return true;
}

fn extrapolate(allocator: std.mem.Allocator, line: []const u8) !@Vector(2, isize) {
    var array: [32]?[]isize = [_]?[]isize{null} ** 32;
    array[0] = try allocator.alloc(isize, 32);
    var split = std.mem.splitScalar(u8, line, ' ');
    var index: usize = 0;
    while (split.next()) |num| : (index += 1) {
        array[0].?[index] = try std.fmt.parseInt(isize, num, 10);
    }

    var length = index;
    const clength = length;
    index = 0;
    while (!arrayValid(array[index].?)) {
        array[index + 1] = try allocator.alloc(isize, length - 1);
        for (0..length - 1) |i| {
            array[index + 1].?[i] = array[index].?[i + 1] - array[index].?[i];
        }
        length -= 1;
        index += 1;
    }

    var extrapolated: isize = array[0].?[clength - 1];
    for (array[1..]) |arr| {
        if (arr) |a| {
            extrapolated += a[a.len - 1];
        }
    }
    var extrapolatedBack: isize = 0;
    for (0..index) |i| {
        const arr = array[index - i - 1].?;
        extrapolatedBack = arr[0] - extrapolatedBack;
    }

    for (array) |arr| {
        if (arr) |a| {
            allocator.free(a);
        }
    }

    return @Vector(2, isize){ extrapolated, extrapolatedBack };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var split = std.mem.splitScalar(u8, data, '\n');

    var sum: isize = 0;
    var sum2: isize = 0;
    while (split.next()) |line| {
        const value = extrapolate(gpa.allocator(), line) catch {
            std.log.err("INVALID LINE: {s}", .{line});
            break;
        };
        std.log.info("Line: {any}", .{value});
        sum += value[0];
        sum2 += value[1];
    }

    std.log.info("Sum: {}", .{sum});
    std.log.info("Sum 2: {}", .{sum2});
}

test {
    const value = try extrapolate(std.testing.allocator, "10 13 16 21 30 45");
    try std.testing.expect(value[0] == 68 and value[1] == 5);
    const value2 = try extrapolate(std.testing.allocator, "1 3 6 10 15 21");
    try std.testing.expect(value2[0] == 28 and value2[1] == 0);
}
