const std = @import("std");

pub const CatImg = struct {
    pub const Hdr: []const u8 = &.{ 0x1b, 0x5b, 0x73, 0x1b, 0x5b, 0x3f, 0x32, 0x35, 0x6c };

    /// "\x1b5b[m"  // reset all attributes
    pub const LineEnd: []const u8 = &.{ 0x1b, 0x5b, 0x6d, 0x0a };

    /// "\x1b[?25h" // make cursor visible
    pub const FileEnd: []const u8 = &.{ 0x1b, 0x5b, 0x3f, 0x32, 0x35, 0x68 };
};

pub const SpriteAnimation = struct {
    name: []const u8,

    animation: []const usize, // array of frame indizes
    rel_x: []const usize, // array relative x position to spr->x
    rel_y: []const usize, // array relative y position to spr->y

    curren_idx: usize = 0,

    ctr1: usize = 0, // convenience counters and thresholds
    ctr2: usize = 0,
    ctr3: usize = 0,
    thr1: usize = 0,
    thr2: usize = 0,
    thr3: usize = 0,

    loop: usize = 0,
    loop_idx: usize = 0,
    loop_threshold: usize = 0,
};

pub const RgbColor = struct {
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
};

pub const HslColor = struct {
    h: u32,
    s: f32,
    l: f32,
};

pub const RgbPalette = []RgbColor;

// Example
//
// rgb_color = { 82, 0, 87 };
//
// H: 296
// S: 1
// L: 0.17058824f
pub fn rgb2hsl(rgb: *RgbColor, hsl: *HslColor) void {
    const r: f32 = (rgb.r / 255.0);
    const g: f32 = (rgb.g / 255.0);
    const b: f32 = (rgb.b / 255.0);

    const min = @min(@min(r, g), b);
    const max = @max(@max(r, g), b);
    const delta = max - min;

    hsl.l = (max + min) / 2; // L

    if (delta == 0) {
        hsl.h = 0; // H
        hsl.s = 0.0; // S
    } else {
        hsl.s = if (hsl.l <= 0.5) (delta / (max + min)) else (delta / (2 - max - min));

        var hue: f32 = undefined;

        if (r == max) {
            hue = ((g - b) / 6) / delta;
        } else if (g == max) {
            hue = (1.0 / 3) + ((b - r) / 6) / delta;
        } else {
            hue = (2.0 / 3) + ((r - g) / 6) / delta;
        }

        if (hue < 0)
            hue += 1;
        if (hue > 1)
            hue -= 1;

        hsl.h = @intCast(hue * 360); // H
    }
}

pub fn hue2rgb(v1: f32, v2: f32, vH: f32) f32 {
    if (vH < 0.0)
        vH += 1.0;

    if (vH > 1.0)
        vH -= 1.0;

    if ((6.0 * vH) < 1.0)
        return (v1 + (v2 - v1) * 6.0 * vH);

    if ((2.0 * vH) < 1.0)
        return v2;

    if ((3.0 * vH) < 2.0)
        return (v1 + (v2 - v1) * ((2.0 / 3.0) - vH) * 6.0);

    return v1;
}

// Example
//
// hsl_color = { 138, 0.50f, 0.76f };
//
// R: 163
// G: 224
// B: 181
pub fn hsl2rgb(hsl: *HslColor, rgb: *RgbColor) void {
    if (hsl.s == 0) {
        const value: u8 = @intCast(hsl.l * 255);
        rgb.r = value;
        rgb.g = value;
        rgb.b = value;
    } else {
        var v1: f32 = undefined;
        var v2: f32 = undefined;
        const hue: f32 = hsl.h / 360;

        v2 = blk: {
            if (hsl.l < 0.5) break :blk (hsl.l * (1 + hsl.s)) else break :blk ((hsl.l + hsl.s) - (hsl.l * hsl.s));
        };

        v1 = 2 * hsl.l - v2;

        rgb.r = @intCast(255 * hue2rgb(v1, v2, hue + (1.0 / 3)));
        rgb.g = @intCast(255 * hue2rgb(v1, v2, hue));
        rgb.b = @intCast(255 * hue2rgb(v1, v2, hue - (1.0 / 3)));
    }
}

