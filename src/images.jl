
module Images

using ..Cairo
using ..BoxPoints: Box, Point, BoxPoints
using ..Drawables: Drawable

export Pik, cairo_memory_surface_ctx, drawimage, drawimage_to_mask


mutable struct Pik
    # img is a matrix with #rows = width, #cols = height
    img::Matrix{UInt32}
    width
    height
end

BoxPoints.Box(pik::Pik) = Box(0, pik.width, 0, pik.height)


Base.copy(pik::Pik) = Pik(copy(pik.img), pik.width, pik.height)


function Pik(img::Matrix)
    height, width = size(img)
    return Pik(convert(Matrix{UInt32}, img), width, height)
end

function Pik(width, height)
    img = Matrix{UInt32}(undef, width, height)
    return Pik(img, width, height)
end

function Base.getproperty(p::Pik, s::Symbol)
    if s == :size
        return Point(getfield(p, :width), getfield(p, :height))
    else
        return getfield(p, s)
    end
end

# draws an image with top,left at p, or centered at p
# scaled to given width and height, if given
function drawimage(ctx::CairoContext, pik::Pik, p; width = nothing, height = nothing, centered = false)
    if width == nothing
        w = pik.width
    else
        w = width
    end
    if height == nothing
        h = pik.height
    else
        h = height
    end
    drawimage_x(ctx, pik::Pik, p.x, p.y, w, h; centered = centered)
end

drawimage(dw::Drawable, pik::Pik, p; kw...) = drawimage(dw.ctx, pik, p; kw...)

drawimage(ctx::CairoContext, pik::Pik, b::Box) = drawimage(ctx, pik, Point(b.xmin, b.ymin);
                                             width = b.xmax - b.xmin,
                                             height = b.ymax - b.ymin)
drawimage(dw::Drawable, pik::Pik, b::Box) = drawimage(dw.ctx, pik, b)


function drawimage_to_mask(ctx::CairoContext, pik::Pik, pts, sx, sy; format = Cairo.FORMAT_ARGB32,
                           operator = Cairo.OPERATOR_OVER)

    surface = Cairo.CairoSurface(pik; format)
    # line(ctx, pts; closed=true, keep=true)
    Cairo.move_to(ctx, pts[1])
    for i=2:length(pts)
        Cairo.line_to(ctx, pts[i])
    end
    Cairo.close_path(ctx)
    Cairo.save(ctx)
    Cairo.scale(ctx, 1/sx, 1/sy)
    Cairo.set_source_surface(ctx, surface, 0, 0)
    Cairo.set_operator(ctx, operator)
    Cairo.fill(ctx)
    Cairo.restore(ctx)
end
drawimage_to_mask(dw::Drawable, pik::Pik, pts, sx, sy; kw...) = drawimage_to_mask(dw.ctx, pik, pts, sx, sy; kw...)


function drawimage_x(ctx::CairoContext, pik::Pik, x, y, width, height; centered = centered, nearest = false)
    if centered
        x = x - width / 2
        y = y - height / 2
    end
    surface = Cairo.CairoSurface(pik)
    sx = pik.width/width  
    sy = pik.height/height
    Cairo.save(ctx)
    Cairo.scale(ctx, 1/sx, 1/sy)
    Cairo.set_source_surface(ctx, surface, sx*x, sy*y)
    if nearest
        Cairo.pattern_set_filter(Cairo.get_source(ctx), Cairo.FILTER_NEAREST)
    end
    Cairo.scale(ctx, sx, sy)
    Cairo.rectangle(ctx, x, y, width, height)
    Cairo.fill(ctx)
    Cairo.restore(ctx)
end
drawimage_x(dw::Drawable, args...; kw...) = drawimage_x(dw.ctx, args...; kw...)





##############################################################################
# surfaces

#
# One use of this is for converting an image to a surface,
# which can then be written to a context.
# Another use is for creating a surface in memory onto
# which one can write
#
# possible formats are Cairo.FORMAT_RGB24 or  Cairo.FORMAT_ARGB32
#
function Cairo.CairoSurface(pik::Pik; format = Cairo.FORMAT_RGB24)
    w = pik.width
    h = pik.height
    stride = Cairo.format_stride_for_width(format, w)
    ptr = ccall((:cairo_image_surface_create_for_data, Cairo.libcairo),
                Ptr{Nothing},
                (Ptr{Nothing}, Int32, Int32, Int32, Int32),
                pik.img, format, w, h, stride)
    return Cairo.CairoSurface(ptr, w, h, pik.img)
end

function cairo_memory_surface_ctx(width, height)
    pik = Pik(width, height)
    surface = CairoSurface(pik, format = Cairo.FORMAT_ARGB32)
    ctx = Cairo.CairoContext(surface)
    return pik, surface, ctx
end

end
