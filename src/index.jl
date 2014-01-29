## index.jl getindex and setindex methods for NamedArray

## (c) 2013 David A. van Leeuwen

## This code is licensed under the GNU General Public License, version 2
## See the file LICENSE in this distribution

import Base.getindex, Base.to_index

# These functions transform various index types into values suitable for standard array indexing
indices(dict::Dict, I::Range1) = I
indices(dict::Dict, I::Range) = I
indices(dict::Dict, I::String) = dict[I]
indices{T<:String}(dict::Dict, I::AbstractVector{T}) = map(s -> dict[s], I) # convenience
indices(dict::Dict, I::BitArray) = find(I)
indices(dict::Dict, I::AbstractVector{Bool}) = find(I)
indices(dict::Dict, I::AbstractVector) = error("unsupported vector type: ", eltype(I))

function indices(dict::Dict, I::Integer)
    if I > 0
        return I
    else
        return setdiff(1:length(dict), -I)
    end
end

indices(dict::Dict, I::Real) = indices(convert(Int, I))

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
        return map(s -> dict[s], setdiff(names(dict), I.names))
    else
        return map(s -> dict[s], I.names)
    end
end

## first, we do all combinations of single indices, for efficiency reasons
getindex(A::NamedArray, i1::Uint) = arrayref(A.array, to_index(i1)) # always positive
function getindex(A::NamedArray, i1::Real) 
    if i1>0
        arrayref(A.array,to_index(i1))
    else 
        getindex(A.array, setdiff(1:length(A.dicts[1]),to_index(-i1)))
    end
end
getindex(A::NamedArray, s1::String) = getindex(A, A.dicts[1][s1])
types = [:Real, :String]
for T1 in types 
    for T2 in types
        @eval getindex(a::NamedArray, i1::$T1, i2::$T2) = getindex(a.array, indices(a.dicts[1], i1), indices(a.dicts[2], i2))
        for T3 in types 
            @eval getindex(a::NamedArray, i1::$T1, i2::$T2, i3::$T3) = getindex(a.array, indices(a.dicts[1], i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3))
            @eval setindex!{T}(a::NamedArray{T}, x, i1::$T1, i2::$T2, i3::$T3) =
            arrayset(a.array, convert(T,x), indices(a.dicts[1], i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3))
#            @eval getindex(a::NamedArray, i1::$T1, i2::$T2, i3::$T3, index::Union($(types...))...) = getindex(a.array, indices(a.dicts[1], i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3), map(i -> indices(a.dicts[i], index[i]), 1:length(index))...)
        end
    end 
end
## This covers everything up over 3 dimensions
getindex(a::NamedArray, index::Union(Real, String)...) = getindex(a.array, map(i -> indices(a.dicts[i], index[i]), 1:length(index))...)

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
    if ndims(a) != n || length(dims)==1 && ndims(A)>1; return a; end # number of dimension changed
    newnames = [ [getindex(names(A,i),II[i])] for i=1:n ]
    NamedArray(a, newnames, A.dimnames[1:n])
end

## These seem to be caught by the general getindex, I'm not sure if this is what we want...
#getindex(A::NamedArray, i0::Real, i1::Real) = arrayref(A.array,to_index(i0),to_index(i1))
#getindex(A::NamedArray, i0::Real, i1::Real, i2::Real) =
#    arrayrefNamed(A.array,to_index(i0),to_index(i1),to_index(i2))
#getindex(A::NamedArray, i0::Real, i1::Real, i2::Real, i3::Real) =
#    arrayrefNamed(A.array,to_index(i0),to_index(i1),to_index(i2),to_index(i3))
#getindex(A::NamedArray, i0::Real, i1::Real, i2::Real, i3::Real,  i4::Real) =
#    arrayrefNamed(A.array,to_index(i0),to_index(i1),to_index(i2),to_index(i3),to_index(i4))
#getindex(A::NamedArray, i0::Real, i1::Real, i2::Real, i3::Real,  i4::Real, i5::Real) =
#    arrayrefNamed(A.array,to_index(i0),to_index(i1),to_index(i2),to_index(i3),to_index(i4),to_index(i5))

#getindex(A::NamedArray, i0::Real, i1::Real, i2::Real, i3::Real,  i4::Real, i5::Real, I::Int...) =
#    arrayref(A.array,to_index(i0),to_index(i1),to_index(i2),to_index(i3),to_index(i4),to_index(i5),I...)


import Base.setindex!

setindex!{T}(A::NamedArray{T}, x) = arrayset(A, convert(T,x), 1)

setindex!{T}(A::NamedArray{T}, x, i0::Real) = arrayset(A.array, convert(T,x), to_index(i0))
setindex!{T}(A::NamedArray{T}, x, i0::Real, i1::Real) =
    arrayset(A.array, convert(T,x), to_index(i0), to_index(i1))
setindex!{T}(A::NamedArray{T}, x, i0::Real, i1::Real, i2::Real) =
    arrayset(A.array, convert(T,x), to_index(i0), to_index(i1), to_index(i2))
setindex!{T}(A::NamedArray{T}, x, i0::Real, i1::Real, i2::Real, i3::Real) =
    arrayset(A.array, convert(T,x), to_index(i0), to_index(i1), to_index(i2), to_index(i3))
setindex!{T}(A::NamedArray{T}, x, i0::Real, i1::Real, i2::Real, i3::Real, i4::Real) =
    arrayset(A.array, convert(T,x), to_index(i0), to_index(i1), to_index(i2), to_index(i3), to_index(i4))
setindex!{T}(A::NamedArray{T}, x, i0::Real, i1::Real, i2::Real, i3::Real, i4::Real, i5::Real) =
    arrayset(A.array, convert(T,x), to_index(i0), to_index(i1), to_index(i2), to_index(i3), to_index(i4), to_index(i5))
setindex!{T}(A::NamedArray{T}, x, i0::Real, i1::Real, i2::Real, i3::Real, i4::Real, i5::Real, I::Int...) =
    arrayset(A.array, convert(T,x), to_index(i0), to_index(i1), to_index(i2), to_index(i3), to_index(i4), to_index(i5), I...)

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
function setindex!(A::NamedArray, x, I::IndexOrNamed...)
    II = tuple([indices(A.dicts[i], I[i]) for i=1:length(I)]...)
    setindex!(A.array, x, II...)
end

