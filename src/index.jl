## index.jl getindex and setindex methods for NamedArray
## (c) 2013--2016 David A. van Leeuwen

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

import Base: getindex

## from subarray.jl
getindex(n::NamedVector, ::Colon) = n
getindex(n::NamedArray, ::Colon) = n.array[:]

## special 0-dimensional case
getindex{T}(n::NamedArray{T,0}, i::Real) = getindex(n.array, i)

@inline function getindex{T,N}(n::NamedArray{T,N}, I::Vararg{Any,N})
    namedgetindex(n, map((d,i)->indices(d, i), n.dicts, I)...)
end
Base.view{T,N}(n::NamedArray{T,N}, I::Vararg{Union{AbstractArray,Colon,Real},N}) = namedgetindex(n, map((d,i)->indices(d, i), n.dicts, I)...; useview=true)
Base.view{T,N}(n::NamedArray{T,N}, I::Vararg{Any,N}) = namedgetindex(n, map((d,i)->indices(d, i), n.dicts, I)...; useview=true)

## indices(::Associative, index) converts any type `index` to Integer

## single index
indices{K<:Real,V<:Integer}(dict::Associative{K,V}, i::K) = dict[i]
@inline indices{K,V<:Integer}(dict::Associative{K,V}, i::Real) = Base.to_index(i)
@inline indices{K,V<:Integer}(dict::Associative{K,V}, i::K) = dict[i]

## ambiguity if dict key is CartesionIndex, this should never happen
indices{K<:CartesianIndex,V<:Integer}(dict::Associative{K,V}, i::K) = dict[i]
indices(dict::Associative, ci::CartesianIndex) = ci

## multiple indices
## the following two lines are partly because of ambiguity
indices{T<:Integer,V<:Integer}(dict::Associative{T,V}, i::AbstractArray{T}) = [dict[k] for k in i]
indices{T<:Real,V<:Integer}(dict::Associative{T,V}, i::AbstractArray{T}) = [dict[k] for k in i]
indices{T<:Integer,K,V<:Integer}(dict::Associative{K,V}, i::AbstractArray{T}) = i
indices{K,V<:Integer}(dict::Associative{K,V}, i::AbstractArray{K}) = [dict[k] for k in i]
## in 0.4, we need to take care of : ourselves it seems
indices{K,V<:Integer}(dict::Associative{K,V}, ::Colon) = collect(1:length(dict))

## negation
indices{K<:Not,V<:Integer}(dict::Associative{K,V}, i::K) = dict[i]
indices(dict::Associative, i::Not) = setdiff(1:length(dict), indices(dict, i.index))

## namedgetindex collects the elements from the array, and takes care of the index names
## `index` is an integer now, or an array of integers, or a cartesianindex
## and has been computed by `indices()`

## Simple scalar indexing
@inline namedgetindex{N}(n::NamedArray, I::Vararg{Integer,N}) = getindex(n.array, I...)

dimkeepingtype(x) = false
dimkeepingtype(x::AbstractArray) = true
dimkeepingtype(x::Range) = true
dimkeepingtype(x::BitArray) = true

## Slices etc.
namedgetindex(n::NamedArray, index::CartesianIndex) = getindex(n.array, index)
function namedgetindex(n::NamedArray, index...; useview=false)
    if useview
        a = view(n.array, index...)
    else
        a = getindex(n.array, index...)
    end
    N = length(index)
    keeping = filter(i -> dimkeepingtype(index[i]), 1:N)
    if ndims(a) < length(keeping) ## || length(dims) == 1 && ndims(n) > 1
        warn("Dropped names for ", typeof(n.array), " with index ", index)
        return a;               # number of dimension changed, this should not happen
    end
    newnames = Any[]
    newdimnames = []
    for d in keeping
        if ndims(index[d]) > 1
            ## take over the names of the index for this dimension
            for (name, dimname) in zip(defaultnames(index[d]), dimnames(index[d]))
                push!(newnames, name)
                push!(newdimnames, Symbol(string(n.dimnames[d], "_", dimname)))
            end
        else
            push!(newnames, names(n, d)[index[d]])
            push!(newdimnames, n.dimnames[d])
        end
    end
    return NamedArray(a, tuple(newnames...), tuple(newdimnames...))
end

function indices(n::NamedArray, I::Pair...)
    length(I) == ndims(n) || error("Incorrect number of dimensions")
    dict = Dict{Any,Any}(I...)
    Set(keys(dict)) == Set(n.dimnames) || error("Dimension name mismatch")
    result = Vector{Int}(ndims(n))
    for (i, name) in enumerate(n.dimnames)
        result[i] = n.dicts[i][dict[name]]
    end
    return result
end

getindex(n::NamedArray, I::Pair...) = getindex(n.array, indices(n, I...)...)
getindex{T,N}(n::NamedArray{T,N}, I::CartesianIndex{N}) = getindex(n.array, I)

import Base.setindex!

# n[:] = m
setindex!(n::NamedArray, x, ::Colon) = setindex!(n.array, x, :)

# n[1:4] = 1:4
## shamelessly copied from array.jl
function setindex!{T}(A::NamedArray{T}, X::ArrayOrNamed{T}, I::Range{Int})
    if length(X) != length(I); error("argument dimensions must match"); end
    copy!(A, first(I), X, 1, length(I))
    return A
end

## This takes care of most other cases
@inline function setindex!{T,N}(A::NamedArray{T,N}, x, I::Vararg{Any,N})
    II = map((d,i)->indices(d, i), A.dicts, I)
    setindex!(A.array, x, II...)
end
@inline setindex!{T,N}(n::NamedArray{T,N}, x, I::Vararg{Pair,N}) = setindex!(n.array, x, indices(n, I...)...)
