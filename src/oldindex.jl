## index.jl getindex and setindex methods for NamedArray

## (c) 2013--2014 David A. van Leeuwen

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

import Base.getindex, Base.to_index

## resolve ambiguity, this should not happen
typeerror() = error("Wrong index type")
indices(dict::Dict{Bool}, i::AbstractVector{Bool}) = typeerror()
indices(dict::Dict{Bool}, i::Range{Bool}) = typeerror()
for t in (:Integer, :Real)
    @eval indices{K<:$t}(dict::Dict{K}, i::AbstractVector{K}) = typeerror()
    @eval indices{K<:$t}(dict::Dict{K}, i::Range{K}) = typeerror()
end
indices(dict::Dict{Bool}, i::BitVector) = typeerror()
for t in (:Colon, :Index)
    @eval getindex{T}(a::NamedArray{T,1,(Dict{$t,Int64},)}, i::$t) = typeerror()
end
for t1 in (:Index, :Indices) for t2 in (:Index, :Indices)
    @eval getindex{T}(a::NamedArray{T,2,(Dict{$t1,Int64},Dict{$t2,Int64})}, i1::$t1, i2::$t2) = typeerror()
end end
## more ambiguities
getindex(a::NamedArray, i::AbstractArray) = namedgetindex(a, i) ## abstractarray.jl
getindex{T,K<:Real}(a::NamedArray{T,1,(Dict{K,Int64},)}, i::Uint64) = namedgetindex(a, i)
for t in (:Real, :AbstractArray)
    @eval getindex{T,A<:$t}(a::NamedArray{T,1,(Dict{A,Int64},)}, i::$t) = namedgetindex(a, i)
end
getindex{T, K1<:Real, K2<:Real}(a::NamedArray{T,2,(Dict{K1,Int64},Dict{K2,Int64})}, i1::K1, i2::K2) = namedgetindex(a, i1, i2)
getindex(a::NamedArray, i::Real) = getindex(a.array, to_index(i))

## Everything should be routed through Index / Indices
getindex(n::NamedArray, i::Index) = getindex(n.array, i.index)
getindex(n::NamedArray, i1::Index, i2::Index) = getindex(n.array, i1.index, i2.index)
## etc
getindex(n::NamedArray, i1::Index, i2::Indices) = namedgetindex(n, i1.index, i2.index)
getindex(n::NamedArray, i1::Indices, i2::Index) = namedgetindex(n, i1.index, i2.index)
getindex(n::NamedArray, i1::Indices, i2::Indices) = namedgetindex(n, i1.index, i2.index)

## perform the getindex while keeping names
## index should be something a normal getindex(::Array) can deal with
function namedgetindex(n::NamedArray, index...)
    a = getindex(n.array, index...)
    dims = map(length, index)
    N = length(dims)
    while dims[N]==1 && N>1
        N -= 1
    end
    if ndims(a) != N || length(dims)==1 && ndims(n)>1
        return a;               # number of dimension changed
    end
    newnames = Any[]
    for d = 1:N
        sortkeys = names(n, d)
        push!(newnames, [sortkeys[i] for i in index[d]])
    end
    NamedArray(a, tuple(newnames...), tuple(n.dimnames[1:N]...))
end

# These functions transform various index types into values suitable for standard array indexing
indices(dict::Dict, I::Range) = Indices(I)
indices{K}(dict::Dict{K}, i::K) = Index(dict[i])
indices{K}(dict::Dict{K}, I::AbstractVector{K}) = Indices(map(k -> dict[k], I)) # convenience
indices(dict::Dict, I::BitVector) = Indices(find(I))
indices(dict::Dict, I::AbstractVector{Bool}) = Indices(find(I))

## negative integers / reals
function indices(dict::Dict, i::Integer)
    if i > 0
        return Index(i)
    else
        return Indices(setdiff(1:length(dict), -i))
    end
end
indices(dict::Dict, i::Real) = indices(dict::Dict, to_index(i))

## Array of int, positive or negative
function indices{T<:Integer}(dict::Dict, I::AbstractVector{T})
    if all(I .> 0)
        return Indices(I)
    elseif all(I .< 0)
        return Indices(setdiff(1:length(dict), -I))
    else
        error("indices must all be of the same sign")
    end
end
indices{T<:Real}(dict::Dict, I::AbstractVector{T}) = indices(dict, to_index(I))