// tsrendersurface.hpp
pub const RenderSurface = struct {
    a: std.mem.Allocator,
    w: usize, // measured in blocks, 1 ASCI char has width 1
    h: usize, // measured in blocks, 1 ASCII char has height 2, 1 block height

    x: usize,
    y: usize,

    z: usize, // layer - for sorting by rendering engine

    colormap: []RgbColor,
    shadowmap: []u8,

    // "need render" f sprites:
    // anis set this, effects, etc.
    // set_frameidx, etc
    // if 0, sprite doesn't re-render itself
    // just waisting time
    is_updated: bool = false,

    pub fn init(alloc: std.mem.Allocator, w: usize, h: usize, c: RgbColor) !RenderSurface {
        var ret = RenderSurface{
            .a = alloc,
            .w = w,
            .h = h,
            .colormap = try alloc.alloc(RgbColor, w * h),
            .shadowmap = try alloc.alloc(u8, w * h),
        };
        ret.clear_surface_bgcolor(c);
    }

    pub fn deinit(s: *RenderSurface) void {
        s.alloc.free(s.colormap);
        s.alloc.free(s.shadowmap);
    }

    pub fn clear_surface_bgcolor(s: *RenderSurface, c: RgbColor) !void {
        if (s.colormap.len != s.shadowmap.len) return error.MapLenMisMatch;

        for (s.colormap) |*item| {
            item.* = c;
        }
        for (s.shadowmap) |*item| {
            item.* = 0;
        }
    }

    pub fn clear_surface_transparent(s: *RenderSurface) !void {
        if (s.colormap.len != s.shadowmap.len) return error.MapLenMisMatch;

        const c = RgbColor{ .r = 0, .g = 0, .b = 0 };

        for (s.colormap) |*item| {
            item.* = c;
        }
        for (s.shadowmap) |*item| {
            item.* = 0;
        }
    }
};

// tsprites.hpp

pub const TSPriteFrame = struct {
    nr: usize = 0,
    w: usize = 0,
    h: usize = 0,
    colormap: []RgbColor,
    shadowmap: []u8,
    s: []const u8 = "",
    s_1down: []const u8, // frame 0: copy of s_1down
};

pub const TFrameSet = struct {
    frames: []TSPriteFrame,
    frame_idx: usize = 0,
};

fn printf(msg: []const u8) void {
    std.log.debug("{s}", .{msg});
}

