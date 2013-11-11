type NamedArray{T,N} <: AbstractArray{T,N}
    array::Array{T,N}
    names::Vector{Vector}
    dimnames::Vector
    dicts::Array{Dict}
    function NamedArray(array::Array{T,N}, names::NTuple{N,Vector}, dimnames::NTuple{N,String})
        @assert size(array)==map(length, names)
        vnames = [name for name in names] # make this a vector
        vdimnames = [name for name in dimnames]
        dicts = [Dict(n,1:length(n)) for n in names]
        new(array, vnames, vdimnames, dicts)
    end
end
function NamedArray{T,N}(::Type{T}, names::NTuple{N,Vector},dimnames::NTuple{N,String})
    array = Array(T,map(length,names))
    NamedArray{T,N}(array, names, dimnames)
end
function NamedArray(a::Array, names::NTuple, dimnames::NTuple)
    @assert ndims(a)==length(names)==length(dimnames)
#    @assert eltype(names) <: Vector
#    @assert eltype(dimnames) <: String
    NamedArray{eltype(a),ndims(a)}(a, names, dimnames)
end

vec2tuple(x...) = x

function NamedArray{T}(::Type{T}, names::Vector, dimnames::Vector)
    @assert length(names) == length(dimnames)
    NamedArray(T, vec2tuple(names...), vec2tuple(dimnames...))
end
    
function NamedArray(T::DataType, dims::Int...)
    ld = length(dims)
    names = [[string(j) for j=1:i] for i=dims]
    dimnames = [string(char(64+i)) for i=1:ld]
    NamedArray(T, vec2tuple(names...), vec2tuple(dimnames...))
end

function NamedArray(a::Array) 
    names = [[string(j) for j=1:i] for i=size(a)]
    dimnames = [string(char(64+i)) for i=1:ndims(a)]
    NamedArray(a, vec2tuple(names...), vec2tuple(dimnames...))
end
    

typealias NamedVector{T} NamedArray{T,1}
typealias ArrayOrNamed{T} Union(Array{T}, NamedArray{T})
typealias IndexOrNamed Union(Real, Range1, String, AbstractVector)