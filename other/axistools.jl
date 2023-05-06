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


#
# pure functions for handling axis, ticks, limits and labels
#

module AxisTools

using ..Cairo
using ..Colors
using ..VeryBasic
using ..Basic
using ..CairoTools

export Axis, AxisMap, AxisOptions, AxisStyle, Layout, Ticks, best_labels, best_ticks, drawaxis, fit_box_around_data, get_tick_extents, set_window_size_from_data, setclipbox


struct AxisMap
    fx
    fy
    f
    fxinv
    fyinv
    finv
end


(ax::AxisMap)(p::Point) = ax.f(p)
(ax::AxisMap)(plist::Array{Point}) = ax.f.(plist)


Base.@kwdef mutable struct Ticks
    xticks = missing
    xtickstrings = missing
    yticks = missing
    ytickstrings = missing
end

function ifnotmissingticks(a::Ticks, b::Ticks)
    return Ticks(ifnotmissing(a.xticks, b.xticks),
                 ifnotmissing(a.xtickstrings, b.xtickstrings),
                 ifnotmissing(a.yticks, b.yticks),
                 ifnotmissing(a.ytickstrings, b.ytickstrings))
end



##############################################################################
# axis

# construct f mapping data coords to window coords
function onecoordfunction(width, leftmargin, rightmargin, xmin, xmax)
    t = (width-leftmargin-rightmargin)/(xmax-xmin)
    cx = leftmargin -t*xmin
    return t, cx
end


function AxisMap(w, h, (lmargin, rmargin, tmargin, bmargin), b::Box,
                           axisequal, yoriginatbottom)
    if axisequal
        # aspect ratios
        ar_data = (b.xmax - b.xmin) / (b.ymax - b.ymin)
        ar_window = (w - lmargin - rmargin)/(h - tmargin - bmargin)
        if ar_data > ar_window
            # letterbox format
            # leave axis width as default, and compute height of axis for
            # equal aspect ratio
            axiswidth = w - lmargin - rmargin
            axisheight = axiswidth / ar_data
            tmargin = (h - axisheight)/2
            bmargin = tmargin
        else
            # vertical letterbox
            axisheight = h - tmargin - bmargin
            axiswidth = axisheight * ar_data
            lmargin = (w - axiswidth)/2
            rmargin = lmargin
        end
    end
    tx, cx = onecoordfunction(w, lmargin, rmargin, b.xmin, b.xmax)
    ty, cy = onecoordfunction(h, bmargin, tmargin, b.ymin, b.ymax)
    if yoriginatbottom
        ty = -ty
        cy = h - cy
    end
    qfx = x -> tx * x + cx
    qfy = y -> ty * y + cy
    qfxinv = x -> (x - cx)/tx
    qfyinv = y -> (y - cy)/ty
    qf =  p::Point -> Point(qfx(p.x), qfy(p.y))
    qfinv =  p::Point -> Point(qfxinv(p.x), qfyinv(p.y))
    return AxisMap(qfx, qfy, qf, qfxinv, qfyinv, qfinv)
end




##############################################################################
# ticks

function Ticks(xmin, xmax, ymin, ymax, xidealnumlabels, yidealnumlabels)
    xt = best_ticks(xmin, xmax, xidealnumlabels)
    yt = best_ticks(ymin, ymax, yidealnumlabels)
    xl = best_labels(xt)
    yl = best_labels(yt)
    ticks =  Ticks(xt, xl, yt, yl)
    return  ticks
end

Ticks(b::Box, xidl, yidl) = Ticks(b.xmin, b.xmax, b.ymin, b.ymax, xidl, yidl)


closefloor(x,e) =  floor(x) < floor(x+e) ?  floor(x+e) :  floor(x)
closeceil(x,e) =    ceil(x) > ceil(x-e) ?    ceil(x-e) :   ceil(x)
pospart(x) = x>0 ? x : zero(x)

