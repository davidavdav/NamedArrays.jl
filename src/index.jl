## index.jl getindex and setindex methods for NamedArray
## (c) 2013--2016 David A. van Leeuwen

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

import Base: getindex, to_index

## ambiguity from abstractarray.jl
if VERSION < v"0.5-dev"
    getindex(n::NamedArray, i::Real) = namedgetindex(n, indices(n.dicts[1], i))
    getindex(n::NamedArray, i::AbstractArray) = namedgetindex(n, indices(n.dicts[1], i))
end
## from subarray.jl
getindex(n::NamedVector, ::Colon) = n
getindex(n::NamedArray, ::Colon) = n.array[:]

## special 0-dimensional case
getindex{T}(n::NamedArray{T,0}, i::Real) = getindex(n.array, i)
if VERSION < v"0.5-dev"
    getindex(a::NamedArray, i) = namedgetindex(a, indices(a.dicts[1], i))
    getindex(a::NamedArray, i1, i2) = namedgetindex(a, indices(a.dicts[1], i1), indices(a.dicts[2], i2))
    getindex(a::NamedArray, i1, i2, i3) = namedgetindex(a, indices(a.dicts[1], i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3))
    getindex(a::NamedArray, i1, i2, i3, i4) = namedgetindex(a, indices(a.dicts[1], i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3), indices(a.dicts[4], i4))
    getindex(a::NamedArray, i1, i2, i3, i4, i5) = namedgetindex(a, indices(a.dicts[1], i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3), indices(a.dicts[4], i4), indices(a.dicts[5], i5))
    getindex(a::NamedArray, i1, i2, i3, i4, i5, I...) = namedgetindex(a, indices(a.dicts[1], i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3), indices(a.dicts[4], i4), indices(a.dicts[5], i5), [indices(a.dicts[5+i], ind) for (i,ind) in enumerate(I)]...)

    getindex(a::NamedArray, it::Base.IteratorsMD.CartesianIndex) = getindex(a.array, it)
else
    @inline function getindex{T,N}(a::NamedArray{T,N}, I::Vararg{Any,N})
        namedgetindex(a, map((d,i)->indices(d, i), a.dicts, I)...)
    end
end

## indices(::Associative, index) converts any type `index` to Integer

## single index
indices{K<:Real,V<:Integer}(dict::Associative{K,V}, i::K) = dict[i]
indices{K,V<:Integer}(dict::Associative{K,V}, i::Real) = to_index(i)
indices{K,V<:Integer}(dict::Associative{K,V}, i::K) = dict[i]

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

namedgetindex(a::NamedArray, i::Integer) = getindex(a.array, i)
namedgetindex(a::NamedArray, i1::Integer, i2::Integer) = getindex(a.array, i1, i2)
namedgetindex(a::NamedArray, i1::Integer, i2::Integer, i3::Integer) = getindex(a.array, i1, i2, i3)
namedgetindex(a::NamedArray, i1::Integer, i2::Integer, i3::Integer, i4::Integer) = getindex(a.array, i1, i2, i3, i4)
namedgetindex(a::NamedArray, i1::Integer, i2::Integer, i3::Integer, i4::Integer, i5::Integer) = getindex(a.array, i1, i2, i3, i4, i5)
namedgetindex(a::NamedArray, i1::Integer, i2::Integer, i3::Integer, i4::Integer, i5::Integer, I::Integer...) = getindex(a.array, i1, i2, i3, i4, i5, I...)

dimkeepingtype(x) = false
dimkeepingtype(x::AbstractArray) = true
dimkeepingtype(x::Range) = true
dimkeepingtype(x::BitArray) = true

## namedgetindex collects the elements from the array, and takes care of the index names
## `index` is an integer now, or an array of integers, or a cartesianindex
## and has been computed by `indices()`
if VERSION < v"0.5.0-dev"
    ## in julia pre 0.5, only trailing singleton dimensions are removed
    function namedgetindex(n::NamedArray, index...)
        a = getindex(n.array, index...)
        N = length(index)
        keeping = collect(1:N) ## dimensions that are kept after slicing
        i = N
        while i > 1 && !dimkeepingtype(index[i])
            deleteat!(keeping, i)
            i -= 1
        end
        if ndims(a) != length(keeping) ## || length(dims) == 1 && ndims(n) > 1
            warn("Dropped names for ", typeof(n.array), " with index ", index)
            return a;               # number of dimension changed, this should not happen
        end
        newnames = Any[]
        for d in keeping
            if dimkeepingtype(index[d])
                push!(newnames, names(n, d)[index[d]])
            else
                push!(newnames, names(n, d)[[index[d]]]) ## for julia-0.4, index[d] could be Integer, but result should be Array
            end
        end
        return NamedArray(a, tuple(newnames...), n.dimnames[keeping])
    end
