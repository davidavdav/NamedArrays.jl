## runtests.jl
## (c) 2013--2014 David A. van Leeuwen

## Julia type that implements a drop-in replacement of Array with named dimensions.

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

using NamedArrays
using Test
using DataStructures
using Combinatorics
using LinearAlgebra
using SparseArrays
using DelimitedFiles
using Statistics
using Random

using KahanSummation

include("test.jl")
