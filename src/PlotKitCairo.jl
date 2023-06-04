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

module PlotKitCairo

using Cairo
using LinearAlgebra

##############################################################################
# submodules

# The included modules are sorted by dependency.

include("tools.jl")
using .Tools

include("colors.jl")
using .Colors

include("boxpoints.jl")
using .BoxPoints

include("curves.jl") 
using .Curves

include("drawables.jl")
using .Drawables

include("layout.jl")
using .Layout

include("images.jl")
using .Images

include("cairotools.jl")
using .CairoTools


##############################################################################
function reexport(m)
    for a in names(m)
        eval(Expr(:export, a))
    end
end


reexport(Tools)
reexport(Colors)
reexport(BoxPoints)
reexport(Curves)
reexport(Drawables)
reexport(Layout)
reexport(Images)
reexport(CairoTools)




end