else
    ## in julia post 0.5, all singleton dimensions are removed
    namedgetindex(n::NamedArray, index::CartesianIndex) = getindex(n.array, index)
    function namedgetindex(n::NamedArray, index...)
        a = getindex(n.array, index...)
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

import Base.setindex!

setindex!{T}(A::NamedArray{T}, x) = setindex!(A, convert(T,x), 1)

if VERSION < v"0.5-dev"
    setindex!{T}(a::NamedArray{T}, x, i1::Real) = setindex!(a.array, convert(T,x), indices(a.dicts[1],i1))
    setindex!{T}(a::NamedArray{T}, x, i1::Real, i2::Real) = setindex!(a.array, convert(T,x), indices(a.dicts[1], i1), indices(a.dicts[2], i2))
    setindex!{T}(a::NamedArray{T}, x, i1::Real, i2::Real, i3::Real) = setindex!(a.array, convert(T,x), indices(a.dicts[1],i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3))
    setindex!{T}(a::NamedArray{T}, x, i1::Real, i2::Real, i3::Real, i4::Real) = setindex!(a.array, convert(T,x), indices(a.dicts[1], i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3), indices(a.dicts[4], i4))
    setindex!{T}(a::NamedArray{T}, x, i1::Real, i2::Real, i3::Real, i4::Real, i5::Real) = setindex!(a.array, convert(T,x), indices(a.dicts[1], i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3), indices(a.dicts[4], i4), indices(a.dicts[5], i5))
    setindex!{T}(a::NamedArray{T}, x, i1::Real, i2::Real, i3::Real, i4::Real, i5::Real, i6::Real) = setindex!(a.array, convert(T,x), indices(a.dicts[1], i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3), indices(a.dicts[4], i4), indices(a.dicts[5], i5), indices(a.dicts[6], i6))
    setindex!{T}(a::NamedArray{T}, x, i1::Real, i2::Real, i3::Real, i4::Real, i5::Real, i6::Real, I...) = setindex!(a.array, convert(T,x), indices(a.dicts[1], i1), indices(a.dicts[2], i2), indices(a.dicts[3], i3), indices(a.dicts[4], i4), indices(a.dicts[5], i5), indices(a.dicts[6], i6), I...)
    # n[1:4] = 5
    setindex!{T<:Real}(A::NamedArray, x, I::Union{Colon,AbstractVector{T}}) = setindex!(A.array, x, I)
end

# n[:] = m
setindex!(n::NamedArray, x, ::Colon) = setindex!(n.array, x, :)

# n[1:4] = 1:4
## shamelessly copied from array.jl
function setindex!{T}(A::NamedArray{T}, X::ArrayOrNamed{T}, I::Range{Int})
    if length(X) != length(I); error("argument dimensions must match"); end
    copy!(A, first(I), X, 1, length(I))
    return A
end

if VERSION < v"0.5-dev"
    # n[[1,3,4,6]] = 1:4
    setindex!{T<:Real}(A::NamedArray, X::AbstractArray, I::AbstractVector{T}) = setindex!(A.array, X, I)

    setindex!(a::NamedArray, x, it::Base.IteratorsMD.CartesianIndex) = setindex!(a.array, x, it)
    setindex!(n::NamedArray, x, I::Pair...) = setindex!(n.array, x, indices(n, I...)...)

    ## This takes care of most other cases
    function setindex!(A::NamedArray, x, I...)
        II = tuple([indices(A.dicts[i], I[i]) for i=1:length(I)]...)
        setindex!(A.array, x, II...)
    end
else
    ## This takes care of most other cases
    @inline function setindex!{T,N}(A::NamedArray{T,N}, x, I::Vararg{Any,N})
        II = map((d,i)->indices(d, i), A.dicts, I)
        setindex!(A.array, x, II...)
    end
    @inline setindex!{T,N}(n::NamedArray{T,N}, x, I::Vararg{Pair,N}) = setindex!(n.array, x, indices(n, I...)...)
end
