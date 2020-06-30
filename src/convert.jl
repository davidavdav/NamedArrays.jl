## convert.jl Convenience function for type conversion
## (c) 2014 David A. van Leeuwen

## just give me the array!

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

import Base: convert

## from array to namedarray, the fallback constructor
convert(::Type{NamedArray}, a::AbstractArray) = NamedArray(a)
convert(::Type{NamedVector}, a::AbstractArray) = NamedArray(a)

## to array
## array(n::NamedArray) = n.array
## convert{T,N}(::Type{AbstractArray{T,N}}, a::NamedArray{T,N}) = a.array
## convert{T}(::Type{AbstractArray{T}}, a::NamedArray{T}) = a.array
## convert{T,N}(::Type{AbstractArray}, a::NamedArray{T,N}) = a.array

## to other type
convert(::Type{NamedArray{T}}, n::NamedArray) where {T} = NamedArray(T.(n.array), n.dicts, n.dimnames)

@inline convert(::Type{NamedArray}, n::NamedArray) = n

#= """ =#
#= Conversion from a Dict to a NamedArray. =#
#= """ =#
#= function convert(t::Type{NamedArray}, dict::Dict{K,V}) where {K,V} =#
#= 	allkeys = collect(keys(dict)) =#
#= 	allvalues = collect(values(dict)) =#
#= 	return NamedArray(allvalues, allkeys, (:keys)) =#
#= end =#

using DataFrames
"""
Converts a NamedArray to a DataFrame.

"""
function convert(t::Type{DataFrame}, n::NamedArray{V}; valueCol = :Values) where {V}
	mydimnames = n.dimnames
	mytypes = map(dict->eltype(keys(dict)),n.dicts)
	dfArgs = map((d,t)-> d=>t[], mydimnames, mytypes)
	dfArgs = (dfArgs..., valueCol => V[])
	df = DataFrame(dfArgs...)
	map(tup -> push!(df,(tup[1]...,tup[2])),enamerate(n))
	return df
end

"""
Converts a DataFrame to a NamedArray.
"""
function convert(t::Type{NamedArray}, df::DataFrame; valueCol = :Values)
	newdimnames = propertynames(df)
	deleteat!(newdimnames,findfirst(x->x==:Values,newdimnames))
	names = map(dn->unique(df[!,dn]),newdimnames)
	lengths = map(length,names)
	println(names)
	newna = NamedArray( reshape(df[!,valueCol], lengths...), tuple(names...), tuple(newdimnames...))
	return newna
end
