## constructors.jl
## (c) 2014 David A. van Leeuwen

## Constructors related to the types in namedarraytypes.jl

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

@compat letter(i) = string(Char((64+i) % 256))

## helpers for constructing names dictionaries
defaultnames(dim::Integer) = map(string, 1:dim)
defaultnamesdict(names::Vector) = OrderedDict(zip(names, 1:length(names)))
defaultnamesdict(dim::Integer) = defaultnamesdict(defaultnames(dim))
defaultnamesdict(dims::NTuple) = map(defaultnamesdict, dims)

defaultdimname(dim::Integer) = Symbol(letter(dim))
defaultdimnames(ndim::Integer) = map(defaultdimname, tuple(1:ndim...))
defaultdimnames(a::AbstractArray) = defaultdimnames(ndims(a))

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
    NamedArray{T, N, typeof(array), typeof(names)}(array, names, defaultdimnames(array)) ## inner constructor
end

## constructor with array, names and dimnames (dict is created from names)
function NamedArray{T,N}(array::AbstractArray{T,N}, names::NTuple{N,Vector}, dimnames::NTuple{N}=defaultdimnames(array))
    dicts = defaultnamesdict(names)
    NamedArray(array, dicts, dimnames)
end

## vectors instead of tuples, with defaults (incl. no names or dimnames at all)
function NamedArray{T,N,VT}(array::AbstractArray{T,N},
                            names::Vector{VT}=[String[string(i) for i=1:d] for d in size(array)],
                            dimnames::Vector = [defaultdimname(i) for i in 1:ndims(array)])
    length(names) == length(dimnames) == N || error("Dimension mismatch")
    if VT <: OrderedDict
        dicts = tuple(names...)
    else
        dicts = defaultnamesdict(tuple(names...))
    end
    NamedArray(array, dicts, tuple(dimnames...))
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
