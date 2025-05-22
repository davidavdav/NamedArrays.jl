## NamedArrays.jl
## (c) 2013--2018 David A. van Leeuwen

## Julia type that implements a drop-in replacement of Array with named dimensions.

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

module NamedArrays

using Requires
import InvertedIndices.Not
using Random
using Statistics
using SparseArrays
using DelimitedFiles
using DataStructures
using LinearAlgebra

export NamedArray, NamedVector, NamedMatrix, Name, Not

## type definition
include("namedarraytypes.jl")

export names, dimnames, defaultnames, setnames!, setdimnames!, array, enamerate

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
include("iterators.jl")


function __init__()
    @require KahanSummation="8e2b3108-d4c1-50be-a7a2-16352aec75c3" begin

        # NOTE: KahanSummation does not support Julia 0.7 dims keyword argument at the moment

        ## rename a dimension
        function KahanSummation.cumsum_kbn(a::NamedArray; dims::Integer)
            NamedArrays.fan(KahanSummation.cumsum_kbn, "cumsum_kbn", a; dims=dims)
        end
    end

    @require AxisArrays="39de3d68-74b9-583c-8d2d-e117c070f3a9" begin

        ## constructor for AxisArray
        function NamedArray(axisarray::AxisArrays.AxisArray{T, N, D, Ax}) where {T, N, D, Ax}
            axes = AxisArrays.axes(axisarray)
            dimlabels = ntuple(i -> first(AxisArrays.axisvalues(axes[i])), N)
            dimnames = ntuple(i -> first(AxisArrays.axisnames(axes[i])), N)
            return NamedArray(axisarray.data; names=dimlabels, dimnames=dimnames)
        end
    end
end

end
