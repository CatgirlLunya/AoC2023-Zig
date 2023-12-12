const std = @import("std");
const data = @embedFile("data/day12test.txt");

fn factorial(n: usize) usize {
    if (n <= 1) return 1;
    return n * factorial(n - 1);
}

pub fn matches(line: []const u8, springs: []const usize) bool {
    var pos: usize = 0;
    var list: [25]usize = [_]usize{0} ** 25;
    var i: usize = 0;
    var count: usize = 0;
    while (pos < line.len) : (pos += 1) {
        if (line[pos] == '#') {
            count += 1;
        } else {
            if (count > 0) {
                list[i] = count;
                i += 1;
                count = 0;
            }
        }
    }
    if (count > 0) {
        list[i] = count;
        i += 1;
    }

    return std.mem.eql(usize, list[0..i], springs);
}

test matches {
    //const test_data =
    //    \\#.#.### 1,1,3
    //    \\.#...#....### 1,1,3
    //    \\.#.###.#.###### 1,3,1,6
    //    \\####.#...#... 4,1,1
    //    \\#....######..#####. 1,6,5
    //    \\.###.##....# 3,2,1
    //;
    //
    //var split = std.mem.splitScalar(u8, test_data, '\n');
    //while (split.next()) |line| {
    //    var ssplit = std.mem.splitScalar(u8, line, ' ');
    //    const exp = ssplit.next().?;
    //    const numbers = ssplit.next().?;
    //    var list = std.ArrayList(usize).init(std.testing.allocator);
    //    defer list.deinit();
    //    var numsplit = std.mem.splitScalar(u8, numbers, ',');
    //    while (numsplit.next()) |num| {
    //        try list.append(try std.fmt.parseInt(usize, num, 10));
    //    }
    //    try std.testing.expect(matches(exp, list.items));
    //}

    const line = "#.#..######..#####";
    const arr = [_]usize{ 1, 6, 5 };
    try std.testing.expect(!matches(line, &arr));
}

pub fn lt(_: void, a: usize, b: usize) bool {
    return a < b;
}

fn getbit(number: usize, index: u6) bool {
    return (number & (@as(usize, 1) << index)) > 0;
}

fn flipbit(number: usize, index: u6) usize {
    return (number ^ (@as(usize, 1) << index));
}

fn setbit(number: usize, index: u6, value: bool) usize {
    if (getbit(number, index) != value) {
        return flipbit(number, index);
    }
    return number;
}

fn gen_perms(allocator: std.mem.Allocator, arr: []const usize, choose: usize) !std.ArrayList([]usize) {
    var perms = std.ArrayList([]usize).init(allocator);
    var bin: usize = 0;
    const max_bits = arr.len;
    while (bin < std.math.pow(usize, 2, max_bits)) : (bin += 1) {
        const bit_count = blk: {
            var count: usize = 0;
            for (0..max_bits) |b| {
                if (getbit(bin, @intCast(b))) count += 1;
            }
            break :blk count;
        };
        if (bit_count == choose) {
            var list = try allocator.alloc(usize, choose);
            var lindex: usize = 0;
            for (0..max_bits) |b| {
                if (getbit(bin, @intCast(b))) {
                    list[lindex] = arr[b];
                    lindex += 1;
                }
            }
            try perms.append(list);
        }
    }

    return perms;
}

test gen_perms {
    const arr = [_]usize{ 1, 2, 3, 4 };
    const list = try gen_perms(std.testing.allocator, &arr, 2);
    std.log.warn("Perms: {any}", .{list.items});
    for (list.items) |l| {
        std.testing.allocator.free(l);
    }
    list.deinit();
}

pub fn solve(allocator: std.mem.Allocator, line: []const u8) !usize {
    var count: usize = 0;
    if (line.len == 0) return 0;
    var split = std.mem.splitScalar(u8, line, ' ');

    var expected = std.ArrayList(usize).init(allocator);
    defer expected.deinit();

    const spring_l = split.next().?;
    var springs = std.ArrayList(usize).init(allocator);
    defer springs.deinit();
    for (spring_l, 0..) |spring, i| {
        if (spring == '?') try springs.append(i);
    }

    const numbers = split.next().?;
    var number_split = std.mem.splitScalar(u8, numbers, ',');
    while (number_split.next()) |num| {
        try expected.append(try std.fmt.parseInt(usize, num, 10));
    }

    // Question positions and expected numbers given,
    for (0..springs.items.len) |spring_count| {
        var perms = try gen_perms(allocator, springs.items, spring_count + 1);
        defer {
            for (perms.items) |p| {
                allocator.free(p);
            }
            perms.deinit();
        }

        for (perms.items) |perm| {
            var cloned_line = try allocator.alloc(u8, line.len);
            defer allocator.free(cloned_line);
            @memcpy(cloned_line, line);
            for (perm) |i| {
                cloned_line[i] = '#';
            }
            if (matches(cloned_line, expected.items)) {
                count += 1;
            }
        }
    }
    if (matches(line, expected.items)) {
        count += 1;
    }
    return count;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var lines = std.mem.splitScalar(u8, data, '\n');
    var count: usize = 0;
    var count2: usize = 0;
    while (lines.next()) |line| {
        count += solve(allocator, line);
        var cloned_line = try allocator.alloc(u8, line.len * 5 + 4);
        defer allocator.free(cloned_line);
        var split = std.mem.splitScalar(u8, line, ' ');
        const spring_l = split.next().?;
        const numbers = split.next().?;
        var c: usize = 0;
        for (0..5) |i| {
            @memcpy(cloned_line[c .. c + spring_l.len], spring_l);
            c += spring_l.len;
            if (i != 4) {
                cloned_line[c] = '?';
                c += 1;
            }
        }
        cloned_line[c] = ' ';
        c += 1;
        for (0..5) |i| {
            @memcpy(cloned_line[c .. c + numbers.len], numbers);
            c += numbers.len;
            if (i != 4) cloned_line[c] = ',';
            c += 1;
        }

        try std.io.getStdOut().writer().print("New Line: {s}", .{cloned_line});
        count2 += try solve(allocator, cloned_line);
    }

    std.log.info("Solution 1: {}, Solution 2: {}", .{ count, count2 });
}