function score_ticks(x, dmin, dmax, i, exponent, idealnumlabels)
    lspacing = (10.0^exponent) * x[i]
    allowederror = (dmax-dmin)/1000/lspacing
    jmin = Int64(closefloor(dmin/lspacing, allowederror))
    jmax = Int64(closeceil(dmax/lspacing, allowederror))
    nlabels = jmax-jmin+1
    coverage = (dmax-dmin)/(jmax*lspacing-jmin*lspacing)
    simplicity = 1-i/length(x)
    includeszero = jmin*lspacing<=0 && jmax*lspacing>=0
    density = 1-(abs(nlabels-idealnumlabels)/idealnumlabels)
    score =  coverage + simplicity + 2*pospart(density) + includeszero
    return score,jmin,jmax,nlabels
end


function best_ticks(dmin, dmax, idealnumlabels=10)
    if dmax == 0 && dmin == 0
        dmax = 1
    elseif dmax == dmin
        dmax = 1.1*dmin
        dmin = 0.9*dmin
    end
    labels = 0
    bestscore = -1
    x  = [1, 5, 2, 2.5]
    for i = 1:length(x)
        emin = Int64(floor(log10(abs(dmax-dmin)/(20*x[i]))))
        emax = Int64(ceil(log10(abs(dmax-dmin)/(0.5*x[i]))))
        for exponent = emin:emax
            score, jmin, jmax, nlabels = score_ticks(x, dmin, dmax, i, exponent, idealnumlabels)
            if score > bestscore
                labels = collect(jmin:jmax)*x[i]*(10.0^exponent)
                bestscore = score
            end
        end
    end
    if labels == 0
        return [0.0, 1.0]
    end
    return labels
end

best_ticks(x) = best_ticks(minimum(x), maximum(x))


function get_tick_extents(t::Ticks)
    xmin, xmax, ymin, ymax = minimum(t.xticks), maximum(t.xticks), minimum(t.yticks), maximum(t.yticks)
    return Box(xmin, xmax, ymin, ymax)
end



##############################################################################
# labels

num_to_string(x::Float64, precision) = Base.Ryu.writefixed(x, precision)
num_to_string(x::Integer, precision) = Base.Ryu.writefixed(1.0*x, precision)

function labelsequal(x, l)
    for i=1:length(x)
        if x[i] != 0.0 && abs(x[i] - parse(Float64, l[i])) / abs(x[i]) > 1e-12
            return false
        end
    end
    return true
end

# given a list of numbers, convert to a list of strings
function best_labels(x::Array{Integer,1}, suffix = "")
    y = string.(x)
    y[end] *= suffix
    return y
end
    

function best_labels(x::Array{Float64,1}, suffix = "")
    if maximum(abs.(x)) > 10^6 && maximum(x) - minimum(x) > 10^7
        return best_labels(x ./ 10^6, "e6")
    end
    if maximum(abs.(x)) < 10^-6
        return best_labels(x .* 10^6, "e-6")
    end
    for p in 0:20
        plabels = num_to_string.(x, p)
        if labelsequal(x, plabels)
            plabels[end] *= suffix
            return plabels
        end
    end
end

##############################################################################
# axis_builder

#
# AxisStyle specifies how to draw the axis. It
# is set by the user
#
Base.@kwdef mutable struct AxisStyle
    drawbox = false
    edgelinestyle = LineStyle(Color(:black), 2)
    drawaxisbackground = true
    xtickverticaloffset = 16
    ytickhorizontaloffset = -8
    backgroundcolor = Color(:bluegray)
    gridlinestyle = LineStyle(Color(:white), 1)
    fontsize = 13
    fontcolor = Color(:black)
    drawxlabels = true
    drawylabels = true
    drawaxis = true
    drawvgridlines = true
    drawhgridlines = true
    title = ""
end

#
# We use Axis to draw the axis, in addition to the axisstyle.
# Axis also contains information about the window:
#
#   width, height, windowbackgroundcolor, drawbackground,
#
# and information about the axis which is not style
#
#   ticks, box, yoriginatbottom
#
# and the AxisStyle object "as". Note that the AxisStyle object
# is provided by the user, and unchanged, but the ticks, and box
# are computed by the Axis constructor.
#
# yoriginatbottom comes from the AxisOptions, and affects
# both the axis drawing and the axismap.
#
# All of this is necessary to draw the axis.
#
# We use AxisMap to draw the graph on the axis.
#
mutable struct Axis
    width            # in pixels, including margins
    height           # in pixels, including margins
    ax::AxisMap      # provides function mapping data coords to pixels
    box::Box         # extents of the axis in data coordinates
    ticks::Ticks
    as::AxisStyle
    yoriginatbottom
    windowbackgroundcolor
    drawbackground   # bool
