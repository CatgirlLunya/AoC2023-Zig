const std = @import("std");
const data = @embedFile("data/day16.txt");

const Point = struct {
    x: isize,
    y: isize,
};

const Direction = enum {
    up,
    down,
    left,
    right,
};

const Beam = struct {
    pos: Point,
    dir: Direction,

    pub fn move(self: *Beam) void {
        switch (self.dir) {
            .up => self.pos.y -= 1,
            .down => self.pos.y += 1,
            .left => self.pos.x -= 1,
            .right => self.pos.x += 1,
        }
    }
};

fn simulate(allocator: std.mem.Allocator, entry: Beam) !usize {
    const width = std.mem.indexOfScalar(u8, data, '\n').? + 1;
    const height = std.mem.count(u8, data, "\n");

    var visited = std.AutoHashMap(Point, void).init(allocator);
    defer visited.deinit();

    var visited_splitters = std.AutoHashMap(Point, void).init(allocator);
    defer visited_splitters.deinit();

    var beams = std.ArrayList(Beam).init(allocator);
    defer beams.deinit();
    try beams.append(entry);

    while (beams.items.len > 0) {
        var i: usize = 0;
        while (i < beams.items.len) {
            var beam = &beams.items[i];
            try visited.put(beam.pos, {});
            switch (data[@as(usize, @intCast(beam.pos.y)) * width + @as(usize, @intCast(beam.pos.x))]) {
                '.' => beam.move(),
                '-' => switch (beam.dir) {
                    .left, .right => beam.move(),
                    .up, .down => {
                        const oldi = i;
                        if (!visited_splitters.contains(beam.pos)) {
                            try visited_splitters.put(beam.pos, {});
                            if (beam.pos.x > 0) {
                                try beams.append(Beam{ .pos = .{ .x = beam.pos.x - 1, .y = beam.pos.y }, .dir = .left });
                                i += 1;
                            }
                            if (beam.pos.x + 2 < width) {
                                try beams.append(Beam{ .pos = .{ .x = beam.pos.x + 1, .y = beam.pos.y }, .dir = .right });
                                i += 1;
                            }
                        }
                        _ = beams.orderedRemove(oldi);
                        if (i > 0) i -= 1;
                        continue;
                    },
                },
                '|' => switch (beam.dir) {
                    .up, .down => beam.move(),
                    .left, .right => {
                        const oldi = i;
                        if (!visited_splitters.contains(beam.pos)) {
                            try visited_splitters.put(beam.pos, {});
                            if (beam.pos.y > 0) {
                                try beams.append(Beam{ .pos = .{ .x = beam.pos.x, .y = beam.pos.y - 1 }, .dir = .up });
                                i += 1;
                            }
                            if (beam.pos.y < height) {
                                try beams.append(Beam{ .pos = .{ .x = beam.pos.x, .y = beam.pos.y + 1 }, .dir = .down });
                                i += 1;
                            }
                        }
                        _ = beams.orderedRemove(oldi);
                        if (i > 0) i -= 1;
                        continue;
                    },
                },
                '/' => {
                    beam.dir = switch (beam.dir) {
                        .left => .down,
                        .right => .up,
                        .up => .right,
                        .down => .left,
                    };
                    beam.move();
                },
                '\\' => {
                    beam.dir = switch (beam.dir) {
                        .left => .up,
                        .right => .down,
                        .up => .left,
                        .down => .right,
                    };
                    beam.move();
                },
                else => {
                    std.log.err("Beam: {any}", .{beam.*});
                    std.log.err("Invalid Char: {}", .{data[@as(usize, @intCast(beam.pos.y)) * width + @as(usize, @intCast(beam.pos.x))]});
                    return error.Fail;
                },
            }
            if (beam.pos.x < 0 or beam.pos.x >= width - 1 or beam.pos.y < 0 or beam.pos.y > height) {
                _ = beams.orderedRemove(i);
            } else {
                i += 1;
            }
        }
    }
    return visited.count();
}

pub fn main() !void {
    const width = std.mem.indexOfScalar(u8, data, '\n').? + 1;
    const height = std.mem.count(u8, data, "\n");

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    std.log.info("Solution 1: {}", .{try simulate(allocator, .{ .dir = .right, .pos = .{ .x = 0, .y = 0 } })});

    var max: usize = 0;
    for (0..height) |h| {
        const val = try simulate(allocator, .{ .dir = .right, .pos = .{ .x = 0, .y = @intCast(h) } });
        max = if (max < val) val else max;
        const val2 = try simulate(allocator, .{ .dir = .left, .pos = .{ .x = @intCast(width - 2), .y = @intCast(h) } });
        max = if (max < val2) val2 else max;
    }
    for (0..width - 2) |w| {
        const val = try simulate(allocator, .{ .dir = .down, .pos = .{ .x = @intCast(w), .y = 0 } });
        max = if (max < val) val else max;
        const val2 = try simulate(allocator, .{ .dir = .up, .pos = .{ .x = @intCast(w), .y = @intCast(height) } });
        max = if (max < val2) val2 else max;
    }

    std.log.info("Solution 2: {}", .{max});
}
