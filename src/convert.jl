## convert.jl Convenience function for type conversion
## (c) 2014 David A. van Leeuwen

## just give me the array!

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

import Base: convert, promote_rule

## from array to namedaraay, the fallback constructor
convert(::Type{NamedArray}, a::AbstractArray) = NamedArray(a)
convert(::Type{NamedVector}, a::AbstractArray) = NamedArray(a)

## to array
array(n::NamedArray) = n.array
## convert{T,N}(::Type{AbstractArray{T,N}}, a::NamedArray{T,N}) = a.array
## convert{T}(::Type{AbstractArray{T}}, a::NamedArray{T}) = a.array
## convert(::Type{AbstractArray}, a::NamedArray) = a.array

## to other type
convert{T}(::Type{NamedArray{T}}, n::NamedArray) = NamedArray(convert(Array{T}, n.array), n.dicts, n.dimnames)
function promote_rule{T1<:Real,T2<:Real,N}(::Type{Array{T1,N}}, ::Type{NamedArray{T2,N}})
#    println("my rule")
    t = promote_type(T1,T2)
    Array{t,N}
end

## convenience functions
##if VERSION < v"0.4-dev"
##    for tf in [:float16, :float32, :float64, :complex32, :complex64, :complex128]
##        eval(Expr(:import, :Base, tf))
##        @eval ($tf)(a::NamedArray) = NamedArray(($tf)(a.array), a.dicts, a.dimnames)
##    end
##end