end

#
# AxisOptions is passed to the Axis constructor,
# which creates the Axis object above. It contains the style
# information for drawing the axis, in AxisStyle
# and the information used to construct the AxisMap, and the layout
# within the window.
#
# AxisOptions are set by the user
# They are only used to create the Axis object.
#
Base.@kwdef mutable struct AxisOptions
    xmin = -Inf
    xmax = Inf
    ymin = -Inf
    ymax = Inf
    xdatamargin = 0
    ydatamargin = 0
    xwidenfactor = 1
    ywidenfactor = 1
    widthfromdata = 0 
    heightfromdata = 0
    width = 800
    height = 600
    lmargin = 80
    rmargin = 80
    tmargin = 80
    bmargin = 80
    xidealnumlabels = 10
    yidealnumlabels = 10
    yoriginatbottom = true
    axisequal = false
    windowbackgroundcolor = Color(:white)
    drawbackground = true
    drawaxis = true
    ticks = Ticks()
    axisstyle = AxisStyle()
    tickbox = Box()
    axisbox = Box()
end


##############################################################################

function set_window_size_from_data(width, height, b::Box,
                                   (lmargin, rmargin, tmargin, bmargin),
                                   widthfromdata, heightfromdata)
    if widthfromdata != 0
        width = (b.xmax - b.xmin) * widthfromdata + lmargin + rmargin
    end
    if heightfromdata != 0
        height = (b.ymax - b.ymin) * heightfromdata + tmargin + bmargin
    end
    return width, height
end

  
# used when you don't have any data and want to ask
# for specific limits on the axis
fit_box_around_data(p::Missing, box0::Box) = iffinite(box0, Box(0,1,0,1))


function fit_box_around_data(p, box0::Box)
    flattened_data = flat_list_of_points(p)
    truncdata = remove_data_outside_box(flattened_data, box0)
    boxtmp = smallest_box_containing_data(truncdata)
    box1 = iffinite(box0, boxtmp)
end

##############################################################################

function Axis(p, ao::AxisOptions)
    
    ignore_data_outside_this_box = getbox(ao)
    
    # tickbox is set to a box that contains the data
    # so if ignore_data_outside_this_box specifies limits on x,
    # then the data is used to determine limits on y
    # and these limits go into tickbox
    boxtmp = fit_box_around_data(p, ignore_data_outside_this_box)
    tickbox = ifnotmissing(ao.tickbox,
                           scale_box(expand_box(boxtmp, ao.xdatamargin, ao.ydatamargin),
                                     ao.xwidenfactor, ao.ywidenfactor))

    # tickbox used to define the minimum area which the ticks
    # are guaranteed to contain
    # Ticks is a set of ticks chosen to be pretty, and to contain tickbox
    ticks = ifnotmissingticks(ao.ticks, Ticks(tickbox,  ao.xidealnumlabels, ao.yidealnumlabels))

    # axisbox is set to the actual min and max of the values of the ticks
    # and determines the extent of the axis region of the plot
    axisbox = ifnotmissing(ao.axisbox, get_tick_extents(ticks))

    # set window width/height based on axis limits
    # if asked to do so
    wh = set_window_size_from_data(ao.width, ao.height, axisbox, margins(ao),
                                   ao.widthfromdata, ao.heightfromdata)

    ax = AxisMap(wh..., margins(ao), axisbox,
                 ao.axisequal, ao.yoriginatbottom)
  
    axis = Axis(wh..., ax, axisbox, ticks, ao.axisstyle,
                ao.yoriginatbottom, ao.windowbackgroundcolor,
                ao.drawbackground)
    return axis
end

Axis(ao::AxisOptions) = Axis(missing, ao)
    
