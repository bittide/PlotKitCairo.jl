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

module Layout

using ..Cairo
using ..Drawables: Drawable, RecorderDrawable
using ..BoxPoints: Point

export hbox, vbox, offset, hvbox, stack
    
# functions for laying out drawables
function hbox(r1::T1, r2::T2) where {T1<:Drawable, T2<:Drawable}
    width = r1.width + r2.width
    height = max(r1.height, r2.height)
    r = RecorderDrawable(width, height)
    paint(r, r1, Point(0, 0))
    paint(r, r2, Point(r1.width, 0))
    return r
end

function vbox(r1::T1, r2::T2) where {T1<:Drawable, T2<:Drawable}
    width = max(r1.width, r2.width)
    height = r1.height + r2.height
    r = RecorderDrawable(width, height)
    paint(r, r1, Point(0, 0))
    paint(r, r2, Point(0, r1.height))
    return r
end


# position r2 relative to r1
function offset(r1::T1, r2::T2, dx, dy) where {T1<:Drawable, T2<:Drawable}
    left = min(0, dx)
    top = min(0, dy)
    right = max(r1.width, r2.width + dx)
    bottom = max(r1.height, r2.height + dy)
    width = right - left
    height = bottom - top
    r = RecorderDrawable(width, height)
    paint(r, r1, Point(-left, -top))
    paint(r, r2, Point(dx - left, dy - top))
    return r
end

vbox(f, g::Missing) = f
vbox(f::Missing, g) = g
hbox(f, g::Missing) = f
hbox(f::Missing, g) = g

vbox(fs::Array) = reduce(vbox, fs)
hbox(fs::Array) = reduce(hbox, fs)

function hvbox(farray)
    rows = [hbox(collect(r)) for r in eachrow(farray)]
    return vbox(collect(rows))
end

function stack(x, ncols)
    nrows = Int(ceil(length(x)/ncols))
    A = Array{Any,2}(missing, ncols, nrows)
    for i=1:length(x)
        A[i] = x[i]
    end
    B = permutedims(A, (2,1))
    return B
end


end




