const std = @import("std");
const data = @embedFile("data/day13test.txt");

fn arrays_equal(a: []const []const u8, b: [][]const u8) bool {
    std.mem.reverse([]const u8, b);
    defer std.mem.reverse([]const u8, b);
    if (a.len != b.len) return false;
    for (a, b) |ai, bi| {
        if (!std.mem.eql(u8, ai, bi)) return false;
    }
    return true;
}

// Detect if any n..end range is symmetrical about (end - n)/2
// Or any 0..n range is symmetrical about n/2
fn horizontalSymmetry(allocator: std.mem.Allocator, grid: []const u8, optional: ?usize) !?usize {
    _ = optional;

    const line_count = std.mem.count(u8, grid, "\n");
    _ = line_count;
    var split = std.mem.splitScalar(u8, grid, '\n');
    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();
    while (split.next()) |line| {
        if (line.len == 0) break;
        try lines.append(line);
    }

    var max_pos: usize = 0;
    for (0..lines.items.len - 1) |n| {
        const pos = (lines.items.len - n) / 2 + n;
        if (arrays_equal(lines.items[n..pos], lines.items[pos..lines.items.len])) {
            std.log.info("N: {}, POS: {}, MAX: {}", .{ n, pos, lines.items.len });
            if (pos > max_pos) {
                // if (optional) |op| {
                //     if (op != pos) max_pos = pos;
                // } else {
                max_pos = pos;
                // }
            }
        }
    }
    var max_pos2: usize = 0;
    for (2..lines.items.len) |n| {
        const pos = n / 2;
        if (arrays_equal(lines.items[0..pos], lines.items[pos..n])) {
            std.log.info("N: {}, POS: {}, MAX: {}", .{ n, pos, lines.items.len });
            if (pos > max_pos2) {
                // if (optional) |op| {
                //     if (op != pos) max_pos2 = pos;
                // } else {
                max_pos2 = pos;
                // }
            }
        }
    }
    if (max_pos > max_pos2) return max_pos;
    if (max_pos2 > max_pos) return max_pos2;
    if (max_pos2 != 0) return max_pos2;

    return null;
}

fn verticalSymmetry(allocator: std.mem.Allocator, grid: []const u8, optional: ?usize) !?usize {
    const width = std.mem.indexOfScalar(u8, grid, '\n').? + 1;
    const new_width = std.mem.count(u8, grid, "\n") + 2;
    const new_grid = try allocator.alloc(u8, grid.len - new_width + width + 1);
    defer allocator.free(new_grid);

    for (0..width - 1) |x| {
        var row = try allocator.alloc(u8, new_width);
        defer allocator.free(row);
        row[new_width - 1] = '\n';
        for (0..new_width - 1) |i| {
            row[i] = grid[i * width + x];
        }
        std.mem.reverse(u8, row[0 .. new_width - 1]);
        @memcpy(new_grid[x * new_width .. (x + 1) * new_width], row);
    }

    return horizontalSymmetry(allocator, new_grid, optional);
}

const Line = struct {
    linen: usize,
    horizontal: bool,
};

fn reflection_lines(allocator: std.mem.Allocator) !std.AutoHashMap(usize, Line) {
    var grid_split = std.mem.splitSequence(u8, data, "\n\n");
    var counts = std.AutoHashMap(usize, Line).init(allocator);

    var number: usize = 0;
    while (grid_split.next()) |grid| : (number += 1) {
        if (try horizontalSymmetry(allocator, grid, null)) |hs| {
            try counts.put(number, Line{ .linen = hs, .horizontal = true });
        }
        if (try verticalSymmetry(allocator, grid, null)) |vs| {
            try counts.put(number, Line{ .linen = vs, .horizontal = false });
        }
    }

    return counts;
}

fn solution1(allocator: std.mem.Allocator) !usize {
    var grid_split = std.mem.splitSequence(u8, data, "\n\n");
    var count: usize = 0;

    while (grid_split.next()) |grid| {
        if (try horizontalSymmetry(allocator, grid, null)) |hs| {
            count += hs * 100;
        }
        if (try verticalSymmetry(allocator, grid, null)) |vs| {
            count += vs;
        }
    }

    return count;
}

fn solution2(allocator: std.mem.Allocator) !usize {
    var grid_split = std.mem.splitSequence(u8, data, "\n\n");
    var count: usize = 0;
    var lines = try reflection_lines(allocator);
    defer lines.deinit();

    var number: usize = 0;
    while (grid_split.next()) |grid| : (number += 1) {
        var mut_grid = try allocator.alloc(u8, grid.len);
        @memcpy(mut_grid, grid);
        defer allocator.free(mut_grid);
        var none = false;
        const line_map = lines.get(number) orelse blk: {
            none = true;
            break :blk Line{ .linen = 0, .horizontal = false };
        };

        for (0..grid.len) |i| {
            const past = mut_grid[i];
            defer mut_grid[i] = past;
            if (mut_grid[i] != '\n') {
                mut_grid[i] = (if (past == '#') '.' else '#');
            } else {
                continue;
            }
            // if (line_map.horizontal or none) {
            if (try horizontalSymmetry(allocator, mut_grid, if (none) null else line_map.linen)) |hs| {
                count += hs * 100;
                break;
            }
            // } else if (!line_map.horizontal or none) {
            if (try verticalSymmetry(allocator, mut_grid, if (none) null else line_map.linen)) |vs| {
                count += vs;
                break;
            }
            // }
        }
    }
    return count;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const sol1 = try solution1(allocator);
    const sol2 = try solution2(allocator);
    std.log.info("Solution 1: {}, Solution 2: {}", .{ sol1, sol2 });
}
