## NamedArrays.jl
## (c) 2013--2018 David A. van Leeuwen

## Julia type that implements a drop-in replacement of Array with named dimensions.

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

module NamedArrays

using Requires
using Random
using Statistics
using SparseArrays
using DelimitedFiles
using DataStructures
using LinearAlgebra

export NamedArray, NamedVector, NamedMatrix, Name, Not

## type definition
include("namedarraytypes.jl")

export names, dimnames, defaultnames, setnames!, setdimnames!, array

include("constructors.jl")
include("arithmetic.jl")
include("linearalgebra.jl")
include("base.jl")
include("changingnames.jl")
include("index.jl")
include("keepnames.jl")
include("names.jl")
include("rearrange.jl")
include("show.jl")
include("convert.jl")


function __init__()
    @require KahanSummation="8e2b3108-d4c1-50be-a7a2-16352aec75c3" begin

        # NOTE: KahanSummation do not support Julia 0.7 dims keyword argument at the moment

        ## rename a dimension
        function KahanSummation.cumsum_kbn(a::NamedArray, dims::Integer)
            NamedArrays.fan(KahanSummation.cumsum_kbn, "cumsum_kbn", a, dims)
        end
    end
end

end
