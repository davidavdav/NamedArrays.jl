## base.jl base methods for NamedArray

## (c) 2013 David A. van Leeuwen

## This code is licensed under the GNU General Public License, version 2
## See the file LICENSE in this distribution


## copy
import Base.copy
copy{T,N,DT}(a::NamedArray{T,N,DT}) = NamedArray{T, N, DT}(copy(a.array), tuple(a.dimnames...), a.dicts)

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
