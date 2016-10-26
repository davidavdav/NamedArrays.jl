using NamedArrays
using Compat
using Base.Test
using DataStructures

if VERSION < v"0.5.0-dev"
	view(n, args...) = getindex(n, args...)
end

include("test.jl")
