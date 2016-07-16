## NamedArrays.jl
## (c) 2013--2014 David A. van Leeuwen

## Julia type that implements a drop-in replacement of Array with named dimensions.

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

VERSION >= v"0.4.0-dev+6521" && __precompile__()

module NamedArrays

using Compat
using DataStructures

export NamedArray, NamedVector, NamedMatrix, Not

## type definition
include("namedarraytypes.jl")

export allnames, dimnames, setnames!, setdimnames!, array

include("compat.jl")
include("constructors.jl")
include("arithmetic.jl")
include("base.jl")
include("changingnames.jl")
include("index.jl")
include("keepnames.jl")
include("names.jl")
include("rearrange.jl")
include("show.jl")
include("convert.jl")

end
