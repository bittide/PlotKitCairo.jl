# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


module CairoTools

using LinearAlgebra
using ..Cairo
using ..Colors
using ..BoxPoints



export Drawable, ImageDrawable, LineStyle, PDFDrawable, Pik, RecorderDrawable, SVGDrawable, cairo_memory_surface_ctx, circle, closepdfsurface, closepngsurface, closesurface, curve, curve_between, draw, drawimage, drawimage_to_mask, get_text_info, line, line_to, makepdfsurface, makepngsurface, makesurface, move_to, oblong, over, paint, polygon, rect, save, set_linestyle, source, star, stroke, text, triangle

##############################################################################
abstract type Drawable
end

mutable struct ImageDrawable <: Drawable
    surface
    ctx
    width
    height
    fname
end


mutable struct PDFDrawable <: Drawable
    surface
    ctx
    width
    height
    fname
end

mutable struct SVGDrawable <: Drawable
    surface
    ctx
    width
    height
    fname
end

mutable struct RecorderDrawable <: Drawable
    surface
    ctx
    width
    height
end


##############################################################################

mutable struct LineStyle
    color
    width
end


##############################################################################
# text functions

"""
    get_text_info(ctx, fsize, txt)

Returns the Cairo text_extents data giving the dimensions of the text at size fsize.
"""
function get_text_info(ctx::CairoContext, fsize, txt)
    Cairo.select_font_face(ctx, "Sans", Cairo.FONT_SLANT_NORMAL,
                           Cairo.FONT_WEIGHT_NORMAL)
    Cairo.set_font_size(ctx, fsize)
    return Cairo.text_extents(ctx, txt)
end
get_text_info(dw::Drawable, fsize, txt) = get_text_info(dw.ctx, fsize, txt)

"""
    text(ctx, p, fsize, color, txt; horizontal, vertical)

Write txt to the Cairo context at point p, with given size and color.

Here horizontal alignment can be "left", "center", or "right".
Vertical alignment can be "top", "center", "bottom" or "baseline".
"""
function Cairo.text(ctx::CairoContext, p::Point, fsize, fcolor, txt; horizontal = "left", vertical="baseline")
    left, top, width, height = get_text_info(ctx, fsize, txt)
    if horizontal == "left"
        dx = left
    elseif horizontal == "center"
        dx = left + width/2
    elseif horizontal == "right"
        dx = left + width
    end
    if vertical == "top"
        dy = top 
    elseif vertical == "center"
        dy = top + height/2
    elseif vertical == "bottom"
        dy = top + height
    elseif vertical == "baseline"
        dy = 0
    end
    p = p - Point(dx, dy)
    textx(ctx, p, fsize, fcolor, txt)
end
Cairo.text(dw::Drawable, args...; kw...) = text(dw.ctx, args...; kw...)
           
##############################################################################
# surface functions

"""
    makerecordingsurface(width, height)

Create a Cairo recording surface.
"""
function RecorderDrawable(width, height)
    surface = CairoRecordingSurface(Cairo.CONTENT_COLOR_ALPHA,
                                    Cairo.CairoRectangle(0,0,width,height))
    ctx = CairoContext(surface)
    return RecorderDrawable(surface, ctx, width, height)
end


"""
     makepdfsurface(width, height, fname)

Create a Cairo surface for writing to pdf file fname.
"""
function PDFDrawable(width, height, fname)
    surface = CairoPDFSurface(fname, width, height)
    ctx = CairoContext(surface)
    return PDFDrawable(surface, ctx, width, height, fname)
end



"""
     makesvgsurface(width, height, fname)

Create a Cairo surface for writing to svg file fname.
"""
function SVGDrawable(width, height, fname)
    surface = CairoSVGSurface(fname, width, height)
    ctx = CairoContext(surface)
    return SVGDrawable(surface, ctx, width, height, fname)
end


"""
    makepngsurface(width, height)

Create a Cairo surface for writing to a png file.
"""
function ImageDrawable(width, height, fname)
    surface = CairoARGBSurface(width, height)
    ctx = CairoContext(surface)
    return ImageDrawable(surface, ctx, width, height, fname)
end


"""
    Drawable(width, height, fname)

Create a Cairo surface with given width/height. Determine type from the file extension.
"""
function Drawable(width, height; fname = nothing)
    if isnothing(fname)
        return RecorderDrawable(width, height)
    end
    
    if lowercase(fname[end-2:end]) == "png"
        return  ImageDrawable(width, height, fname)
    end

    if lowercase(fname[end-2:end]) == "svg"
        return SVGDrawable(width, height, fname)
    end
    
    if lowercase(fname[end-2:end]) == "pdf"
        return PDFDrawable(width, height, fname)
    end

    println("ERROR: need valid filename to create drawable")
end

"""
    closedrawable(dw::Drawable)

Close the Cairo surface and write output.
"""
function Base.close(dw::Drawable) 
    finish(dw.surface)
    destroy(dw.surface)
    destroy(dw.ctx)
