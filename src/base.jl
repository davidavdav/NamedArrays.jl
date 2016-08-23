## base.jl base methods for NamedArray

## (c) 2013 David A. van Leeuwen

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

## copy
import Base: copy, copy!
copy{T,N,AT,DT}(a::NamedArray{T,N,AT,DT}) = NamedArray{T,N,AT,DT}(copy(a.array), deepcopy(a.dicts), identity(a.dimnames))

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

function Base.similar(a::NamedArray, t::Type, dims::Base.Dims)
    if size(a) != dims
        return NamedArray(t, dims...) # re-initialize names arrays...
    else
        return NamedArray(similar(a.array, t), a.dicts, a.dimnames)
    end
end
#similar(A::NamedArray, t::DataType, dims::Int...) = similar(A, t, dims)
#similar(A::NamedArray, t::DataType) = similar(A, t, size(A.array))
#similar(A::NamedArray) = similar(A, eltype(A.array), size(A.array))

## our own interpretation of ind2sub
Base.ind2sub(n::NamedArray, index::Integer) = tuple(map(x -> names(n, x[1])[x[2]], enumerate(ind2sub(size(n), index)))...)

## simplified text representation of namedarray
Base.writedlm(io, n::NamedVecOrMat) = writedlm(io, hcat(names(n,1), n.array))
