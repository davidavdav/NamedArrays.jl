## constructors.jl
## (c) 2014 David A. van Leeuwen

## Constructors related to the types in namedarraytypes.jl

## temporary compatibility hack
if VERSION < v"0.4.0-dev"
    Base.Dict(z::Base.Zip2) = Dict(z.a, z.b)
end

## constructor with array, names and dimnames (dict is created from names)
function NamedArray{T,N}(array::Array{T,N}, names::NTuple{N,Vector}, dimnames::NTuple{N})
    @assert size(array)==map(length, names)
    dicts = map(names -> Dict(zip(names,1:length(names))), names)
    NamedArray{T,N,typeof(dicts)}(array, dimnames, dicts) # call inner constructor
end

function NamedArray(a::Array, names::NTuple, dimnames::NTuple)
    @assert ndims(a)==length(names)==length(dimnames)
    println(typeof(dimnames), typeof(names))
    NamedArray{eltype(a),ndims(a)}(a, names, dimnames)
end

function NamedArray(T::DataType, dims::Int...)
    ld = length(dims)
    names = [[symbol(string(j)) for j=1:i] for i=dims]
    dimnames = [symbol(string(char(64+i))) for i=1:ld]
    NamedArray(T, tuple(names...), tuple(dimnames...))
end

function NamedArray(a::Array) 
    names = [[symbol(string(j)) for j=1:i] for i=size(a)]
    dimnames = [symbol(string(char(64+i))) for i=1:ndims(a)]
    NamedArray(a, tuple(names...), tuple(dimnames...))
end

## Names constructors

Names(names::Vector) = Names(names, false)

## This is a construction that allows you to say somethong like
## n[!"one",2] or n[!["one", "two"], 2]
## We might, for consistency, decide to do this with "-" instead of !
import Base.!
!(names::Names) = Names(names.names, !names.exclude)
!{T<:String}(names::Vector{T}) = !Names(names)
!(name::String) = !Names([name])

