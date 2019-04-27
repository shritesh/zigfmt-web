const std = @import("std");

fn format(source: []const u8, allocator: *std.mem.Allocator) ![]u8 {
    const tree = try std.zig.parse(allocator, source);
    defer tree.deinit();

    var buffer = try std.Buffer.initSize(allocator, 0);
    defer buffer.deinit();

    var buffer_stream = std.io.BufferOutStream.init(&buffer);

    _ = try std.zig.render(allocator, &buffer_stream.stream, tree);

    const slice = buffer.toSliceConst();

    var result = try allocator.alloc(u8, slice.len);
    std.mem.copy(u8, result, slice);
    return result;
}

export fn format_export(input_ptr: [*]const u8, input_len: usize, output_ptr: *[*]u8, output_len: *usize) bool {
    const input = input_ptr[0..input_len];

    var output = format(input, std.heap.wasm_allocator) catch |err| return false;

    output_ptr.* = output.ptr;
    output_len.* = output.len;
    return true;
}

export fn _wasm_alloc(len: usize) u32 {
    var buf = std.heap.wasm_allocator.alloc(u8, len) catch |err| return 0;
    return @ptrToInt(buf.ptr);
}

export fn _wasm_dealloc(ptr: [*]const u8, len: usize) void {
    std.heap.wasm_allocator.free(ptr[0..len]);
}
