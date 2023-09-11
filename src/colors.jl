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


module Colors

using LinearAlgebra
using ..Tools

export Color, RGBAColor, RGBColor, colormap, hadamard, hexcol, interp, default_colors
    
abstract type Color end

struct RGBColor <: Color
    r::Float64
    g::Float64
    b::Float64
end

struct RGBAColor <: Color
    r::Float64
    g::Float64
    b::Float64
    a::Float64
end

eval(makevector(RGBColor))
eval(makevector(RGBAColor))

Color(r,g,b) = RGBColor(r,g,b)
Color(r,g,b,a) = RGBAColor(r,g,b,a)
Color(x::Tuple{Any,Any,Any}) = RGBColor(x)
Color(x::Tuple{Any,Any,Any,Any}) = RGBAColor(x)
Color(x::Symbol) = color_names[x]


##############################################################################
# color functions

"""
    hexcol(c::UInt32)

Return the color corresponding to a 6-digit hex number 
"""
function hexcol(c::UInt32)
    r = c >>16 & 0xff
    g = c >>8 & 0xff
    b = c  & 0xff
    return RGBColor(r/255, g/255, b/255)
end

"""
    corput_sequence(n)

Return the Van der Corput low-discrepancy sequence, a permutation of 0...2^n-1.
"""
function corput_sequence(n)
    f(x) = parse(Int, reverse(string(x, base=2, pad=n)), base=2)
    m = (1<<n)-1
    return [f(x) for x=0:m]
end

"""
    hsvtorgb(h,s,v)

Convert h,s,v color to r,g,b
"""
function Color_from_hsv(h,s,v)
    cube_x=[ 1 1 0 0 0 1 1
             0 1 1 1 0 0 0
             0 0 0 1 1 1 0 ]
    if (h==1)
        h=0;
    end
    seg=Int(floor(h*6)+1)
    extremals = hcat(cube_x[:,seg],cube_x[:,seg+1],[1;1;1])
    l = zeros(3,1);
    l[3] = 1-s
    l[2] = (6 * h + 1 - seg)*(1 - l[3])
    l[1] = 1 - l[2] - l[3]
    y = extremals * l
    y = y*v
    return RGBColor(y[1], y[2], y[3])
end

"""
    rgbtohsv(r,g,b)

Convert r,g,b to h,s,v color.
"""
function hsv(c::RGBColor)
    x = [c.r, c.g, c.b]
    val, i = max(x)
    if (val==0)
        return (0, 0, 0)
    end
    x = x / val
    r = x[1]
    g = x[2]
    b = x[3]
    # Now we have normalized by the infinity norm,
    # so x is on the surface of a unit cube.
    # x is on one of three faces of this cube, since x >= 0

    # Projecting this cube onto the plane perpendicular
    # to [1;1;1] results in a hexagon.

    # Each of the three faces of the cube projects to two segments 
    # of the hexagon.
    cube_x=[ 1 1 0 0 0 1 1
             0 1 1 1 0 0 0
             0 0 0 1 1 1 0 ]

    # segments 6 and 1 (i.e., the r=1 face)
    if (i == 1)
        if (g < b)
            # segment 6
            seg = 6
        else
            # segment 1
            seg = 1
        end
    end

    # segments 2 and 3 (i.e., the g=1 face)
    if (i == 2)
        if (b < r)
            # segment 2
            seg = 2
        else
            # segment 3
            seg = 3
        end
    end
    # segments 4 and 5 (i.e., the b=1 face)
    if (i == 3)
        if (r < g)
            # segment 4
            seg = 4
        else
            # segment 5
            seg = 5
        end
    end

    extremals = [ cube_x[:, seg], cube_x[:,seg+1], [1;1;1] ]

    # now express x (which is on the interior of a segment)
    # as a linear combination of the segment's extremal vectors
    l = extremals\x

    # and the saturation is 1 - the coefficient of (1,1,1)
    sat = 1 - l[3]

    # the hue parameterizes the distance around the boundary
    # (similar to polar coordinates)
    if l[1] + l[2] < 1e-10
        # singular case
        hue = 0
    else
        hue = (l[2] / (l[1] + l[2]) + seg - 1) / 6 
    end
    return (hue, sat, val)
end

"""
    make_pseudo_random_hues()

Return a pseudo-random list of colors, at fixed saturation and value.
"""
function make_pseudo_random_hues()
    hues = corput_sequence(8)
    cmap = [Color_from_hsv(h/255, 0.9, 0.9) for h in hues]
end

"""
    make_pseudo_random_colors()

Return a pseudo-random list of colors.
"""
function make_pseudo_random_colors()
    vals = [255, 128, 192,  160,  96,  224]
    sathues = [255, 128,  64,  192,  32,  160,  96,  224]
    cmap = [Color_from_hsv(h/255, s/255, v/255) for v in vals for s in sathues for h in sathues]
    return cmap
end


function css_colors()
    tomato = hexcol(0xFF6347)
    yellowgreen = hexcol(0x9ACD32)
    steelblue = hexcol(0x4682B4)
    gold = hexcol(0xDAA520)
    darkred = hexcol(0x8b0000)
    darkgreen = hexcol(0x006400)
    midnightblue = hexcol(0x191970)
    darkorange = hexcol(0xff8c00)
    salmon = hexcol(0xfa8072)
    lightgreen = hexcol(0x90ee90)
    lightblue = hexcol(0xadd8e6)
    moccasin = hexcol(0xFFE4B5)
    return [tomato, yellowgreen, steelblue, gold,
            darkred, darkgreen, midnightblue, darkorange,
            salmon, lightgreen, lightblue, moccasin]
end

"""
    colormap(i)

Return the i'th color in the default colormap
"""
colormap(i) = default_colors[i]

"""
    colormap(i,j)

Return the i'th color in the default colormap, darkened by amount j.
"""
colormap(i,j) = 0.7 ^ (j-1) * colormap(i)

const default_colors = []

function __init__()
    append!(default_colors, css_colors())
    append!(default_colors, make_pseudo_random_colors())
end

const color_names = Dict(
    :white   => Color(1.0, 1.0, 1.0),
    :black   => Color(0.0, 0.0, 0.0),
    :bluegray => Color(0.917, 0.917, 0.949),
    :red => Color(1,0,0),
    :green => Color(0,1,0),
    :blue => Color(0,0,1),
    :cyan => Color(0,1,1),
    :magenta => Color(1,0,1),
    :yellow => Color(1,1,0),
)


end
