## constructors.jl
## (c) 2014 David A. van Leeuwen

## Constructors related to the types in namedarraytypes.jl

## vector version of above, this would be the normal way of initialization with dicts
function NamedArray{T,N,S}(a::Array{T,N}, dimnames::Vector{S}, dicts::Vector{Dict}) 
    tdicts = tuple(dicts...)
    NamedArray{T,N,S,typeof(tdicts)}(a, tuple(dimnames...), tdicts)
end

## temporary compatibility hack
if VERSION < v"0.4.0-dev"
    Base.Dict(z::Base.Zip2) = Dict(z.a, z.b)
end

## constructor with array, names and dimnames (dict is created from names)
function NamedArray{T,N,S}(array::Array{T,N}, names::NTuple{N,Vector}, dimnames::NTuple{N,S})
    @assert size(array)==map(length, names)
    dicts = map(names -> Dict(zip(names,1:length(names))), names)
    NamedArray{T,N,S,typeof(dicts)}(array, dimnames, dicts) # call inner constructor
end
## vector version
NamedArray{S<:String}(array::Array, names::Vector, dimnames::Vector{S}) = NamedArray(array, tuple(names...), tuple(dimnames...))
## type constructor
function NamedArray{T,N}(::Type{T}, names::NTuple{N,Vector},dimnames::NTuple{N,String})
    array = Array(T,map(length,names))
    NamedArray(array, names, dimnames) # call first outer constructor
end
## vector version
NamedArray{T,S<:String}(::Type{T}, names::Vector, dimnames::Vector{S}) = NamedArray(T, tuple(names...), tuple(dimnames...))

function NamedArray(a::Array, names::NTuple, dimnames::NTuple)
    @assert ndims(a)==length(names)==length(dimnames)
#    @assert eltype(names) <: Vector
#    @assert eltype(dimnames) <: String
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

