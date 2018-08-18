## NamedArrays.jl
## (c) 2013--2018 David A. van Leeuwen

## Julia type that implements a drop-in replacement of Array with named dimensions.

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

module NamedArrays

using Random
using Statistics
using SparseArrays
using DelimitedFiles
using DataStructures

export NamedArray, NamedVector, NamedMatrix, Name, Not

## type definition
include("namedarraytypes.jl")

export names, dimnames, defaultnames, setnames!, setdimnames!, array

include("constructors.jl")
#include("arithmetic.jl")
include("base.jl")
include("changingnames.jl")
include("index.jl")
include("keepnames.jl")
include("names.jl")
include("rearrange.jl")
include("show.jl")
include("convert.jl")

end
