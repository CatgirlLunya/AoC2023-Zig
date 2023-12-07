const std = @import("std");
const data = @embedFile("data/day7.txt");

const HandType = enum(u8) {
    const Self = @This();

    high_card,
    one_pair,
    two_pair,
    three_of_a_kind,
    full_house,
    four_of_a_kind,
    five_of_a_kind,

    pub fn lt(self: Self, other: Self) bool {
        return @intFromEnum(self) < @intFromEnum(other);
    }

    pub fn eql(self: Self, other: Self) bool {
        return @intFromEnum(self) == @intFromEnum(other);
    }

    pub fn gt(self: Self, other: Self) bool {
        return @intFromEnum(self) > @intFromEnum(other);
    }

    pub fn cmp(self: Self, other: Self) std.math.Order {
        if (self.lt(other)) return .lt;
        if (self.gt(other)) return .gt;
        return .eq;
    }
};

test HandType {
    try std.testing.expect(HandType.high_card.lt(.two_pair));
    try std.testing.expect(HandType.full_house.eql(.full_house));
    try std.testing.expect(HandType.four_of_a_kind.gt(.two_pair));
}

const Hand = struct {
    order: [5]u8 = undefined,
    type: HandType = undefined,

    pub fn init(allocator: std.mem.Allocator, order: []u8, trial2: bool) !Hand {
        var hand = Hand{};
        for (0..5) |i| {
            hand.order[i] = switch (order[i]) {
                '0'...'9' => |c| c - '0',
                'T' => 10,
                'J' => if (trial2) 1 else 11,
                'Q' => 12,
                'K' => 13,
                'A' => 14,
                else => @panic("Invalid char"),
            };
        }
        var map = std.AutoHashMap(u8, u8).init(allocator);
        defer map.deinit();
        var jokers: u8 = 0;
        for (hand.order) |card| {
            if (trial2 and card == 1) {
                jokers += 1;
                continue;
            }
            if (map.getPtr(card)) |c| {
                c.* += 1;
            } else {
                try map.put(card, 1);
            }
        }

        var mvit = map.valueIterator();
        if (mvit.len != 0) {
            while (mvit.next()) |i| {
                i.* += jokers;
            }
        } else {
            try map.put(1, 5);
        }

        hand.type = switch (map.count()) {
            5 => .high_card,
            4 => .one_pair,
            3 => blk: {
                var it = map.valueIterator();
                while (it.next()) |item| {
                    if (item.* == 3) break :blk .three_of_a_kind;
                }
                break :blk .two_pair;
            },
            2 => blk: {
                var it = map.valueIterator();
                while (it.next()) |item| {
                    if (item.* == 4) break :blk .four_of_a_kind;
                }
                break :blk .full_house;
            },
            1 => .five_of_a_kind,
            else => {
                std.log.err("Invalid sequence: {any}", .{hand.order});
                @panic("Invalid type");
            },
        };

        return hand;
    }

    pub fn cmp(self: Hand, other: Hand) std.math.Order {
        const type_cmp = self.type.cmp(other.type);
        if (type_cmp != .eq) return type_cmp;

        return std.mem.order(u8, &self.order, &other.order);
    }
};

test Hand {
    const hand1 = try Hand.init(std.testing.allocator, [_]u8{ 2, 3, 4, 5, 6 });
    try std.testing.expect(hand1.type == .high_card);
    const hand2 = try Hand.init(std.testing.allocator, [_]u8{ 2, 2, 3, 4, 5 });
    try std.testing.expect(hand2.type == .one_pair);
    const hand3 = try Hand.init(std.testing.allocator, [_]u8{ 2, 2, 3, 3, 4 });
    try std.testing.expect(hand3.type == .two_pair);
    const hand4 = try Hand.init(std.testing.allocator, [_]u8{ 2, 2, 2, 3, 4 });
    try std.testing.expect(hand4.type == .three_of_a_kind);
    const hand5 = try Hand.init(std.testing.allocator, [_]u8{ 2, 2, 2, 3, 3 });
    try std.testing.expect(hand5.type == .full_house);
    const hand6 = try Hand.init(std.testing.allocator, [_]u8{ 2, 2, 2, 2, 3 });
    try std.testing.expect(hand6.type == .four_of_a_kind);
    const hand7 = try Hand.init(std.testing.allocator, [_]u8{ 2, 2, 2, 2, 2 });
    try std.testing.expect(hand7.type == .five_of_a_kind);

    const hand8 = try Hand.init(std.testing.allocator, [_]u8{ 3, 3, 2, 2, 2 });
    try std.testing.expect(hand8.cmp(hand5) == .gt);
    try std.testing.expect(hand8.cmp(hand7) == .lt);
}

const Play = struct {
    hand: Hand,
    value: usize,

    pub fn init(allocator: std.mem.Allocator, line: []u8, trial2: bool) !Play {
        return Play{
            .hand = try Hand.init(allocator, line[0..5], trial2),
            .value = try std.fmt.parseInt(usize, line[6..], 10),
        };
    }

    pub fn lt(_: void, self: Play, other: Play) bool {
        return self.hand.cmp(other.hand) == .lt;
    }
};

pub fn main() !void {
    const count = 1000;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    var lines = std.mem.splitScalar(u8, data, '\n');
    var plays = try allocator.alloc(Play, count);
    var trial2plays = try allocator.alloc(Play, count);
    defer allocator.free(plays);
    defer allocator.free(trial2plays);
    var index: usize = 0;
    while (lines.next()) |line| : (index += 1) {
        plays[index] = try Play.init(allocator, @constCast(line), false);
        trial2plays[index] = try Play.init(allocator, @constCast(line), true);
    }

    std.sort.block(Play, plays, {}, Play.lt);
    std.sort.block(Play, trial2plays, {}, Play.lt);

    var sum: usize = 0;
    var trial2sum: usize = 0;
    for (plays, 0..count) |p, i| {
        sum += (i + 1) * p.value;
    }

    for (trial2plays, 0..count) |p, i| {
        trial2sum += (i + 1) * p.value;
    }

    try std.io.getStdOut().writer().print("Solution: {}, Solution 2: {}\n", .{ sum, trial2sum });
}
