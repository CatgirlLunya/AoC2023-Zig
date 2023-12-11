const std = @import("std");
const embed = @embedFile("data/day11.txt");
const width = std.mem.indexOfScalar(u8, embed, '\n') orelse unreachable;
const height = blk: {
    @setEvalBranchQuota(embed.len + 1000);
    break :blk std.mem.count(u8, embed, "\n");
};

const Galaxy = struct {
    x: isize,
    y: isize,
    x_expand: isize,
    y_expand: isize,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var data: [height * 3][width * 3]u8 = undefined;
    var row_split = std.mem.splitScalar(u8, embed, '\n');
    var i: usize = 0;
    var curr_row: usize = 0;
    var extra_rows = std.ArrayList(isize).init(allocator);
    defer extra_rows.deinit();
    var extra_cols = std.ArrayList(isize).init(allocator);
    defer extra_cols.deinit();
    while (row_split.next()) |row| : (i += 1) {
        if (row.len == 0) break;
        std.mem.copyForwards(u8, &data[curr_row], row[0..width]);
        var empty: bool = true;
        for (row) |char| {
            if (char == '#') {
                empty = false;
                break;
            }
        }
        if (empty) {
            try extra_rows.append(@intCast(i));
        }
        curr_row += 1;
    }

    var column: isize = 0;
    const max_columns: usize = width;
    while (column < max_columns) : (column += 1) {
        var empty = true;
        for (0..curr_row) |row| {
            if (data[row][@intCast(column)] == '#') {
                empty = false;
                break;
            }
        }
        if (empty) {
            try extra_cols.append(column);
        }
    }

    var galaxy_list = std.ArrayList(Galaxy).init(allocator);
    defer galaxy_list.deinit();
    for (data[0..curr_row], 0..) |row, y| {
        for (row, 0..) |char, x| {
            _ = char;
            if (data[y][x] == '#') {
                var x_expand: isize = 0;
                var y_expand: isize = 0;
                if (y > 0) {
                    for (0..y) |dy| {
                        if (std.mem.indexOfScalar(isize, extra_rows.items, @intCast(dy)) != null) {
                            y_expand += 1;
                        }
                    }
                }
                if (x > 0) {
                    for (0..x) |dx| {
                        if (std.mem.indexOfScalar(isize, extra_cols.items, @intCast(dx)) != null) {
                            x_expand += 1;
                        }
                    }
                }
                const point = Galaxy{
                    .x = @intCast(x),
                    .y = @intCast(y),
                    .x_expand = x_expand * 999999,
                    .y_expand = y_expand * 999999,
                };
                try galaxy_list.append(point);
            }
        }
    }

    var sum: usize = 0;
    for (galaxy_list.items, 0..) |galaxy1, j| {
        for (galaxy_list.items[j + 1 ..]) |galaxy2| {
            sum += @abs((galaxy1.x + (galaxy1.x_expand - 1)) - (galaxy2.x + galaxy2.x_expand - 1)) + @abs((galaxy1.y + galaxy1.y_expand - 1) - (galaxy2.y + galaxy2.y_expand - 1));
        }
    }

    std.log.info("Sum: {}", .{sum});
}
