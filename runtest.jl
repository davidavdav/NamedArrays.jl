#!/usr/bin/env julia
# include("src/NamedArrays.jl")
using NamedArrays
#using Base.Test
#using OrderedCollections
#using Combinatorics

cd("test")

#include("test/rearrange.jl")

include("test/runtests.jl")
