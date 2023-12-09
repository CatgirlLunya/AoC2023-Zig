const std = @import("std");
const data = @embedFile("data/day8.txt");

const Node = struct {
    data: [3]u8 = undefined,
    left: [3]u8 = undefined,
    right: [3]u8 = undefined,
    lindex: usize = 0,
    rindex: usize = 0,

    pub fn init(line: []u8) Node {
        var node: Node = .{};
        var i: usize = 0;
        var num: usize = 0;
        while (i < line.len) : (i += 1) {
            if (std.ascii.isAlphanumeric(line[i])) {
                if (num == 0) std.mem.copyForwards(u8, &node.data, line[i .. i + 3]);
                if (num == 1) std.mem.copyForwards(u8, &node.left, line[i .. i + 3]);
                if (num == 2) std.mem.copyForwards(u8, &node.right, line[i .. i + 3]);
                i += 3;
                num += 1;
                if (num == 3) continue;
            }
        }

        return node;
    }

    pub fn eql(self: Node, other: *const [3:0]u8) bool {
        return std.mem.eql(u8, &self.data, other);
    }

    pub fn next(self: Node, list: []Node, instr: u8) *Node {
        const find = switch (instr) {
            'L' => self.lindex,
            'R' => self.rindex,
            else => @panic("Undefined instruction!"),
        };

        return &list[find];
    }
};

pub fn solution1(node_list: []Node, instructions: []const u8) usize {
    var head = blk: {
        for (node_list) |*node| {
            if (node.eql("AAA")) break :blk node;
        }
        @panic("No head found");
    };

    var instruction: usize = 0;
    var i: usize = 0;
    while (true) {
        if (head.eql("ZZZ")) break;
        head = head.next(node_list, instructions[instruction]);
        instruction += 1;
        i += 1;
        if (instruction == instructions.len) instruction = 0;
    }

    return i;
}

pub fn solution2(allocator: std.mem.Allocator, node_list: []Node, instructions: []const u8) !u128 {
    const count = blk: {
        var count: usize = 0;
        for (node_list) |node| {
            if (node.data[2] == 'A') count += 1;
        }
        break :blk count;
    };

    var heads = try allocator.alloc(Node, count);
    defer allocator.free(heads);
    var i: usize = 0;
    for (node_list) |node| {
        if (node.data[2] == 'A') {
            heads[i] = node;
            i += 1;
        }
    }

    i = 0;
    var instruction: usize = 0;
    const ratios = try allocator.alloc(usize, count);
    defer allocator.free(ratios);
    for (ratios) |*r| r.* = 0;

    var a: usize = 0;
    while (true) : (a += 1) {
        for (heads, ratios) |*head, *r| {
            if (head.data[2] == 'Z' and r.* == 0) {
                r.* = a;
            }
            head.* = head.next(node_list, instructions[instruction]).*;
        }
        instruction += 1;
        if (instruction == instructions.len) instruction = 0;
        var correct = true;
        for (ratios) |r| {
            if (r == 0) correct = false;
        }
        if (correct) break;
    }

    var gcd: u128 = ratios[0];
    var product: u128 = ratios[0];
    for (ratios[1..]) |r| {
        gcd = std.math.gcd(gcd, r);
        product *= r;
    }

    std.log.info("Ratios: {any}, gcd: {}, product: {}", .{ ratios, gcd, product });

    return product / gcd;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    var lines = std.mem.splitScalar(u8, data, '\n');
    const instructions = lines.next().?;
    _ = lines.next();

    var node_list = try allocator.alloc(Node, std.mem.count(u8, lines.rest(), "\n") + 1);
    var i: usize = 0;
    while (lines.next()) |line| : (i += 1) {
        const node = Node.init(@constCast(line));
        node_list[i] = node;
    }

    for (node_list) |*node| {
        node.lindex = blk: {
            for (node_list, 0..) |n, a| {
                if (std.mem.eql(u8, &node.left, &n.data)) break :blk a;
            }
            @panic("No left index!");
        };
        node.rindex = blk: {
            for (node_list, 0..) |n, a| {
                if (std.mem.eql(u8, &node.right, &n.data)) break :blk a;
            }
            @panic("No right index!");
        };
    }

    try std.io.getStdOut().writer().print("Solution 1: {}, Solution 2: {}\n", .{ 0, try solution2(allocator, node_list, instructions) });
}
