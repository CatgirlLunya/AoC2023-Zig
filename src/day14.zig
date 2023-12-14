const std = @import("std");
const data = @embedFile("data/day14.txt");

const width = std.mem.indexOf(u8, data, "\n").?;
const height = blk: {
    @setEvalBranchQuota(1000000);
    break :blk std.mem.count(u8, data, "\n") + 1;
};

pub fn north(mdata: *[height][width]u8) !void {
    for (0..height) |y| {
        for (0..width) |x| {
            if (mdata[y][x] != 'O' or y == 0) continue;
            var dy: usize = 1;
            while (dy < y + 1 and mdata[y - dy][x] == '.') : (dy += 1) {
                mdata[y - dy][x] = 'O';
                mdata[y - dy + 1][x] = '.';
            }
        }
    }
}

pub fn south(mdata: *[height][width]u8) !void {
    for (0..height) |y| {
        const ya = height - y - 1;
        for (0..width) |x| {
            if (mdata[ya][x] != 'O') continue;
            var dy: usize = 1;
            while (dy < y + 1 and mdata[ya + dy][x] == '.') : (dy += 1) {
                mdata[ya + dy][x] = 'O';
                mdata[ya + dy - 1][x] = '.';
            }
        }
    }
}

pub fn west(mdata: *[height][width]u8) !void {
    for (0..height) |y| {
        for (0..width) |x| {
            if (mdata[y][x] != 'O' or x == 0) continue;
            var dx: usize = 1;
            while (dx < x + 1 and mdata[y][x - dx] == '.') : (dx += 1) {
                mdata[y][x - dx] = 'O';
                mdata[y][x - dx + 1] = '.';
            }
        }
    }
}

pub fn east(mdata: *[height][width]u8) !void {
    for (0..height) |y| {
        for (0..width) |x| {
            const xa = width - x - 1;
            if (mdata[y][xa] != 'O') continue;
            var dx: usize = 1;
            while (dx < x + 1 and mdata[y][xa + dx] == '.') : (dx += 1) {
                mdata[y][xa + dx] = 'O';
                mdata[y][xa + dx - 1] = '.';
            }
        }
    }
}

const map_type = std.AutoArrayHashMap([height][width]u8, [height][width]u8);
var map: map_type = undefined;

pub fn cycle(mdata: *[height][width]u8) !void {
    try north(mdata);
    try west(mdata);
    try south(mdata);
    try east(mdata);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var mdata: [height][width]u8 = undefined;
    var split = std.mem.split(u8, data, "\n");
    var i: usize = 0;
    while (split.next()) |line| : (i += 1) {
        @memcpy(mdata[i][0..width], line);
    }

    map = map_type.init(allocator);
    defer map.deinit();

    var cycle_start: usize = 0;
    var cycle_end: usize = 0;
    const len = 1_000_000_000;
    for (0..len) |x| {
        if (map.get(mdata)) |odata| {
            cycle_start = map.getIndex(mdata).?;
            cycle_end = x;
            for (&mdata, odata) |*r, o| {
                for (r, o) |*c, oc| {
                    c.* = oc;
                }
            }
            break;
        } else {
            var dup: [height][width]u8 = undefined;
            for (&dup, mdata) |*r, o| {
                for (r, o) |*c, oc| {
                    c.* = oc;
                }
            }

            try cycle(&mdata);
            try map.put(dup, mdata);
        }
    }

    const cycle_length = (len - cycle_start - 1) % (cycle_end - cycle_start);
    var count: usize = 0;
    const ndata = map.values()[cycle_start + cycle_length];
    for (0..ndata.len) |y| {
        for (0..ndata[y].len) |x| {
            if (ndata[y][x] == 'O') count += ndata.len - y;
        }
    }

    try std.io.getStdOut().writer().print("Solution 2: {}\n", .{count});
}
