## namedarraytypes.jl.
## (c) 2013--2018 David A. van Leeuwen

## Julia type that implements a drop-in replacement of Array with named dimensions.

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

## DT is a tuple of Dicts, characterized by the types of the keys.
## This way NamedArray is dependent on the dictionary type of each dimensions.
## The inner constructor checks for consistency, the values must all be 1:d

using DataStructures: OrderedDict

if !isdefined(:NamedArray)

struct Name{T}
    name::T
end

Base.show(io::IO, name::Name) = print(io, name.name)

function checkdict(dict::Associative)
    pairs = Pair[]
    union = Union{}
    n = length(dict)
    covered = falses(n)
    for (key, value) in dict
        if isa(key, Integer)
            key = Name(key)
        end
        union = Union{union, typeof(key)}
        push!(pairs, key => value)
        if isa(value, Integer) && 1 ≤ value ≤ n
            covered[value] = true
        end
    end
    all(covered) || error("Not all target indices are covered")
    return OrderedDict{union, Int}(pairs)
end

mutable struct NamedArray{T,N,AT} <: AbstractArray{T,N}
    array::AT
    dicts::NTuple{N, OrderedDict}
    dimnames::NTuple{N, Any}
    function (::Type{S}){S<:NamedArray, T, N}(array::AbstractArray{T, N}, dicts::NTuple{N, OrderedDict}, dimnames::NTuple{N, Any})
        size(array) == map(length, dicts) || error("Inconsistent dictionary sizes")
        ## dicts = map(dict -> checkdict(dict), dicts)
        new{T, N, typeof(array)}(array, dicts, dimnames)
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
