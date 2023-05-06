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


module Basic

using ..VeryBasic

export @plotfns, expand_box, flat_list_of_points, getbox, iffinite, ifnotmissing, margins, overdata, remove_data_outside_box, scale_box, setoptions!, smallest_box_containing_data



##############################################################################

getbox(a) = Box(a.xmin, a.xmax, a.ymin, a.ymax)

# should be axfns
macro plotfns(ax)
    return esc(quote
               rfx = x -> round($ax.fx(x))
               rfy = y -> round($ax.fy(y))
               rf = p -> (rfx(p[1]), rfy(p[2]))
               fx = x -> $ax.fx(x)
               fy = y -> $ax.fy(y)
               f = p::Point -> Point(fx(p.x), fy(p.y))
    end)
end

ifnotnothing(x::Nothing, y) = y
ifnotnothing(x, y) = x

ifnotmissing(x::Missing, y) = y
ifnotmissing(x, y) = x

function ifnotmissing(a::Box, b::Box)
    return Box(ifnotmissing(a.xmin, b.xmin),
               ifnotmissing(a.xmax, b.xmax),
               ifnotmissing(a.ymin, b.ymin),
               ifnotmissing(a.ymax, b.ymax))
end

margins(a) = (a.lmargin, a.rmargin, a.tmargin, a.bmargin)

##############################################################################
# lists of points

# if x = [p1,p2,p3]  returns x
# if x = [ [p1,p2],[p3,p4,p5]] returns [p1,p2,p3,p4,p5]
#
# should work for arbitrary dimensional array
flat_list_of_points(x::Vector{Point}) = x
function flat_list_of_points(slist)
    # nomissing is a list whoses elements are Vector{Point}
    nomissing = Vector{Point}[series for series in skipmissing(slist)]
    # flat is a Vector{Point}
    flat = reduce(vcat, nomissing)
end





##############################################################################
function iffinite(r::Number, d::Number)
    if isfinite(r)
        return r
    end
    return d
end

# if requested limits are finite, use them
function iffinite(a::Box, b::Box)
    xmin = iffinite(a.xmin, b.xmin)
    xmax = iffinite(a.xmax, b.xmax)
    ymin = iffinite(a.ymin, b.ymin)
    ymax = iffinite(a.ymax, b.ymax)
    return Box(xmin, xmax, ymin, ymax)
end

remove_data_outside_box(plist, b::Box) = Point[p for p in plist if inbox(p, b)]

function smallest_box_containing_data(plist)
    xmin = minimum(a.x for a in plist)
    xmax = maximum(a.x for a in plist)
    ymin = minimum(a.y for a in plist)
    ymax = maximum(a.y for a in plist)
    return Box(xmin, xmax, ymin, ymax)
end

##############################################################################
# keyword args

function symsplit(s::Symbol, a::String)
    n = length(a)
    st = string(s)
    if length(st) > n && st[1:length(a)] == a
        return true, Symbol(st[length(a)+1:end])
    end
    return false, :nosuchsymbol
end

function setoptions!(d, prefix, kwargs...)
    for (key, value) in kwargs
        match, tail = symsplit(key, prefix)
        if match && tail in fieldnames(typeof(d))
            setfield!(d, tail, value)
        end
    end
end

end
