## base.jl base methods for NamedArray

## (c) 2013 David A. van Leeuwen

## This code is licensed under the GNU General Public License, version 2
## See the file LICENSE in this distribution


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
size(a::NamedArray) = size(a.array)
size(a::NamedArray, d) = size(a.array, d)
ndims(a::NamedArray) = ndims(a.array)


## convert, promote
import Base.convert,Base.promote_rule
## to array
convert{T,N}(::Type{Array{T,N}}, A::NamedArray{T,N}) = A.array
convert(::Type{Array}, a::NamedArray) = a.array
## to other type
convert{T}(::Type{NamedArray{T}}, a::NamedArray) = NamedArray(convert(Array{T}, a.array), a.dimnames, a.dicts)
function promote_rule{T1<:Real,T2<:Real,N}(::Type{Array{T1,N}},::Type{NamedArray{T2,N}})
#    println("my rule")
    t = promote_type(T1,T2)
    Array{t,N}
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
