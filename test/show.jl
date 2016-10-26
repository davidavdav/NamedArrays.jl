## show.jl
## (c) 2013--2014 David A. van Leeuwen

## various tests for show()

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution
println("show,")

include("init-namedarrays.jl")

if VERSION >= v"0.4.0-dev"
    println(NamedArray(Array{Int}()))
end
println(NamedArray([]))
print(n)
println()
show(n)
show(STDOUT, MIME"text/plain"(), n)
show(NamedArray(randn(2,1000)))
show(NamedArray(randn(1000,2)))
show(NamedArray(randn(1000)))

zo = [0,1]
println(NamedArray(rand(2,2,2), (zo, zo, zo), ("base", "zero", "indexing")))
for ndim in 1:5
    println(NamedArray(rand(fill(2,ndim)...)))
end
## various singletons
println(NamedArray(rand(1,2,2)))
println(NamedArray(rand(2,1,2)))
println(NamedArray(rand(2,2,1)))

nms = [string(hash(i)) for i in 1:1000]
show(NamedArray(sprand(1000,1000, 1e-4), (nms, nms)))
