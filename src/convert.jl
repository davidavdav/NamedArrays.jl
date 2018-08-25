## convert.jl Convenience function for type conversion
## (c) 2014 David A. van Leeuwen

## just give me the array!

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

import Base: convert

## from array to namedarray, the fallback constructor
convert(::Type{NamedArray}, a::AbstractArray) = NamedArray(a)
convert(::Type{NamedVector}, a::AbstractArray) = NamedArray(a)

## to array
## array(n::NamedArray) = n.array
## convert{T,N}(::Type{AbstractArray{T,N}}, a::NamedArray{T,N}) = a.array
## convert{T}(::Type{AbstractArray{T}}, a::NamedArray{T}) = a.array
## convert{T,N}(::Type{AbstractArray}, a::NamedArray{T,N}) = a.array

## to other type
convert(::Type{NamedArray{T}}, n::NamedArray) where {T} = NamedArray(T.(n.array), n.dicts, n.dimnames)

@inline convert(::Type{NamedArray}, n::NamedArray) = n
