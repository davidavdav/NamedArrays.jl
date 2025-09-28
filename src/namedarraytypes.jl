## namedarraytypes.jl.
## (c) 2013--2018 David A. van Leeuwen

## Julia type that implements a drop-in replacement of Array with named dimensions.

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

## DT is a tuple of Dicts, characterized by the types of the keys.
## This way NamedArray is dependent on the dictionary type of each dimensions.
## The inner constructor checks for consistency, the values must all be 1:d

using OrderedCollections: OrderedDict

if ! @isdefined NamedArray

"""
    Name(name)

Wrapper type to ensure a name is used in an index, and not the numeric value.

# Example
```jldoctest
julia> n = NamedArray([1 2 3; 4 5 6], ([2, 4], [3, 6, 9]))
2×3 Named Matrix{Int64}
A ╲ B │ 3  6  9
──────┼────────
2     │ 1  2  3
4     │ 4  5  6

julia> n[2, 3]
6

julia> n[Name(2), Name(3)]
1

```
"""
struct Name{T}
    name::T
end

Base.show(io::IO, name::Name) = print(io, name.name)

function checkdict(dict::AbstractDict)
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

mutable struct NamedArray{T,N,AT,DT} <: AbstractArray{T,N}
    array::AT
    dicts::DT
    dimnames::NTuple{N, Any}
    function (::Type{S})(array::AbstractArray{T, N},
                         dicts::NTuple{N, OrderedDict},
                         dimnames::NTuple{N, Any}) where {S<:NamedArray, T, N}
        size(array) == map(length, dicts) || error("Inconsistent dictionary sizes")
        ## dicts = map(dict -> checkdict(dict), dicts)
        new{T, N, typeof(array), typeof(dicts)}(array, dicts, dimnames)
    end
end

const NamedVector{T} = NamedArray{T,1}
const NamedMatrix{T} = NamedArray{T,2}
const NamedVecOrMat{T} = Union{NamedVector{T},NamedMatrix{T}}
const ArrayOrNamed{T,N} = Union{Array{T,N}, NamedArray{T,N,Array}}

if @isdefined RowVector
    NamedRowVector{T,RVT<:AbstractVector} = NamedArray{T,2,RowVector{T,RVT}}
end

end
