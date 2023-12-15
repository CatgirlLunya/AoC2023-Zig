const std = @import("std");
const data = @embedFile("data/day15.txt");
const test_data = "rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7";

fn HASH(str: []const u8) usize {
    var value: usize = 0;
    for (str) |c| {
        if (c == '\n') continue;
        value += @as(usize, c);
        value *= 17;
        value %= 256;
    }
    return value;
}

const Lens = struct {
    label: []const u8,
    number: usize,
};

const Box = std.ArrayList(Lens);

pub fn main() !void {
    var split = std.mem.splitScalar(u8, data, ',');
    var sol1: usize = 0;

    while (split.next()) |str| {
        sol1 += HASH(str);
    }

    try std.io.getStdOut().writer().print("Solution 1: {}\n", .{sol1});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var boxes: [256]Box = undefined;
    for (0..256) |box| {
        boxes[box] = Box.init(allocator);
    }

    split.reset();
    while (split.next()) |str| {
        const labeli = blk: {
            for (str, 0..) |c, i| {
                if (!std.ascii.isAlphabetic(c)) break :blk i;
            }
            unreachable;
        };
        const label = str[0..labeli];
        const hash = HASH(label);
        const op = str[labeli];
        if (op == '=') {
            var inside: bool = false;
            const number = str[labeli + 1] - '0';
            for (boxes[hash].items, 0..) |b, i| {
                if (std.mem.eql(u8, b.label, label)) {
                    boxes[hash].items[i].number = number;
                    inside = true;
                    break;
                }
            }
            if (!inside) try boxes[hash].append(Lens{ .label = label, .number = number });
        } else {
            for (boxes[hash].items, 0..) |b, i| {
                if (std.mem.eql(u8, b.label, label)) {
                    _ = boxes[hash].orderedRemove(i);
                    break;
                }
            }
        }
    }

    var sol2: usize = 0;
    for (boxes, 0..) |box, id| {
        for (box.items, 0..) |item, slot| {
            sol2 += (id + 1) * (slot + 1) * item.number;
        }
    }

    try std.io.getStdOut().writer().print("Solution 2: {}\n", .{sol2});
}