pub const TSprite = struct {
    alloc: std.mem.Allocator,
    w: usize = 0,
    h: usize = 0, // in blocks / "half characters"
    x: usize = 0,
    y: usize = 0, // in blocks / "half characters"
    z: usize = 0,
    fs: ?TFrameSet = null, // frames for slicing, animations, ...

    // convenience counters and thresholds
    counter1: usize = 0,
    counter2: usize = 0,
    counter3: usize = 0,
    threshhold1: usize = 0,
    threshhold2: usize = 0,
    threshhold3: usize = 0,

    state: usize = 0, // generic type to support own concepts

    out_surface: ?*RenderSurface = null, // last render, direct access for speed

    s: []const u8 = "", // for fast Print() / printf()

    // for convenience, created on import:
    // pre-rendered string-representation, having the sprite
    // moved 1 block down. For fast Print(x, y) ( using only printf() ),
    // if you don't want to deal with frames / rendering at all.
    // -> Makes smooth Y-movements possible with fast printf(),
    s_1down: []const u8 = "",

    // rgb_color *background = 0, // for rendering

    pub fn init(alloc: std.mem.Allocator) TSprite {
        return .{
            .alloc = alloc,
        };
    }

    // pub fn init_from_dims(w: usize, h: usize) TSprite { }

    pub fn initFromCatimg(alloc: std.mem.Allocator, imgstr: []const u8) !TSprite {
        var ret = TSprite{ .alloc = alloc };
        try ret.importFromImgStr(imgstr);
        return ret;
    }

    pub fn deinit(self: *TSprite) void {
        self.free_frames();
        // and s_1down, etc
    }

    // should be removed in favor of deinit long-term
    pub fn free_frames(self: *TSprite) void {
        _ = self;
    }

    // instead of an error, we just use a bool for now
    pub fn importFromImgStr(self: *TSprite, str: []const u8) !bool {
        const hdr = CatImg.Hdr;
        var width: usize = 0;
        var height: usize = 0;
        const l = str.len;

        // -- check file "hdr": catimg esc seq 0x1b, 0x5b, 0x73 = "\x1b[s"
        if (l < CatImg.Hdr.len) {
            printf("[TS][ImportFromImgStr] ERROR: invalid file type!\n");
            return false;
        }

        if (!std.mem.eql(u8, str[0..CatImg.Hdr.len], hdr)) {
            printf("[TS][ImportFromImgStr] ERROR: invalid file type!\n");
            return false;
        }

        // -- start conversion
        var pos: usize = CatImg.Hdr.len; // start of 1st line
        var lnr: usize = 0;

        // result, ready2print char * string, with relative line ends
        var outstr = self.alloc.allocate(u8, l + 4096) catch {
            printf("[TS][ImportFromImgStr] ERROR: unable to alloc tmp mem!\n");
            return false;
        }; // surplus for new lineend encodings
        // 0x0a -> esc: go w left, 1 down

        // -- convert line by line
        var lpos: usize = 0; // pos in line
        var pxcount: usize = 0;
        var out_idx: usize = 0;

        while (pos < (l - (CatImg.LineEnd.len + CatImg.FileEnd.len))) {
            // search end of line (0x0a)
            // s[pos] = start of line
            lpos = 0; // pos in line

            while (str[pos + lpos + CatImg.LineEnd.len - 1] != 0x0a) {
                const c = str[pos + lpos];

                if (c == 0x96 or c == 0x20) {
                    if (lnr == 0) {
                        // count on 1st line only
                        width += 1;
                    }
                    pxcount += 1;
                }
                lpos += 1;
            }

            // -- here we stand at line end, and have width:
            // -> add this line + go left + go down to result
            std.log.debug(
                "\n[TS][ImportFromImgStr] line nr #{}, pos: {}, llen: {}\n",
                .{ lnr, pos, lpos },
            );

            // copy line to result, out_idx is 0 now
            std.mem.copy(u8, outstr[0..lpos], str[pos .. pos + lpos]);
            out_idx = lpos;

            // TODO: rene the following copies could be avoided if we printed directly into outstr

            // create new, relative line end
            const clear_str: []const u8 = "\x1b[0m"; // clear all modes
            std.mem.copy(u8, outstr[out_idx .. out_idx + clear_str.len], clear_str[0..clear_str.len]);
            out_idx += clear_str.len;

            // cursor go left(lpos)
            const goleft_str = try std.fmt.bufPrint(outstr[out_idx..outstr.len], "\x1b[{}D", .{width});
            out_idx += goleft_str.len;

            const godown_str: []const u8 = "\x1b[1B"; // cursor go down(1)
            std.mem.copy(u8, outstr[out_idx .. out_idx + godown_str.len], godown_str[0..godown_str.len]);
            out_idx += goleft_str.len;

            lpos += CatImg.LineEnd.len;

            lnr += 1;
            height += 2; // 1 char = 2 blocks high

            pos += lpos;
        }
        outstr[out_idx] = 0x00; // conversion done

        std.log.debug(
            "\nw[TS][ImportFromImgStr] x h = {} x {} = pxcount = {}, tt px-size of conversion: {}\n",
            .{ width, height, pxcount, out_idx },
        );

        // -- now we have w, h -> we know image size and can create and
        // fill maps / a new frame:

        var F: *TSPriteFrame = self.add_frames(1, width, height);
        F.s = try self.alloc.dupe(u8, outstr[0..out_idx]);

        // -- fill maps from input string
        self.imgstr_2maps(str, F);

        // -- create 1down representation, store in frame
        self.create_1down_str(F);

        // Skip, when called for further frames:
        // Sprite gets initialized only from 1st frame (frame 0)
        if (self.fs) |*fs| {
            if (fs.frame_count == 1) {
                self.s = outstr;
                self.h = height;
                self.w = width;
                self.s_1down = try self.alloc.dupe(u8, F.s_1down);
            }
        }

        return true;
    }
};

// tscreen.hpp
// tseffects.hpp
// tsrender.hpp
// tsutils.hpp