end

function Base.close(dw::ImageDrawable)
    write_to_png(dw.surface, dw.fname)
    finish(dw.surface)
    destroy(dw.surface)
    destroy(dw.ctx)
end





"""
    get_scale(ctx)

Return the Cairo x,y scale factors between device and user space.
"""
function get_scale(ctx)
    s = Cairo.device_to_user_distance!(ctx, [1.0,0.0])
    return s[1], s[2]
end
get_scale(dw::Drawable) = get_scale(dw.ctx)



##############################################################################
# core cairo

"""
    source(ctx, c)

Set the current Cairo source to be the color c.
"""
source(ctx::CairoContext, c::RGBColor) = Cairo.set_source_rgb(ctx, c.r, c.g, c.b)
source(ctx::CairoContext, c::RGBAColor) = Cairo.set_source_rgba(ctx, c.r, c.g, c.b, c.a)
source(dw::Drawable, c::Color) = source(dw.ctx, c)


"""
    rectangle(ctx, p, wh)

Add a rectangle to the current path. p is the upper left, wh is the width-height.
"""
Cairo.rectangle(ctx::CairoContext, p::Point, wh::Point) = Cairo.rectangle(ctx, p.x, p.y, wh.x, wh.y)
Cairo.rectangle(dw::Drawable, p::Point, wh::Point) = Cairo.rectangle(dw.ctx, p, wh)

"""
    move_to(ctx, p)

Set the current point to p.
"""
Cairo.move_to(ctx::CairoContext, p::Point) = Cairo.move_to(ctx, p.x, p.y)
Cairo.move_to(dw::Drawable, p::Point) = Cairo.move_to(dw.ctx, p)


"""
    line_to(ctx, p)

Add a line to the current path from the current point to p.
"""
Cairo.line_to(ctx::CairoContext, p::Point) = Cairo.line_to(ctx, p.x, p.y)
Cairo.line_to(dw::Drawable, p::Point) = Cairo.line_to(dw.ctx, p)


"""
    arc(ctx, p, r, t1, t2)

Draw a Cairo arc of radius r, centered at p, starting at angle t1, ending angle t2
"""
Cairo.arc(ctx::CairoContext, p::Point, r, t1, t2) = Cairo.arc(ctx, p.x, p.y, r, t1, t2)
Cairo.arc(dw::Drawable, p::Point, r, t1, t2) = Cairo.arc(dw.ctx, p, r, t1, t2)


"""
    curve_to(ctx, p1, p2, p3)

Draw a curve from the current point to p3 with control points p1,p2.
"""
Cairo.curve_to(ctx::CairoContext, p1::Point, p2::Point, p3::Point) =  Cairo.curve_to(ctx, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y)
Cairo.curve_to(dw::Drawable, p1::Point, p2::Point, p3::Point) =  Cairo.curve_to(dw.ctx, p1, p2, p3)


"""
    set_linestyle(ctx, linestyle)

Set the linewidth and color of the pen for Cairo.
"""
function set_linestyle(ctx::CairoContext, ls::LineStyle)
    Cairo.set_line_width(ctx, ls.width)
    source(ctx, ls.color)
end
set_linestyle(dw::Drawable, ls::LineStyle) = set_linestyle(dw.ctx, ls)

"""
    stroke(ctx, linestyle)

Stroke the current Cairo path with linestyle
"""
function Cairo.stroke(ctx::CairoContext, ls::LineStyle)
    set_linestyle(ctx, ls)
    Cairo.stroke(ctx)
end
Cairo.stroke(dw::Drawable, ls::LineStyle) = stroke(dw.ctx, ls)


"""
    colorfill(ctx, color)

Fill the current Cairo path with color.
"""
function colorfill(ctx::CairoContext, fillcolor)
    source(ctx, fillcolor)
    Cairo.fill(ctx)
end
colorfill(dw::Drawable, fillcolor) = colorfill(dw.ctx, fillcolor)

"""
    strokefill(ctx, linestyle, fillcolor)

Stroke and fill the current cairo path.
"""
function strokefill(ctx::CairoContext, ls, fillcolor)
    set_linestyle(ctx, ls)
    Cairo.stroke_preserve(ctx)
    source(ctx, fillcolor)
    Cairo.fill(ctx)
end
strokefill(dw::Drawable, ls, fillcolor) = strokefill(dw.ctx, ls, fillcolor)

"""
    textx(ctx, p, size, color, txt)

Write txt at point p, with the given font size and color.
"""
function textx(ctx::CairoContext, p::Point, fsize, color, txt)
    Cairo.select_font_face(ctx, "Sans", Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_NORMAL)
    Cairo.set_font_size(ctx, fsize)
    Cairo.move_to(ctx, p)
    source(ctx, color)
    Cairo.show_text(ctx, txt)
end
textx(dw::Drawable, p::Point, fsize, color, txt) = textx(dw.ctx, p, fsize, color, txt)