##############################################################################


function parse_axis_options(; kw...)
    ao = AxisOptions()
    setoptions!(ao, "", kw...)
    setoptions!(ao, "axisoptions_", kw...)
    setoptions!(ao.tickbox, "tickbox_", kw...)
    setoptions!(ao.axisbox, "axisbox_", kw...)
    setoptions!(ao.ticks, "ticks_", kw...)
    setoptions!(ao.axisstyle, "axisstyle_", kw...)
    return ao
end
    

Axis(p; kw...) = Axis(p, parse_axis_options(; kw...))

Axis(; kw...) = Axis(missing; kw...)

##############################################################################
# draw_axis


function drawaxis(ctx, axismap, ticks, box, as::AxisStyle)
    if !as.drawaxis
        return
    end
    xticks = ticks.xticks
    xtickstrings = ticks.xtickstrings
    yticks = ticks.yticks
    ytickstrings = ticks.ytickstrings
    xmin, xmax, ymin, ymax = box.xmin, box.xmax, box.ymin, box.ymax
    @plotfns(axismap)
    if as.drawaxisbackground
        Cairo.rectangle(ctx, rfx(xmin), rfy(ymin), rfx(xmax)-rfx(xmin),
                        rfy(ymax)-rfy(ymin))
        source(ctx, as.backgroundcolor)
        Cairo.fill(ctx)
    end
    Cairo.set_line_width(ctx, 1)
    for i=1:length(xticks)
        xt = xticks[i]
        if as.drawvgridlines
            if xt>xmin && xt<xmax
                Cairo.move_to(ctx, rfx(xt)-0.5, rfy(ymax))  
                Cairo.line_to(ctx, rfx(xt)-0.5, rfy(ymin))
                set_linestyle(ctx, as.gridlinestyle)
                Cairo.stroke(ctx)
            end
        end
        if xt>=xmin && xt<=xmax
            if as.drawxlabels
                text(ctx, Point(fx(xt), fy(ymin) + as.xtickverticaloffset),
                     as.fontsize, as.fontcolor, xtickstrings[i];
                     horizontal = "center")
            end
        end
    end
    for i=1:length(yticks)
        yt = yticks[i]
        if as.drawhgridlines
            if yt>ymin && yt<ymax
                Cairo.move_to(ctx, rfx(xmin), rfy(yt)-0.5) 
                Cairo.line_to(ctx, rfx(xmax), rfy(yt)-0.5)
                set_linestyle(ctx, as.gridlinestyle)
                Cairo.stroke(ctx)
            end
        end
        if yt>=ymin && yt<=ymax
            if as.drawylabels
                text(ctx, Point(fx(xmin) + as.ytickhorizontaloffset, fy(yt)),
                     as.fontsize, as.fontcolor, ytickstrings[i];
                     horizontal = "right", vertical = "center")
            end
        end
    end
    if as.drawbox
        Cairo.move_to(ctx, rfx(xmin)-0.5, rfy(ymax)-0.5)  #tl
        Cairo.line_to(ctx, rfx(xmin)-0.5, rfy(ymin)+0.5)  #bl
        Cairo.line_to(ctx, rfx(xmax)+0.5, rfy(ymin)+0.5)  #br
        Cairo.line_to(ctx, rfx(xmax)+0.5, rfy(ymax)-0.5)  #tr
        Cairo.close_path(ctx)
        set_linestyle(ctx, as.edgelinestyle)
        Cairo.stroke(ctx)
    end
    text(ctx, Point(fx((xmin+xmax)/2), fy(ymax) + 15), as.fontsize, as.fontcolor, as.title;
         horizontal = "center")
    
end

##############################################################################

# also draw background
function drawaxis(ctx, axis::Axis)
    if axis.drawbackground
        rect(ctx, Point(0,0), Point(axis.width, axis.height); fillcolor=axis.windowbackgroundcolor)
    end
    drawaxis(ctx, axis.ax, axis.ticks, axis.box, axis.as)
end

function setclipbox(ctx::CairoContext, axis::Axis)
    setclipbox(ctx, axis.ax, axis.box)
end

##############################################################################

end

