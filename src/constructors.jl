## constructors.jl
## (c) 2014 David A. van Leeuwen

## Constructors related to the types in namedarraytypes.jl

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

@compat letter(i) = string(Char((64+i) % 256))

## helpers for constructing names dictionaries
defaultnamesdict(names::Vector) = OrderedDict(zip(names, 1:length(names)))
defaultnamesdict(dim::Integer) = defaultnamesdict([string(i) for i in 1:dim])
defaultnamesdict(dims::NTuple) = map(defaultnamesdict, dims)

## disambiguation (Argh...)
if VERSION ≥ v"0.4-dev"
    NamedArray{T,N}(a::AbstractArray{T,N}, names::Tuple{}, dimnames::NTuple{N}) = NamedArray{T,N,typeof(a),Tuple{}}(a, (), ())
    NamedArray{T,N}(a::AbstractArray{T,N}, names::Tuple{}) = NamedArray{T,N,typeof(a),Tuple{}}(a, (), ())
end

## Basic constructor: array, tuple of dicts, tuple
## This calls the inner constructor with the appropriate types
function NamedArray{T,N}(a::AbstractArray{T,N}, names::NTuple{N,OrderedDict}, dimnames::NTuple{N})
    NamedArray{T, N, typeof(a), typeof(names)}(a, names, dimnames) ## inner constructor
end

## dimnames created as default, then inner constructor called
function NamedArray{T,N}(array::AbstractArray{T,N}, names::NTuple{N,OrderedDict})
    dimnames = [Symbol(letter(i)) for i=1:ndims(array)]
    NamedArray{T, N, typeof(array), typeof(names)}(array, names, tuple(dimnames...)) ## inner constructor
end

## constructor with array, names and dimnames (dict is created from names)
function NamedArray{T,N}(array::AbstractArray{T,N}, names::NTuple{N,Vector}, dimnames::NTuple{N})
    dicts = defaultnamesdict(names)
    NamedArray(array, dicts, dimnames)
end

## constructor with array, names (dict is created from names), dimnames created as default
function NamedArray{T,N}(array::AbstractArray{T,N}, names::NTuple{N,Vector})
    dicts = defaultnamesdict(names)
    dimnames = [Symbol(letter(i)) for i=1:length(names)]
    NamedArray(array, dicts, tuple(dimnames...))
end

## vectors instead of tuples, with defaults
function NamedArray{T,N,VT}(a::AbstractArray{T,N},
                            names::Vector{VT}=[String[string(i) for i=1:d] for d in size(a)],
                            dimnames::Vector = Symbol[Symbol(letter(i)) for i=1:N])
    length(names) == length(dimnames) == N || error("Dimension mismatch")
    if VT <: OrderedDict
        dicts = tuple(names...)
    else
        dicts = defaultnamesdict(tuple(names...))
    end
    NamedArray(a, dicts, tuple(dimnames...))
end


## Type and dimensions
"""
`NamedArray(T::Type, dims::Int...)` creates an uninitialized array with default names
for the dimensions (`:A`, `:B`, ...) and indices (`"1"`, `"2"`, ...).
"""
function NamedArray(T::DataType, dims::Int...)
    ld = length(dims)
    names = [[string(j) for j=1:i] for i=dims]
    dimnames = [@compat Symbol(letter(i)) for i=1:ld]
    a = Array(T, dims...)
    NamedArray(a, tuple(names...), tuple(dimnames...))
end
