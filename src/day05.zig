const std = @import("std");
// const data = @embedFile("data/day5.txt");
const data = @embedFile("data/day5test.txt");

const Range = struct {
    start: usize = 0,
    length: usize = 0,
};

const Map = struct {
    const Self = @This();

    src: usize = 0,
    dest: usize = 0,
    length: usize = 0,

    pub fn map(self: *const Self, number: usize) ?usize {
        if (number >= self.src and number < self.src + self.length) return self.dest + (number - self.src);
        return null;
    }

    pub fn mapRange(self: *const Self, range: Range) ?[3]?Range {
        // Range partially or fully inside map
        if (self.src + self.length <= range.start or self.src >= range.start + range.length) return null;
        var ranges = [3]?Range{ null, null, null };
        const startIntersection: ?usize = if (range.start >= self.src) null else self.src - range.start;
        const endIntersection: ?usize = if (range.start + range.length > self.src + self.length) range.length - ((range.start + range.length) - (self.src + self.length)) else null;

        std.log.warn("Start: {any}, End: {any}", .{ startIntersection, endIntersection });
        std.log.warn("Range: {any}, Map: {any}", .{ range, self.* });
        // Guaranteed, intersection of map and range adjusted
        ranges[0] = .{
            .start = (startIntersection orelse 0) + self.dest,
            .length = (endIntersection orelse range.length) - (startIntersection orelse 0),
        };
        // Range before map
        ranges[1] = if (startIntersection) |int| .{
            .start = range.start,
            .length = int,
        } else null;

        ranges[2] = if (endIntersection) |int| .{
            .start = range.start + self.length,
            .length = range.length - int,
        } else null;

        return ranges;
    }
};

pub fn getMaps(allocator: std.mem.Allocator) ![7][]Map {
    var mapSplit = std.mem.splitSequence(u8, data, "\n\n");
    _ = mapSplit.next(); // Skip seeds line
    var maps: [7][]Map = undefined;
    var mapIndex: usize = 0;
    while (mapSplit.next()) |map| : (mapIndex += 1) {
        var lines = std.mem.splitAny(u8, map, "\n");
        _ = lines.next();
        const count = std.mem.count(u8, map, "\n");
        maps[mapIndex] = try allocator.alloc(Map, count);
        var lineIndex: usize = 0;
        while (lines.next()) |line| : (lineIndex += 1) {
            var parser = std.fmt.Parser{ .buf = line };
            maps[mapIndex][lineIndex].dest = parser.number() orelse return error.Parser;
            parser.pos += 1;
            maps[mapIndex][lineIndex].src = parser.number() orelse return error.Parser;
            parser.pos += 1;
            maps[mapIndex][lineIndex].length = parser.number() orelse return error.Parser;
        }
    }

    return maps;
}

pub fn solution1() !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const seeds = blk: {
        var lines = std.mem.splitAny(u8, data, "\n");
        const line = lines.first();
        const count = std.mem.count(u8, line, " ");
        var array = try allocator.alloc(usize, count);
        var split = std.mem.splitAny(u8, line, " ");
        _ = split.next();
        var index: usize = 0;
        while (split.next()) |s| {
            array[index] = try std.fmt.parseInt(usize, s, 10);
            index += 1;
        }
        break :blk array;
    };
    defer allocator.free(seeds);

    const maps = try getMaps(allocator);
    defer for (maps) |map| allocator.free(map);

    for (maps) |map| {
        for (seeds) |*num| {
            for (map) |range| {
                if (range.map(num.*)) |mapped| {
                    num.* = mapped;
                    break;
                }
            }
        }
    }

    const solution = blk: {
        var minimum: usize = 9999999999;
        for (seeds) |seed| {
            minimum = if (minimum > seed) seed else minimum;
        }
        break :blk minimum;
    };

    return solution;
}

pub fn solution2() !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var seeds = blk: {
        const line = data[0 .. std.mem.indexOf(u8, data, "\n") orelse 0];
        const count = std.mem.count(u8, line, " ");
        var list = try std.ArrayList(Range).initCapacity(allocator, count / 2);
        var parser = std.fmt.Parser{ .buf = line, .pos = 7 };
        for (0..count / 2) |_| {
            var range: Range = undefined;
            range.start = parser.number() orelse return error.Parser;
            parser.pos += 1;
            range.length = parser.number() orelse return error.Parser;
            parser.pos += 1;
            try list.append(range);
        }

        break :blk list;
    };
    std.log.info("Seed Start: {any}", .{seeds.items});
    defer seeds.deinit();

    const maps = try getMaps(allocator);
    defer for (maps) |map| allocator.free(map);

    for (maps) |map| {
        std.log.warn("Old Seeds: {any}", .{seeds.items});
        var rangeNum: usize = 0;
        while (rangeNum < seeds.items.len) : (rangeNum += 1) {
            for (map) |mapping| {
                if (mapping.mapRange(seeds.items[rangeNum])) |ranges| {
                    _ = seeds.orderedRemove(rangeNum);
                    try seeds.insert(rangeNum, ranges[0].?);
                    for (ranges[1..]) |range| {
                        if (range) |r| try seeds.insert(rangeNum + 1, r);
                    }
                }
            }
        }
        std.log.warn("New Seeds: {any}", .{seeds.items});
    }

    const solution = blk: {
        var minimum: usize = 99999999999;
        std.log.warn("Seeds: {any}", .{seeds.items});
        for (seeds.items) |seed| {
            minimum = if (minimum < seed.start) minimum else seed.start;
        }
        break :blk minimum;
    };

    return solution;
}

pub fn main() !void {
    try std.io.getStdOut().writer().print("Solution: {}, Solution 2: {}\n", .{ try solution1(), try solution2() });
}

test Range {
    const range = Range{
        .start = 100,
        .length = 20,
    };
    const m1 = Map{
        .src = 100,
        .length = 20,
        .dest = 200,
    };

    const mapped1 = m1.mapRange(range);
    try std.testing.expect(mapped1 != null and mapped1.?[0] != null and mapped1.?[1] == null and mapped1.?[2] == null);

    const m2 = Map{
        .src = 110,
        .length = 10,
        .dest = 200,
    };
    const mapped2 = m2.mapRange(range);
    try std.testing.expect(mapped2 != null and mapped2.?[1] != null and mapped2.?[2] == null);

    const m3 = Map{
        .src = 105,
        .length = 10,
        .dest = 200,
    };

    const mapped3 = m3.mapRange(range);
    try std.testing.expect(mapped3 != null and mapped3.?[1] != null and mapped3.?[2] != null);

    const m4 = Map{
        .src = 120,
        .length = 10,
        .dest = 200,
    };

    const mapped4 = m4.mapRange(range);

    std.log.warn("Mapped: {any}, {any}, {any}", .{ mapped1, mapped2, mapped3 });
    try std.testing.expect(mapped4 == null);
}
