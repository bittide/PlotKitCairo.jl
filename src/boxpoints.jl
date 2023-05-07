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


module BoxPoints

using LinearAlgebra
using ..Tools

export Box, Point, expand_box, inbox, scale_box

##############################################################################
# points

struct Point
    x::Number
    y::Number
end

eval(makevector(Point))

function Base.:*(A::Matrix, b::Point) 
    return  Point(A[1,1]*b.x + A[1,2]*b.y,  A[2,1]*b.x + A[2,2]*b.y)
end


##############################################################################
# boxes

"""
    struct Box
        xmin, xmax, ymin, ymax
    end

"""
mutable struct Box
    xmin
    xmax
    ymin
    ymax
end


Box(; xmin=missing, xmax=missing, ymin=missing, ymax=missing) = Box(xmin, xmax, ymin, ymax)

# just specify topleft
Box(xmin, ymin; width = 0, height = 0) = Box(xmin, xmin + width,
                                             ymin, ymin + height)

Box(tl::Point, br::Point) = Box(tl.x, br.x, tl.y, br.y)

Base.copy(a::Box) =  Box(a.xmin, a.xmax, a.ymin, a.ymax)

function expand_box(b::Box, dx, dy)
    return Box(b.xmin - dx, b.xmax + dx, b.ymin - dy, b.ymax + dy)
end

function scale_box(b::Box, rx, ry)
    width = b.xmax - b.xmin
    height = b.ymax - b.ymin
    cx = (b.xmax + b.xmin) / 2
    cy = (b.ymax + b.ymin) / 2
    return Box(cx - rx*width/2, cx + rx*width/2, cy - ry*height/2, cy + ry*height/2)
end

inbox(p::Point, b::Box) = (b.xmin <= p.x <= b.xmax) && (b.ymin <= p.y <= b.ymax)

function Base.getproperty(b::Box, s::Symbol)
    if s == :width
        return getfield(b, :xmax) - getfield(b, :xmin)
    elseif s == :height
        return getfield(b, :ymax) - getfield(b, :ymin)
    elseif s == :center
        return Point((getfield(b, :xmin) + getfield(b, :xmax))/2,
                     (getfield(b, :ymin) + getfield(b, :ymax))/2)
    elseif s == :topleft
        return Point(getfield(b, :xmin), getfield(b, :ymin))
    elseif s == :topright
        return Point(getfield(b, :xmax), getfield(b, :ymin))
    elseif s == :botright
        return Point(getfield(b, :xmax), getfield(b, :ymax))
    elseif s == :botleft
        return Point(getfield(b, :xmin), getfield(b, :ymax))
    elseif s == :corners
        return (Point(getfield(b, :xmin), getfield(b, :ymin)),
                Point(getfield(b, :xmin), getfield(b, :ymax)),
                Point(getfield(b, :xmax), getfield(b, :ymax)),
                Point(getfield(b, :xmax), getfield(b, :ymin)))
    elseif s == :size
        return Point(getfield(b, :xmax) - getfield(b, :xmin),
                     getfield(b, :ymax) - getfield(b, :ymin))
    else
        return getfield(b, s)
    end
end
    
##############################################################################


end





