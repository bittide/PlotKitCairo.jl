

#
# run using Pkg.test("PlotKitCairo")
#
#
# or using
#
#  cd PlotKitCairo.jl/test
#  julia
#  include("runtests.jl")
#
#
module TestSet

using PlotKitCairo

plotpath(x) = joinpath(tempdir(), x)

using Test
include("testset.jl")
end


using .TestSet
TestSet.main()



