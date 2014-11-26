## constructors.jl
## (c) 2014 David A. van Leeuwen

## Constructors related to the types in namedarraytypes.jl

## call inner constructor
function NamedArray{T,N}(a::Array{T,N}, names::NTuple{N,Dict}, dimnames::NTuple{N})
    NamedArray{T, N, typeof(names)}(a, names, dimnames) ## inner constructor
end

## constructor with array, names and dimnames (dict is created from names)
function NamedArray{T,N}(array::Array{T,N}, names::NTuple{N,Vector}, dimnames::NTuple{N})
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
function NamedArray(a::Array) 
    names = [[string(j) for j=1:i] for i=size(a)]
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