function indices(dict::Dict, I::Names)
    k = keys(dict)
    if !is(eltype(I.names), eltype(k))
        error("elements of the Names object must be of the same type as the array names for each dimension")
    end
    if I.exclude
        return Indices(map(s -> dict[s], setdiff(sortnames(dict), I.names)))
    else
        return Indices(map(s -> dict[s], I.names))
    end
end

## 0.4-dev functions
if VERSION >= v"0.4.0-dev"
    indices(dict::Dict, it::Base.IteratorsMD.CartesianIndex) = it
end

## getindex()
## resolve ambiguity in 0.4-dev
getindex(A::NamedVector, ::Colon) = A

## first, we do all combinations of single indices, for efficiency reasons
getindex{T,K}(A::NamedArray{T,1,(Dict{K,Int},)}, i::Uint) = getindex(A.array, i) # always positive

## resolve ambiguity with AbstactArray
getindex{T,R<:Real}(a::NamedArray{T, 1, (Dict{R,Int},)}, i::R) = getindex(a, indices(a.dicts[1], i))



## can we construct a faster getindex for a known key type?
for t1 in [:Real, :K1]
    @eval getindex{T,K1}(a::NamedArray{T,1,(Dict{K1,Int},)}, i::$t1) = getindex(a, indices(a.dicts[1], i))
    for t2 in [:Real, :K2]
        @eval getindex{T,K1,K2}(a::NamedArray{T,2,(Dict{K1,Int},Dict{K2,Int})}, i1::$t1, i2::$t2) = getindex(a, indices(a.dicts[1], i1), indices(a.dicts[2], i2))
        for t3 in [:Real, :K3]
            @eval getindex{T,K1,K2,K3}(a::NamedArray{T,3,(Dict{K1,Int},Dict{K2,Int},Dict{K3,Int})}, i1::$t1, i2::$t2, i3::$t3) = getindex(a, indices(a.dicts[1], i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3))
        end
    end
end

## This covers everything up over 3 dimensions
getindex(a::NamedArray, index...) = getindex(a, map(i -> indices(a.dicts[i], index[i]), 1:length(index))...)


import Base.setindex!

setindex!{T}(A::NamedArray{T}, x) = setindex!(A, convert(T,x), 1)

setindex!{T}(A::NamedArray{T}, x, i0::Real) = setindex!(A.array, convert(T,x), to_index(i0))
setindex!{T}(A::NamedArray{T}, x, i0::Real, i1::Real) =
    setindex!(A.array, convert(T,x), to_index(i0), to_index(i1))
setindex!{T}(A::NamedArray{T}, x, i0::Real, i1::Real, i2::Real) =
    setindex!(A.array, convert(T,x), to_index(i0), to_index(i1), to_index(i2))
setindex!{T}(A::NamedArray{T}, x, i0::Real, i1::Real, i2::Real, i3::Real) =
    setindex!(A.array, convert(T,x), to_index(i0), to_index(i1), to_index(i2), to_index(i3))
setindex!{T}(A::NamedArray{T}, x, i0::Real, i1::Real, i2::Real, i3::Real, i4::Real) =
    setindex!(A.array, convert(T,x), to_index(i0), to_index(i1), to_index(i2), to_index(i3), to_index(i4))
setindex!{T}(A::NamedArray{T}, x, i0::Real, i1::Real, i2::Real, i3::Real, i4::Real, i5::Real) =
    setindex!(A.array, convert(T,x), to_index(i0), to_index(i1), to_index(i2), to_index(i3), to_index(i4), to_index(i5))
setindex!{T}(A::NamedArray{T}, x, i0::Real, i1::Real, i2::Real, i3::Real, i4::Real, i5::Real, I::Int...) =
    setindex!(A.array, convert(T,x), to_index(i0), to_index(i1), to_index(i2), to_index(i3), to_index(i4), to_index(i5), I...)

# n[1:4] = 5
setindex!{T<:Real}(A::NamedArray, x, I::AbstractVector{T}) = setindex!(A.array, x, I)

# n[1:4] = 1:4
## shamelessly copied from array.jl
function setindex!{T}(A::NamedArray{T}, X::ArrayOrNamed{T}, I::Range1{Int})
    if length(X) != length(I); error("argument dimensions must match"); end
    copy!(A, first(I), X, 1, length(I))
    return A
end

# n[[1,3,4,6]] = 1:4
setindex!{T<:Real}(A::NamedArray, X::AbstractArray, I::AbstractVector{T}) = setindex!(A.array, X, I)

## This takes care of most other cases
function setindex!(A::NamedArray, x, I...)
    II = tuple([indices(A.dicts[i], I[i]) for i=1:length(I)]...)
    setindex!(A.array, x, II...)
end

