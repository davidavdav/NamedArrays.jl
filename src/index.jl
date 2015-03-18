## index.jl getindex and setindex methods for NamedArray
## (c) 2013--2014 David A. van Leeuwen

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

import Base.getindex, Base.to_index

## ambiguity from abstractarray.jl
getindex(a::NamedArray, i::Real) = namedgetindex(a, indices(a.dicts[1], i))
getindex(a::NamedArray, i::AbstractArray) = namedgetindex(a, indices(a.dicts[1], i))
## from subarray.jl
getindex{T}(a::NamedArray{T,1}, ::Colon) = a

getindex(a::NamedArray, i) = namedgetindex(a, indices(a.dicts[1], i))
getindex(a::NamedArray, i1, i2) = namedgetindex(a, indices(a.dicts[1], i1), indices(a.dicts[2], i2))
getindex(a::NamedArray, i1, i2, i3) = namedgetindex(a, indices(a.dicts[1], i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3))
getindex(a::NamedArray, i1, i2, i3, i4) = namedgetindex(a, indices(a.dicts[1], i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3), indices(a.dicts[4], i4))
getindex(a::NamedArray, i1, i2, i3, i4, i5) = namedgetindex(a, indices(a.dicts[1], i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3), indices(a.dicts[4], i4), indices(a.dicts[5], i5))
getindex(a::NamedArray, i1, i2, i3, i4, i5, I...) = namedgetindex(a, indices(a.dicts[1], i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3), indices(a.dicts[4], i4), indices(a.dicts[5], i5), [indices(a.dicts[5+i], ind) for (i,ind) in enumerate(I)]...)

## 0.4-dev functions
if VERSION >= v"0.4.0-dev"
    getindex(a::NamedArray, it::Base.IteratorsMD.CartesianIndex) = getindex(a.array, it)
end

## single index
indices{K<:Real,V<:Integer}(dict::Associative{K,V}, i::K) = dict[i]
indices{K,V<:Integer}(dict::Associative{K,V}, i::Real) = to_index(i)
indices{K,V<:Integer}(dict::Associative{K,V}, i::K) = dict[i]
## multiple indices
## the following two lines are [artly because of ambiguity
indices{T<:Integer,V<:Integer}(dict::Associative{T,V}, i::AbstractArray{T}) = [dict[k] for k in i]
indices{T<:Real,V<:Integer}(dict::Associative{T,V}, i::AbstractArray{T}) = [dict[k] for k in i]
indices{T<:Integer,K,V<:Integer}(dict::Associative{K,V}, i::AbstractArray{T}) = i
indices{K,V<:Integer}(dict::Associative{K,V}, i::AbstractArray{K}) = [dict[k] for k in i]

## negation
indices{K<:Not,V<:Integer}(dict::Associative{K,V}, i::K) = dict[i]
indices(dict::Associative, i::Not) = setdiff(1:length(dict), indices(dict, i.index))

namedgetindex(a::NamedArray, i::Integer) = getindex(a.array, i)
namedgetindex(a::NamedArray, i1::Integer, i2::Integer) = getindex(a.array, i1, i2)
namedgetindex(a::NamedArray, i1::Integer, i2::Integer, i3::Integer) = getindex(a.array, i1, i2, i3)
namedgetindex(a::NamedArray, i1::Integer, i2::Integer, i3::Integer, i4::Integer) = getindex(a.array, i1, i2, i3, i4)
namedgetindex(a::NamedArray, i1::Integer, i2::Integer, i3::Integer, i4::Integer, i5::Integer) = getindex(a.array, i1, i2, i3, i4, i5)
namedgetindex(a::NamedArray, i1::Integer, i2::Integer, i3::Integer, i4::Integer, i5::Integer, I::Integer...) = getindex(a.array, i1, i2, i3, i4, i5, I...)


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

import Base.setindex!

setindex!{T}(A::NamedArray{T}, x) = setindex!(A, convert(T,x), 1)

setindex!{T}(a::NamedArray{T}, x, i1::Real) = setindex!(a.array, convert(T,x), indices(a.dicts[1],i1))
setindex!{T}(a::NamedArray{T}, x, i1::Real, i2::Real) =
    setindex!(a.array, convert(T,x), indices(a.dicts[1], i1), indices(a.dicts[2], i2))
setindex!{T}(a::NamedArray{T}, x, i1::Real, i2::Real, i3::Real) =
    setindex!(a.array, convert(T,x), indices(a.dicts[1],i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3))
setindex!{T}(a::NamedArray{T}, x, i1::Real, i2::Real, i3::Real, i4::Real) =
    setindex!(a.array, convert(T,x), indices(a.dicts[1], i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3), indices(a.dicts[4], i4))
setindex!{T}(a::NamedArray{T}, x, i1::Real, i2::Real, i3::Real, i4::Real, i5::Real) =
    setindex!(a.array, convert(T,x), indices(a.dicts[1], i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3), indices(a.dicts[4], i4), indices(a.dicts[5], i5))
setindex!{T}(a::NamedArray{T}, x, i1::Real, i2::Real, i3::Real, i4::Real, i5::Real, i6::Real) =
    setindex!(a.array, convert(T,x), indices(a.dicts[1], i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3), indices(a.dicts[4], i4), indices(a.dicts[5], i5), indices(a.dicts[6], i6))
setindex!{T}(a::NamedArray{T}, x, i1::Real, i2::Real, i3::Real, i4::Real, i5::Real, i6::Real, I...) =
    setindex!(a.array, convert(T,x), indices(a.dicts[1], i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3), indices(a.dicts[4], i4), indices(a.dicts[5], i5), indices(a.dicts[6], i6), I...)

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