"""
    draw(ctx; closed, linestyle, fillcolor)

Fill and/or stroke the current Cairo path.
"""
function draw(ctx::CairoContext; closed = false, linestyle = nothing,
              fillcolor = nothing, keep = false)
    if closed
        Cairo.close_path(ctx)
    end
    if closed && !isnothing(linestyle) && !isnothing(fillcolor)
        strokefill(ctx, linestyle, fillcolor)
        return
    end
    if closed && !isnothing(fillcolor)
        colorfill(ctx, fillcolor)
        return
    end
    if !isnothing(linestyle)
        stroke(ctx, linestyle)
        return
    end
    if isnothing(fillcolor) && isnothing(linestyle) && !keep
        Cairo.new_path(ctx)
    end
end
draw(dw::Drawable; kw...) = draw(dw.ctx, kw...)

##############################################################################
# elementary

"""
    rect(ctx, p, wh; linestyle, fillcolor)

Draw a rectangle with top-left corner at p and width-height given by wh.

"""
function rect(ctx::CairoContext, p::Point, wh::Point; linestyle = nothing, fillcolor = nothing)
    rectangle(ctx, p, wh)
    draw(ctx; closed = true, linestyle, fillcolor)
end
rect(dw::Drawable, p::Point, wh::Point; kw...) = rect(dw.ctx, p, wh; kw...)

rect(ctx::CairoContext, b::Box;  linestyle = nothing, fillcolor = nothing) = rect(ctx, Point(b.xmin, b.ymin), Point(b.xmax - b.xmin, b.ymax - b.ymin); linestyle, fillcolor)
rect(dw::Drawable, b::Box; kw...) = rect(dw.ctx, b; kw...)

"""
    circle(ctx, p, r; linestyle, fillcolor)

Draw a circle centered at p with radius r.
"""
function Cairo.circle(ctx::CairoContext, p::Point, r; linestyle = nothing, fillcolor = nothing)
    Cairo.new_sub_path(ctx)
    Cairo.arc(ctx, p, r, 0, 2*pi)
    draw(ctx; closed=true, linestyle, fillcolor)
end
Cairo.circle(dw::Drawable, p, r; kw...) = circle(dw.ctx, p, r; kw...)

"""
    curve(ctx, p0, p1, p2, p3; closed, linestyle, fillcolor)

Draw a cubic curve with control points p0, p1, p2, p3.
"""
function curve(ctx::CairoContext, p0, p1, p2, p3;
               closed = false, linestyle = nothing, fillcolor = nothing)
    Cairo.move_to(ctx, p0)
    Cairo.curve_to(ctx, p1, p2, p3)
    draw(ctx; closed, linestyle, fillcolor)
end
curve(dw::Drawable, p0, p1, p2, p3; kw...) = curve(dw.ctx,  p0, p1, p2, p3; kw...)

"""
    line(ctx, x; closed, linestyle, fillcolor)

Draw a line joining the points in the list of points x.
"""
function line(ctx::CairoContext, p::Array{Point};
              closed = false, linestyle = nothing, fillcolor = nothing,
              keep = false)
    Cairo.move_to(ctx, p[1])
    for i=2:length(p)
        Cairo.line_to(ctx, p[i])
    end
    draw(ctx; closed, linestyle, fillcolor, keep)
end
line(dw::Drawable, p::Array{Point}; kw...) = line(dw.ctx, p; kw...)

"""
    line(ctx, p, q; linestyle, arrowstyle, arrowpos)

Draw a line from Point p to Point q on the Cairo context ctx.
"""
function line(ctx::CairoContext, p::Point, q::Point; linestyle = nothing)
    Cairo.move_to(ctx, p)
    Cairo.line_to(ctx, q)
    draw(ctx; linestyle)
end
line(dw::Drawable, p::Point, q::Point; kw...) = line(dw.ctx, p, q; kw...)

###############################################################
# images

mutable struct Pik
    # img is a matrix with #rows = width, #cols = height
    img::Matrix{UInt32}
    width
    height
end

Box(pik::Pik) = Box(0, pik.width, 0, pik.height)


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
    line(ctx, pts; closed=true, keep=true)
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
# output a RecorderDrawable


# output to a context
# p = location of top-left of r in destination coords
function Cairo.paint(ctx::CairoContext, r::RecorderDrawable, p = Point(0,0), scalefactor = 1.0)
    save(ctx)
    scale(ctx, scalefactor, scalefactor)
    set_source_surface(ctx, r.surface, p.x/scalefactor, p.y/scalefactor)
    paint(ctx)
    restore(ctx)
end
Cairo.paint(dest::Drawable, args...) = paint(dest.ctx, args...)


# output to a file
function Cairo.save(r::RecorderDrawable, fname, scale=1)
    dw = Drawable(scale*r.width, scale*r.height, fname)
    Cairo.scale(dw.ctx, scale, scale)
    paint(dw, r)
    close(dw)
end




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
