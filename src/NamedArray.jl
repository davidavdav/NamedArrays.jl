## This is just an attempt to see if we can do named arrays

## type definition
require("named/namedarraytypes.jl")

## seting names, dimnames
function setnames!(a::NamedArray, v::Vector, d::Int)
    @assert length(a.names[d]) == length(v)
    a.names[d] = v
end

## copy
import Base.copy
copy(A::NamedArray) = NamedArray{typeof(A[1]),length(A.names)}(copy(A.array), copy(A.names), copy(A.dimnames))

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

## convert, promote
## I don't understand how to do this
import Base.convert,Base.promote_rule
convert(::Type{Array}, A::NamedArray) = A.array
promote_rule(::Type{Array},::Type{NamedArray}) = Array
+(x::Array, y::NamedArray) = +(promote(x,y)...)
function *(x::NamedArray, y::Number) 
    r = copy(x)
    r.array *= y
end
.*(y::Number, x::NamedArray) = *(x,y)
.*(x::NamedArray, y::Number) = *(x,y)
*(y::Number, x::NamedArray) = *(x,y)

import Base.print, Base.show
print(A::NamedArray) = print(A.array)
function show(io::IO, A::NamedArray)
    println(io, typeof(A))
    print(io, "names: ")
    for (n in A.names) print(io, n') end
    println(io, "dimnames: ", A.dimnames')
    println(io, A.array)
end

import Base.size, Base.ndims
size(a::NamedArray) = arraysize(a.array)
size(a::NamedArray, d) = arraysize(a.array, d)
ndims(a::NamedArray) = ndims(a.array)

import Base.similar
function similar(A::NamedArray, t::DataType, dims::NTuple)
    if size(A) != dims
        return NamedArray(t, dims...) # re-initialize names arrays...
    else
        return NamedArray(t, A.names, A.dimnames)
    end
end
#similar(A::NamedArray, t::DataType, dims::Int...) = similar(A, t, dims)
#similar(A::NamedArray, t::DataType) = similar(A, t, size(A.array))
#similar(A::NamedArray) = similar(A, eltype(A.array), size(A.array))

import Base.getindex, Base.to_index

## sting indexed arrays, single elements: drop names
getindex(A::NamedArray, s0::String) = getindex(A, A.dicts[1][s0])
getindex(A::NamedArray, s::String...) = getindex(A, map(function(t) A.dicts[t[1]][t[2]] end, zip(1:length(s), s))...)

## I'm not sure this is the right name...
## This function takes a range or vector of ints or vector of strings, 
## and returns a range or vector of ints, suitable for indexing using traditional 
## array indexing
import Base.indices
function indices(dict::Dict, I::IndexOrNamed)
    if isa(I, Real)
        return I:I
    elseif isa(I, Range)
        return I                # eltype(Range1) is always <: Real
    elseif isa(I, String)
        dI = dict[I]
        return dI:dI
    elseif isa(I, AbstractVector)
        if eltype(I) <: String
            return map(function(s) dict[s] end, I)
        elseif eltype(I) <: Real
            return I
        else
            error("Unsupported vector type ", eltype(I))
        end
    end
end

getindex(A::NamedArray, i0::Real) = arrayref(A.array,to_index(i0))
## for Ranges or Arrays we do an effort keep names
function getindex(A::NamedArray, I::IndexOrNamed...)
    ## This is not completely safe...
    ## II = map(function(i) indices(A.dicts[i], I[i]) end, 1:length(I))
    II = vec2tuple([indices(A.dicts[i], I[i]) for i=1:length(I)]...)
    a = getindex(A.array, II...)
    if ndims(a) != ndims(A); return a; end # number of dimension changed
    @assert ndims(A) == length(II)
    names = map(function(i) getindex(A.names[i],II[i]) end, 1:length(II))
    NamedArray{eltype(a),ndims(a)}(a, vec2tuple(names...), vec2tuple(A.dimnames...))
end


## These seem to be caught by the general getindex, I'm not sure if this is what we want...
getindex(A::NamedArray, i0::Real) = arrayref(A.array,to_index(i0))
getindex(A::NamedArray, i0::Real, i1::Real) = arrayref(A.array,to_index(i0),to_index(i1))
getindex(A::NamedArray, i0::Real, i1::Real, i2::Real) =
    arrayrefNamed(A.array,to_index(i0),to_index(i1),to_index(i2))
getindex(A::NamedArray, i0::Real, i1::Real, i2::Real, i3::Real) =
    arrayrefNamed(A.array,to_index(i0),to_index(i1),to_index(i2),to_index(i3))
getindex(A::NamedArray, i0::Real, i1::Real, i2::Real, i3::Real,  i4::Real) =
    arrayrefNamed(A.array,to_index(i0),to_index(i1),to_index(i2),to_index(i3),to_index(i4))
getindex(A::NamedArray, i0::Real, i1::Real, i2::Real, i3::Real,  i4::Real, i5::Real) =
    arrayrefNamed(A.array,to_index(i0),to_index(i1),to_index(i2),to_index(i3),to_index(i4),to_index(i5))

getindex(A::NamedArray, i0::Real, i1::Real, i2::Real, i3::Real,  i4::Real, i5::Real, I::Int...) =
    arrayref(A.array,to_index(i0),to_index(i1),to_index(i2),to_index(i3),to_index(i4),to_index(i5),I...)


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
    II = vec2tuple([indices(A.dicts[i], I[i]) for i=1:length(I)]...)
    setindex!(A.array, x, II...)
end

function hcat{T}(V::NamedVector{T}...) 
    keepnames=true
    V1=V[1]
    names = V1.names
    for i=2:length(V)
        keepnames &= V[i].names==names
    end
    a = hcat(map(function(a) a.array end,V)...)
    if keepnames
        colnames = [string(i) for i=1:size(a,2)]
        NamedArray(a, (names[1], colnames), (V1.dimnames[1], "hcat"))
    else
        NamedArray(a)
    end
end
