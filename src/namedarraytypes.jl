## namedarraytypes.jl.
## (c) 2013 David A. van Leeuwen

## Julia type that implements a drop-in replacement of Array with named dimensions.

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

using Compat

## DT is a tuple of Dicts, characterized by the types of the keys.
## This way NamedArray is dependent on the dictionary type of each dimensions.
## The inner constructor checks for consistency, the values must all be 1:d
if !isdefined(:NamedArray)

type NamedArray{T,N,AT,DT} <: AbstractArray{T,N}
    array::AT
    dicts::DT
    dimnames::NTuple{N, Any}
    function (::Type{S}){S<:NamedArray, T, N}(array::AbstractArray{T, N}, dicts::NTuple{N, OrderedDict}, dimnames::NTuple{N, Any})
        size(array) == map(length, dicts) || error("Inconsistent dictionary sizes")
#        for (d,dict) in zip(size(array),dicts)
#            Set(values(dict)) == Set(1:d) || error("Inconsistent values in dict")
#        end
        new{T,N,typeof(array),typeof(dicts)}(array, dicts, dimnames)
    end
end


## a type that negates any index
immutable Not{T}
    index::T
end

@compat NamedVector{T} = NamedArray{T,1}
@compat NamedMatrix{T} = NamedArray{T,2}
@compat NamedVecOrMat{T} = Union{NamedVector{T},NamedMatrix{T}}
@compat ArrayOrNamed{T,N} = Union{Array{T,N}, NamedArray{T,N,Array}}

end
