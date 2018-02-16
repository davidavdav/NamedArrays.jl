## namedarraytypes.jl.
## (c) 2013--2018 David A. van Leeuwen

## Julia type that implements a drop-in replacement of Array with named dimensions.

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

## DT is a tuple of Dicts, characterized by the types of the keys.
## This way NamedArray is dependent on the dictionary type of each dimensions.
## The inner constructor checks for consistency, the values must all be 1:d
if !isdefined(:NamedArray)

mutable struct NamedArray{T,N,AT,DT} <: AbstractArray{T,N}
    array::AT
    dicts::DT
    dimnames::NTuple{N, Any}
    function (::Type{S}){S<:NamedArray, T, N}(array::AbstractArray{T, N}, dicts::NTuple{N, OrderedDict}, dimnames::NTuple{N, Any})
        size(array) == map(length, dicts) || error("Inconsistent dictionary sizes")
        new{T,N,typeof(array),typeof(dicts)}(array, dicts, dimnames)
    end
end


## a type that negates any index
struct Not{T}
    index::T
end

NamedVector{T} = NamedArray{T,1}
NamedMatrix{T} = NamedArray{T,2}
NamedVecOrMat{T} = Union{NamedVector{T},NamedMatrix{T}}
ArrayOrNamed{T,N} = Union{Array{T,N}, NamedArray{T,N,Array}}

if isdefined(Base, :RowVector)
    NamedRowVector{T,RVT<:AbstractVector} = NamedArray{T,2,RowVector{T,RVT}}
end

end
