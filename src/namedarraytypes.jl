## namedarraytypes.jl.
## (c) 2013 David A. van Leeuwen

## Julia type that implements a drop-in replacement of Array with named dimensions. 

## This code is licensed under the GNU General Public License, version 2
## See the file LICENSE in this distribution

## DT is a tuple of Dicts, characterized by the types of the keys. 
## The inner constructor checks for consistency, the values must all be 1:d
type NamedArray{T,N,S,DT} <: AbstractArray{T,N}
    array::Array{T,N}
    dimnames::Vector{S}
    dicts::DT
    function NamedArray(array::Array{T,N}, dimnames::NTuple{N,S}, dicts::NTuple{N,Dict})
        size(array) == map(length, dicts) || error("Inconsistent dictionary sizes")
        for (d,dict) in zip(size(array),dicts)
            Set(values(dict)) == Set(1:d) || error("Inconsistent values in dict")
        end
        vdimnames = [name for name in dimnames]
        new(array, vdimnames, dicts)
    end
end


## a type that encapsulated any other type as a name
immutable Names
    names::Vector
    exclude::Bool
end

typealias NamedVector{T} NamedArray{T,1}
typealias NamedMatrix{T} NamedArray{T,2}
typealias ArrayOrNamed{T,N} Union(Array{T,N}, NamedArray{T,N})
typealias IndexOrNamed Union(Real, Range1, String, Names, AbstractVector)
