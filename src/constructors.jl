## constructors.jl
## (c) 2014 David A. van Leeuwen

## Constructors related to the types in namedarraytypes.jl

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

## call inner constructor
function NamedArray{T,N}(a::AbstractArray{T,N}, names::NTuple{N,Associative}, dimnames::NTuple{N})
    NamedArray{T, N, typeof(a), typeof(names)}(a, names, dimnames) ## inner constructor
end

## constructor with array, names and dimnames (dict is created from names)
function NamedArray{T,N}(array::AbstractArray{T,N}, names::NTuple{N,Vector}, dimnames::NTuple{N})
    dicts = map(names -> Dict(zip(names,1:length(names))), names)
    NamedArray(array, dicts, dimnames) # call constructor above
end

## Type and dimensions
function NamedArray(T::DataType, dims::Int...)
    ld = length(dims)
    names = [[string(j) for j=1:i] for i=dims]
    dimnames = [symbol(string(char(64+i))) for i=1:ld]
    a = Array(T, dims...)
    NamedArray(a, tuple(names...), tuple(dimnames...))
end

## just an array
function NamedArray(a::AbstractArray)
    names = [[string(j) for j=1:i] for i=size(a)]
    dimnames = [symbol(string(char(64+i))) for i=1:ndims(a)]
    NamedArray(a, tuple(names...), tuple(dimnames...))
end

