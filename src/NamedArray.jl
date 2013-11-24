## NamedArray.jl
## (c) 2013 David A. van Leeuwen

## Julia type that implements a drop-in replacement of Array with named dimensions. 

## This code is licensed under the GNU General Public License, version 2
## See the file LICENSE in this distribution

## type definition
require("src/namedarraytypes.jl")

## access to the names of the dimensions
names(dict::Dict) = collect(keys(dict))[sortperm(collect(values(dict)))] 
names(a::NamedArray) = map(dict -> names(dict), a.dicts)
names(a::NamedArray, d::Int) = names(a.dicts[d])
dimnames(a::NamedArray) = a.dimnames
dimnames(a::NamedArray, d::Int) = a.dimnames[d]

## seting names, dimnames
function setnames!(a::NamedArray, v::Vector, d::Int)
    @assert size(a.array,d) == length(v)
    a.dicts[d] = Dict(v, 1:length(v))
end

## copy
import Base.copy
copy(a::NamedArray) = NamedArray{eltype(a),length(a.dicts)}(copy(a.array), tuple(copy(a.dimnames)...), tuple(copy(a.dicts)...))

## from array.jl
function copy!{T}(dest::NamedArray{T}, dsto::Integer, src::ArrayOrNamed{T}, so::Integer, N::
Integer)
    if so+N-1 > length(src) || dsto+N-1 > length(dest) || dsto < 1 || so < 1
        throw(BoundsError())
    end
    if isa(src, NamedArray) 
        unsafe_copy!(dest.array, dsto, src.array, so, N)
    else
        unsafe_copy!(dest.array, dsto, src, so, N)
    end
end

import Base.size, Base.ndims
size(a::NamedArray) = arraysize(a.array)
size(a::NamedArray, d) = arraysize(a.array, d)
ndims(a::NamedArray) = ndims(a.array)


## convert, promote
import Base.convert,Base.promote_rule
## to array
convert{T,N}(::Type{Array{T,N}}, A::NamedArray{T,N}) = A.array
convert(::Type{Array}, a::NamedArray) = a.array
## to other type
convert{T}(::Type{NamedArray{T}}, a::NamedArray) = NamedArray(convert(Array{T}, a.array), tuple(a.dimnames...), tuple(a.dicts...))
function promote_rule{T1<:Real,T2<:Real,N}(::Type{Array{T1,N}},::Type{NamedArray{T2,N}})
    println("my rule")
    t = promote_type(T1,T2)
    Array{t,N}
end
for op in (:+, :-, :.+, :.-, :.*, :./)
    ## named %op% named
    @eval function ($op)(x::NamedArray, y::NamedArray)
        if names(x)==names(y) && dimnames(x)==dimnames(y)
            NamedArray(($op)(x.array,y.array), tuple(names(x)...), tuple(dimnames(x)...))
        else
            warn("Dropping mismatching names")
            ($op)(x.array,y.array)
        end
    end
    ## named %op% array
    @eval ($op)(x::NamedArray, y::Array) = NamedArray(($op)(x.array, y), tuple(names(x)...), tuple(x.dimnames...))
    @eval ($op)(x::Array, y::NamedArray) = NamedArray(($op)(x, y.array), tuple(names(y)...), tuple(y.dimnames...))
end
for op in (:+, :-, :.+, :.-, :.*, :*, :/, :\) 
    @eval ($op)(x::AbstractArray, y::AbstractArray) = ($op)(promote(x,y)...)
end
## matmul
*(x::NamedArray, y::NamedArray) = NamedArray(x.array*y.array, (names(x,1),names(y,2)), (x.dimnames[1], y.dimnames[2]))
## scalar arithmetic
for op in (:+, :-, :*, :/, :.+, :.-, :.*, :./, :\)
    @eval function ($op)(x::NamedArray, y::Number) 
        if promote_type(eltype(x),typeof(y)) == eltype(x)
            r = copy(x)
            r.array = $op(x.array,y)
        else
            NamedArray(($op)(x.array, y), tuple(x.dimnames...), tuple(x.dicts...))
        end
    end
    @eval function ($op)(x::Number, y::NamedArray) 
        if promote_type(typeof(x), eltype(y)) == eltype(y)
            r = copy(y)
            r.array = $op(x, y.array)
        else
            NamedArray(($op)(x, y.array), tuple(x.dimnames...), tuple(x.dicts...))
        end
    end
end

