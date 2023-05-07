
module TestSet

using PlotKitCairo

plotpath(x) = joinpath(tempdir(), x)

using Test
include("testset.jl")
end


using .TestSet
TestSet.main()



