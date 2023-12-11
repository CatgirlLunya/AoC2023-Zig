const std = @import("std");
const data = @embedFile("data/day10.txt");
const width = std.mem.indexOfScalar(u8, data, '\n').?;
const height = blk: {
    @setEvalBranchQuota(data.len + 1000);
    break :blk std.mem.count(u8, data, "\n") + 1;
};

const Orientation = enum(u8) { vertical = '|', horizontal = '-', northeast = 'L', northwest = 'J', southeast = 'F', southwest = '7', s = 'S', none = '.' };

const Point = struct {
    x: usize,
    y: usize,

    pub fn hash(self: Point) usize {
        return (self.x << 32) + self.y;
    }

    pub fn inList(self: Point, list: []Point) bool {
        for (list) |l| {
            if (l.x == self.x and l.y == self.y) return true;
        }
        return false;
    }
};

fn getList(allocator: std.mem.Allocator) !std.ArrayList(Point) {
    const spos = std.mem.indexOfScalar(u8, data, 'S').?;
    const start = Point{
        .x = @mod(spos, width + 1),
        .y = @divFloor(spos, width),
    };
    var list = std.ArrayList(Point).init(allocator);

    var current_position = start;
    while (!current_position.inList(list.items)) {
        try list.append(current_position);
        const char = data[current_position.y * (width + 1) + current_position.x];

        const previous_position: ?Point = if (list.items.len > 1) list.items[list.items.len - 2] else null;
        switch (char) {
            '|' => {
                if (previous_position.?.y > current_position.y) {
                    current_position.y -= 1;
                } else {
                    current_position.y += 1;
                }
            },
            '-' => {
                if (previous_position.?.x > current_position.x) {
                    current_position.x -= 1;
                } else {
                    current_position.x += 1;
                }
            },
            'L' => { // If previous above, then move right
                if (previous_position.?.y < current_position.y) {
                    current_position.x += 1;
                } else {
                    current_position.y -= 1;
                }
            },
            'J' => { // If previous above, then move left
                if (previous_position.?.y < current_position.y) {
                    current_position.x -= 1;
                } else {
                    current_position.y -= 1;
                }
            },
            'F' => { // If previous below, then move right
                if (previous_position.?.y > current_position.y) {
                    current_position.x += 1;
                } else {
                    current_position.y += 1;
                }
            },
            '7' => { // If previous was below, move left
                if (previous_position.?.y > current_position.y) {
                    current_position.x -= 1;
                } else {
                    current_position.y += 1;
                }
            },
            'S' => {
                current_position.y += 1;
            },
            else => @panic("Invalid"),
        }
    }

    return list;
}

// Taken and adapted from https://github.com/ryleelyman/advent_of_code_2023/blob/main/src/20.zig, kindof makes sense to me though
fn countInsideRow(y: usize, row: []const u8, loop: []Point) usize {
    var count: usize = 0;
    var inside = false;
    var last: u8 = 0;
    for (row, 0..) |char, x| {
        const point = Point{ .x = x, .y = y };
        if (!point.inList(loop)) {
            if (inside) count += 1;
        } else {
            if (char == '|') inside = !inside;
            if (char == 'L' or char == 'F') last = char;
            if (char == '7' and last == 'L') inside = !inside;
            if (char == 'J' and last == 'F') inside = !inside;
            if (char == '7' or char == 'J') last = 0;
        }
    }
    return count;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const list = try getList(allocator);
    defer list.deinit();

    std.log.info("Solution 1: {}", .{list.items.len / 2});

    var dataclone = try allocator.alloc(u8, height * (width + 1));
    for (0..width + 1) |x| {
        for (0..height) |y| {
            const point = Point{ .x = x, .y = y };
            dataclone[y * (width + 1) + x] = if (point.inList(list.items) or data[y * (width + 1) + x] == '\n') data[y * (width + 1) + x] else '.';
        }
    }
    const spos = std.mem.indexOfScalar(u8, data, 'S').?;
    dataclone[spos] = '|';
    defer allocator.free(dataclone);

    var rows = std.mem.splitScalar(u8, dataclone, '\n');
    var count: usize = 0;
    var r: usize = 0;
    while (rows.next()) |row| : (r += 1) {
        count += countInsideRow(r, row, list.items);
    }

    std.log.info("Data: {s}", .{dataclone});
    std.log.info("Solution 2: {any}", .{count});
}
