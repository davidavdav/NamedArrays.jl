## constructors.jl
## (c) 2014--2017 David A. van Leeuwen

## Constructors related to the types in namedarraytypes.jl

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

letter(i) = string(Char((64+i) % 256))

## helpers for constructing names dictionaries
defaultnames(dim::Integer) = map(string, 1:dim)
function defaultnamesdict(names::Vector)
    dict = OrderedDict(zip(names, 1:length(names)))
    length(dict) == length(names) || error("Cannot have duplicated names for indices")
    return dict
end
defaultnamesdict(dim::Integer) = defaultnamesdict(defaultnames(dim))
defaultnamesdict(dims::Tuple) = map(defaultnamesdict, dims) # ::NTuple{length(dims), OrderedDict}

defaultdimname(dim::Integer) = Symbol(letter(dim))
defaultdimnames(ndim::Integer) = ntuple(defaultdimname, ndim)
defaultdimnames(a::AbstractArray) = defaultdimnames(ndims(a))

## disambiguation (Argh...)
function NamedArray(a::AbstractArray{T,N},
                    names::Tuple{},
                    dimnames::NTuple{N, Any}) where {T,N}
    NamedArray{T,N,typeof(a),Tuple{}}(a, (), ())
end

function NamedArray(a::AbstractArray{T,N}, names::Tuple{}) where {T,N}
    NamedArray{T,N,typeof(a),Tuple{}}(a, (), ())
end

## Basic constructor: array, tuple of dicts
## dimnames created as default, then inner constructor called
function NamedArray(array::AbstractArray{T,N},
                    names::NTuple{N,OrderedDict}) where {T,N}
    ## inner constructor
    NamedArray{T, N, typeof(array), typeof(names)}(array, names, defaultdimnames(array))
end

## constructor with array, names and dimnames (dict is created from names)
function NamedArray(array::AbstractArray{T,N},
                    names::NTuple{N,Vector},
                    dimnames::NTuple{N, Any}=defaultdimnames(array)) where {T,N}
    dicts = defaultnamesdict(names)
    NamedArray{T, N, typeof(array), typeof(dicts)}(array, dicts, dimnames)
end

## vectors instead of tuples, with defaults (incl. no names or dimnames at all)
function NamedArray(array::AbstractArray{T,N},
                    names::Vector{VT}=[defaultnames(d) for d in size(array)],
                    dimnames::Vector=[defaultdimname(i) for i in 1:ndims(array)]) where
                    {T,N,VT}
    length(names) == length(dimnames) == N || error("Dimension mismatch")
    if VT == Union{} ## edge case, array == Array{}()
        dicts = ()
    elseif VT <: OrderedDict
        dicts = tuple(names...)
    else
        dicts = defaultnamesdict(tuple(names...))::NTuple{N, OrderedDict{eltype(VT),Int}}
    end
    NamedArray{T, N, typeof(array), typeof(dicts)}(array, dicts, tuple(dimnames...))
end


## Type and dimensions
"""
`NamedArray(T::Type, dims::Int...)` creates an uninitialized array with default names
for the dimensions (`:A`, `:B`, ...) and indices (`"1"`, `"2"`, ...).
"""
NamedArray(T::DataType, dims::Int...) = NamedArray(Array{T}(undef, dims...))

NamedArray{T}(n...) where {T} = NamedArray(Array{T}(undef, n...))
