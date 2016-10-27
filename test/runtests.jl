## runtests.jl
## (c) 2013--2014 David A. van Leeuwen

## Julia type that implements a drop-in replacement of Array with named dimensions.

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

using NamedArrays
using Base.Test
using DataStructures

if VERSION < v"0.5.0-dev"
	view(n, args...) = getindex(n, args...)
end

include("test.jl")
