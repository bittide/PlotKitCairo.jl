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

module Drawing

using ..Cairo
using ..Colors
using ..VeryBasic
using ..Basic
using ..CairoTools
using ..AxisTools

export setclipbox

    
function AxisTools.setclipbox(ctx::CairoContext, ax::AxisMap, box)
    @plotfns ax
    xmin, xmax, ymin, ymax = box.xmin, box.xmax, box.ymin, box.ymax
    Cairo.rectangle(ctx, rfx(xmin), rfy(ymin), rfx(xmax)-rfx(xmin),
                    rfy(ymax)-rfy(ymin))
    Cairo.clip(ctx)
    Cairo.new_path(ctx)
end


##############################################################################
# from tools

# TODO: circle radius shouldbe in axis coords too? What about non-uniform x,y scaling

# does this:
#
# CairoTools.line(ax::AxisMap, ctx, p, args...)
#    = CairoTools.line(ctx, ax(p), args...)
#
for f in (:line, :circle, :text)
    @eval function CairoTools.$f(ax::AxisMap, ctx::CairoContext, p, args...; kwargs...)
        CairoTools.$f(ctx::CairoContext, ax(p), args...; kwargs...)
    end
end


# for functions with two arguments of type Point
for f in (:line,)
    @eval function CairoTools.$f(ax::AxisMap, ctx::CairoContext, p::Point, q::Point, args...; kwargs...)
        CairoTools.$f(ctx::CairoContext, ax(p), ax(q), args...; kwargs...)
    end
end


# for functions with four arguments of type Point
for f in (:curve,)
    @eval function CairoTools.$f(ax::AxisMap, ctx::CairoContext, p, q, r, s, args...; kwargs...)
        CairoTools.$f(ctx::CairoContext,
                      ax(p), ax(q), ax(r), ax(s), args...; kwargs...)
    end
end


##############################################################################
# higher level drawing


function CairoTools.drawimage(ax::AxisMap, ctx, pik::Pik, b::Box)
    x1 = ax.fx(b.xmin)
    x2 = ax.fx(b.xmax)
    y1 = ax.fy(b.ymin)
    y2 = ax.fy(b.ymax)
    b2 = Box(min(x1, x2), max(x1, x2), min(y1, y2), max(y1,y2))
    drawimage(ctx, pik, b2)
end


end
