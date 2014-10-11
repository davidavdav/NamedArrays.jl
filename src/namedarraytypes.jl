## namedarraytypes.jl.
## (c) 2013 David A. van Leeuwen

## Julia type that implements a drop-in replacement of Array with named dimensions. 

## This code is licensed under the GNU General Public License, version 2
## See the file LICENSE in this distribution

## The inner constructor assumes all elements exiisting
type NamedArray{T,N} <: AbstractArray{T,N}
    array::Array{T,N}
#    names::Vector{Vector}
    dimnames::Vector
    dicts::Vector{Dict}
    function NamedArray(array::Array{T,N}, dimnames::NTuple{N,String}, dicts::NTuple{N,Dict})
#        vnames = [name for name in names] # make this a vector
        vdimnames = [name for name in dimnames]
        vdicts = [dict for dict in dicts]
        new(array, vdimnames, vdicts)
    end
end
## vector version of above
NamedArray{S<:String}(array::Array, dimnames::Vector{S}, dicts::Vector{Dict}) = NamedArray(array, tuple(dimnames...), tuple(dicts...))

## constructor with array, names and dimnames (dict is created from names)
## first outer
function NamedArray{T,N}(array::Array{T,N}, names::NTuple{N,Vector}, dimnames::NTuple{N, String})
    @assert size(array)==map(length, names)
    dicts = map(names -> Dict(zip(names,1:length(names))), names)
    NamedArray{T,N}(array, dimnames, dicts) # call inner constructor
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

#function NamedArray{T}(::Type{T}, names::Vector, dimnames::Vector)
#    @assert length(names) == length(dimnames)
#    NamedArray(T, tuple(names...), tuple(dimnames...))
#end
    
function NamedArray(T::DataType, dims::Int...)
    ld = length(dims)
    names = [[string(j) for j=1:i] for i=dims]
    dimnames = [string(char(64+i)) for i=1:ld]
    NamedArray(T, tuple(names...), tuple(dimnames...))
end

function NamedArray(a::Array) 
    names = [[string(j) for j=1:i] for i=size(a)]
    dimnames = [string(char(64+i)) for i=1:ndims(a)]
    NamedArray(a, tuple(names...), tuple(dimnames...))
end

## a type that encapsulated any other type as a name
immutable Names
    names::Vector
    exclude::Bool
end

Names(names::Vector) = Names(names, false)

## This is a construction that allows you to say somethong like
## n[!"one",2] or n[!["one", "two"], 2]
## We might, for consistency, decide to do this with "-" instead of !
import Base.!
!(names::Names) = Names(names.names, !names.exclude)
!{T<:String}(names::Vector{T}) = !Names(names)
!(name::String) = !Names([name])

typealias NamedVector{T} NamedArray{T,1}
typealias ArrayOrNamed{T} Union(Array{T}, NamedArray{T})
typealias IndexOrNamed Union(Real, Range1, String, Names, AbstractVector)
