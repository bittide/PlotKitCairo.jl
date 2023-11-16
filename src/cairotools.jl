
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
using ..Cairo: destroy, CairoContext, Cairo, CairoPattern, circle, rectangle, stroke, text
using ..Colors
using ..BoxPoints
using ..Drawables: Drawable
using ..Curves: Bezier


export destroy, LineStyle, add_color_stop, circle, curve, curve_between, draw, get_text_info, line, line_to, linear_pattern, move_to, over, rect, set_linestyle, source, stroke, text

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
function get_text_info(ctx::CairoContext, fsize, fname, txt)
    Cairo.select_font_face(ctx, fname, Cairo.FONT_SLANT_NORMAL,
                           Cairo.FONT_WEIGHT_NORMAL)
    Cairo.set_font_size(ctx, fsize)
    return Cairo.text_extents(ctx, txt)
end
get_text_info(dw::Drawable, fsize, fname, txt) = get_text_info(dw.ctx, fsize, fname, txt)

"""
    text(ctx, p, fsize, color, txt; horizontal, vertical, fname)

Write txt to the Cairo context at point p, with given size and color.

Here horizontal alignment can be "left", "center", or "right".
Vertical alignment can be "top", "center", "bottom" or "baseline".
"""
function Cairo.text(ctx::CairoContext, p::Point, fsize, fcolor, txt; horizontal = "left", vertical="baseline", fname="Sans")
    left, top, width, height = get_text_info(ctx, fsize, fname, txt)
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
    textx(ctx, p, fsize, fcolor, fname, txt)
end
Cairo.text(dw::Drawable, args...; kw...) = text(dw.ctx, args...; kw...)
           




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
source(ctx::CairoContext, p::CairoPattern) = Cairo.set_source(ctx, p)
source(dw::Drawable, c) = source(dw.ctx, c)


"""
    linear_pattern(q1, q2)

Create a Cairo linear pattern between points q1 and q2.
"""
linear_pattern(q1::Point, q2::Point) = Cairo.pattern_create_linear(q1.x, q1.y, q2.x, q2.y)



"""
   add_color_stop(pat::CairoPattern, offset, c::RGBColor)

Add a Cairo color stop.
"""
add_color_stop(pat::CairoPattern, offset, c::RGBColor) = Cairo.pattern_add_color_stop_rgb(pat, offset, c.r, c.g, c.b)
add_color_stop(pat::CairoPattern, offset, c::RGBAColor) = Cairo.pattern_add_color_stop_rgba(pat, offset, c.r, c.g, c.b, c.a)

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
function textx(ctx::CairoContext, p::Point, fsize, color, fname, txt)
    Cairo.select_font_face(ctx, fname, Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_NORMAL)
    Cairo.set_font_size(ctx, fsize)
    Cairo.move_to(ctx, p)
    source(ctx, color)
    Cairo.show_text(ctx, txt)
end
textx(dw::Drawable, p::Point, fsize, color, fname, txt) = textx(dw.ctx, p, fsize, color, fname, txt)

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
curve(ctx::CairoContext, b::Bezier; kw...) = curve(ctx, b.p0, b.p1, b.p2, b.p3; kw...)
curve(dw::Drawable, p0, p1, p2, p3; kw...) = curve(dw.ctx,  p0, p1, p2, p3; kw...)
curve(dw::Drawable, b::Bezier; kw...) = curve(dw.ctx,  b; kw...)



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


end
