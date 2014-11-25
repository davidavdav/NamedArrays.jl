## index.jl getindex and setindex methods for NamedArray

## (c) 2013 David A. van Leeuwen

## This code is licensed under the GNU General Public License, version 2
## See the file LICENSE in this distribution

import Base.getindex, Base.to_index

## resolve ambiguity, this should not happen
indices(dict::Dict{Bool}, i::AbstractVector{Bool}) = error("Wrong index type")
indices(dict::Dict{Bool}, i::Range{Bool}) = error("Wrong index type")
for t in (:Integer, :Real)
    @eval indices{K<:$t}(dict::Dict{K}, i::AbstractVector{K}) = error("Wrong index type")
    @eval indices{K<:$t}(dict::Dict{K}, i::Range{K}) = error("Wrong index type")
end
indices(dict::Dict{Bool}, i::BitVector) = error("Wrong index type")
getindex(a::NamedArray, i::AbstractArray) = getindex(a.array, i) ## abstractarray.jl

# These functions transform various index types into values suitable for standard array indexing
indices(dict::Dict, I::Range) = I
indices{K}(dict::Dict{K}, I::K) = dict[I]
indices{K}(dict::Dict{K}, I::AbstractVector{K}) = map(k -> dict[k], I) # convenience
indices(dict::Dict, I::BitVector) = find(I)
indices(dict::Dict, I::AbstractVector{Bool}) = find(I)

if false
    indices(dict::Dict, i::Integer) = i
    indices{T<:Integer}(dict::Dict, i::AbstractVector{T}) = i
end

## negative integers / reals
function indices(dict::Dict, I::Integer)
    if I > 0
        return I
    else
        return setdiff(1:length(dict), -I)
    end
end
indices(dict::Dict, I::Real) = indices(convert(Int, I))

## Array of int, positive or negative
function indices{T<:Integer}(dict::Dict, I::AbstractVector{T})
    if all(I .> 0)
        return I
    elseif all(I .< 0)
        return setdiff(1:length(dict), -I)
    else
        error("indices must all be of the same sign")
    end
end
indices{T<:Real}(dict::Dict, I::AbstractVector{T}) = indices(dict, convert(Vector{Int}, I))

function indices(dict::Dict, I::Names)
    k = keys(dict)
    if !is(eltype(I.names), eltype(k))
        error("elements of the Names object must be of the same type as the array names for each dimension")
    end

    if I.exclude
        return map(s -> dict[s], setdiff(sortnames(dict), I.names))
    else
        return map(s -> dict[s], I.names)
    end
end

## first, we do all combinations of single indices, for efficiency reasons
getindex(A::NamedArray, i1::Uint) = getindex(A.array, i1) # always positive
function getindex(A::NamedArray, i1::Real) 
    if i1>0
        getindex(A.array,i1)
    else 
        getindex(A.array, setdiff(1:length(A.dicts[1]),to_index(-i1)))
    end
end

types = [:Real]
for T1 in types 
    for T2 in types
        @eval getindex(a::NamedArray, i1::$T1, i2::$T2) = getindex(a.array, indices(a.dicts[1], i1), indices(a.dicts[2], i2))
        for T3 in types 
            @eval getindex(a::NamedArray, i1::$T1, i2::$T2, i3::$T3) = getindex(a.array, indices(a.dicts[1], i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3))
#            @eval setindex!{T}(a::NamedArray{T}, x, i1::$T1, i2::$T2, i3::$T3) =
#            setindex!(a.array, convert(T,x), indices(a.dicts[1], i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3))
       end
    end 
end
## This covers everything up over 3 dimensions
getindex(a::NamedArray, index...) = getindex(a.array, map(i -> indices(a.dicts[i], index[i]), 1:length(index))...)

## for Ranges or Arrays we do an effort keep names
## We follow the protocol of Array, that the last singleton dimensions are dropped
function getindex(A::NamedArray, I::IndexOrNamed...)
    II = tuple([indices(A.dicts[i], I[i]) for i=1:length(I)]...)
    a = getindex(A.array, II...)
    dims = map(length, II)
    n = length(dims)
    while dims[n]==1 && n>1
        n -= 1
    end
    if ndims(a) != n || length(dims)==1 && ndims(A)>1; 
        return a;               # number of dimension changed
    end 
    names = Any[]
    for d = 1:n
        sortkeys = collect(keys(A.dicts[d]))[sortperm(collect(keys(A.dicts[d])))]
        push!(names, [sortkeys[i] for i in II[d]])
    end
    NamedArray(a, tuple(names...), tuple(A.dimnames[1:n]...))
end

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