import Base.print, Base.show # , Base.display
print(A::NamedArray) = print(A.array)
function show(io::IO, A::NamedArray)
    println(io, typeof(A), " names:")
    for i in 1:length(A.dimnames)
        print(io, " ", A.dimnames[i], ": ")
        print(io, names(A,i)')
    end
    print(io, A.array)
end

function ctranspose(a::NamedArray) 
    @assert ndims(a)==2
    NamedArray(a.array', tuple(reverse(names(a))...), tuple(reverse(a.dimnames)...))
end

import Base.similar
function similar(a::NamedArray, t::DataType, dims::NTuple)
    if size(a) != dims
        return NamedArray(t, dims...) # re-initialize names arrays...
    else
        return NamedArray(t, names(a), a.dimnames)
    end
end
#similar(A::NamedArray, t::DataType, dims::Int...) = similar(A, t, dims)
#similar(A::NamedArray, t::DataType) = similar(A, t, size(A.array))
#similar(A::NamedArray) = similar(A, eltype(A.array), size(A.array))

import Base.getindex, Base.to_index, Base.indices

# These functions transform various index types into values suitable for standard array indexing
indices(dict::Dict, I::Range1) = I
indices(dict::Dict, I::Range) = I
indices(dict::Dict, I::String) = dict[I]
indices{T<:String}(dict::Dict, I::AbstractVector{T}) = map(s -> dict[s], I)
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
getindex(A::NamedArray, i1::Real) = arrayref(A.array,to_index(i1))
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

##getindex(A::NamedArray, i0::Real) = arrayref(A.array,to_index(i0))
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
    newnames = map(i -> [getindex(names(A,i),II[i])], 1:n)
    NamedArray(a, tuple(newnames...), tuple(A.dimnames[1:n]...))
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

# this keeps names...
function hcat{T}(V::NamedVector{T}...) 
    keepnames=true
    V1=V[1]
    firstnames = names(V1)
    for i=2:length(V)
        keepnames &= names(V[i])==firstnames
    end
    a = hcat(map(a -> a.array, V)...)
    if keepnames
        colnames = [string(i) for i=1:size(a,2)]
        NamedArray(a, (firstnames[1], colnames), (V1.dimnames[1], "hcat"))
    else
        NamedArray(a)
    end
end

## sum etc: keep names in one dimension
import Base.sum, Base.prod, Base.maximum, Base.minimum, Base.mean, Base.std
for f = (:sum, :prod, :maximum, :minimum, :mean, :std)
    @eval function ($f)(a::NamedArray, d::Int)
        s = ($f)(a.array, d)
        newnames = [i==d ? [string($f,"(",a.dimnames[i],")")] : names(a,i) for i=1:ndims(a)]
        NamedArray(s, tuple(newnames...), tuple(a.dimnames...))
    end
end

function verify_names(a::NamedArray...)
    nargs = length(a)
    @assert nargs>1
    bigi = indmax(map(length, a)) # find biggest dimension
    big = a[bigi]
    for i in setdiff(bigi, 1:nargs)
        println("i ", i)
        for d=1:ndims(a[i])
            println("d ", d)
            if size(a[i],d) > 1
                @assert names(big,d) == names(a(i),d)
            end
        end
    end
    return bigi::Int, big
end

## broadcast
import Base.broadcast, Base.broadcast!
function broadcast(f::Function, a::NamedArray...)
    ## verify that the names are consistent
    bigi, big = verify_names(a...)
    arrays = map(x->x.array, a)
    NamedArray(broadcast(f, arrays...), tuple(big.dimnames...), tuple(big.dicts...))
end

function broadcast!(f::Function, dest::NamedArray, a::NamedArray...)
    ## verify that the names are consistent, we assume dest is the right size
    bigi, big = verify_names(a...)
    arrays = map(x->x.array, a)
    broadcast!(f, dest.array, arrays...)
    dest
end

import Base.flipdim
function flipdim(a::NamedArray, d::Int) 
    newdicts = copy(a.dicts)
    newdicts[d] = copy(a.dicts[d])
    n = size(a,d)+1
    for (k,v) in collect(newdicts[d])
        newdicts[d][k] = n - v
    end
    NamedArray(flipdim(a.array,d), tuple(a.dimnames...), tuple(newdicts...))
end

## circshift automagically works...
## :' automagically works, how is this possible?

import Base.permutedims
function permutedims(a::NamedArray, perm::Vector{Int})
    newdicts = a.dicts[perm]
    newdimnames = a.dimnames[perm]
    NamedArray(permutedims(a.array, perm), tuple(newdimnames...), tuple(newdicts...))
end
import Base.transpose
transpose(a::NamedArray) = permutedims(a, [2,1])

import Base.vec
vec(a::NamedArray) = vec(a.array)

# import Base.rotl90, Base.rot180, Base.rotr90
           
fa(f::Function, a::NamedArray) = NamedArray(f(a), tuple(a.dimnames...), tuple(a.dicts...))
faa(f::Function, a::NamedArray, args...) = NamedArray(f(a, args...), tuple(a.dimnames...), tuple(a.dicts...))

# import Base.inv
# for f in (:inv
