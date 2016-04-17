#!/usr/bin/env julia
include("src/NamedArrays.jl")
using NamedArrays

cd("test")
include("test/runtests.jl")
