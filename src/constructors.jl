## constructors.jl
## (c) 2014--2020 David A. van Leeuwen

## Constructors related to the types in namedarraytypes.jl

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

letter(i) = string(Char((64+i) % 256))

## helpers for constructing names dictionaries
defaultnames(dim::Integer) = map(string, 1:dim)
function defaultnamesdict(names::AbstractVector)
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

NamedArray(a::AbstractArray{T,N}, names::Tuple{}) where {T,N} = NamedArray{T,N,typeof(a),Tuple{}}(a, (), ())
NamedArray(a::AbstractArray{T,0}, ::Tuple{}, ::Tuple{}) where T = NamedArray{T,0,typeof(a),Tuple{}}(a, (), ())

## Basic constructor: array, tuple of dicts, tuple of dimnames
function NamedArray(array::AbstractArray{T,N},
                    names::NTuple{N,OrderedDict},
                    dimnames::NTuple{N}=defaultdimnames(array)) where {T,N}
    ## inner constructor
    NamedArray{T, N, typeof(array), typeof(names)}(array, names, dimnames)
end

## constructor with array, names and dimnames (dict is created from names)
"""
    NamedArray(a::AbstractArray{T,N}, names::Tuple{N,AbstractVector}, dimnames::NTuple{N,Any}))
    NamedArray(a::AbstractArray{T,N}; names::Tuple{N,AbstractVector}, dimnames::NTuple{N,Any}))

Construct a NamedArray from array `a`, with names for the indices in each dimesion `names`, 
and names of the dimensions `dimnames`. 

If `dimnames` is unspecified, dimensions are named `:A, :B, ...`, 
if `names` are unspecified, names are `"1", "2", "3", ...`.

# Examples
```jldoctest
julia> NamedArray([1 2 3; 4 5 6])
2×3 Named Matrix{Int64}
A ╲ B │ 1  2  3
──────┼────────
1     │ 1  2  3
2     │ 4  5  6


julia> NamedArray([1 2 3; 4 5 6]; names=(["a", "b"], 1:3))
2×3 Named Matrix{Int64}
A ╲ B │ 1  2  3
──────┼────────
a     │ 1  2  3
b     │ 4  5  6


julia> NamedArray([1 2 3; 4 5 6]; dimnames=("rows", "cols"))
2×3 Named Matrix{Int64}
rows ╲ cols │ 1  2  3
────────────┼────────
1           │ 1  2  3
2           │ 4  5  6

julia> NamedArray([1 2; 3 4; 5 6], (["一", "二", "三"], ["first", "second"]), ("cmn", "en"))
3×2 Named Matrix{Int64}
cmn ╲ en │  first  second
─────────┼───────────────
一       │      1       2
二       │      3       4
三       │      5       6
```
"""
function NamedArray(array::AbstractArray{T,N},
                    names::NTuple{N,AbstractVector},
                    dimnames::NTuple{N, Any}=defaultdimnames(array)) where {T,N}
    NamedArray(array; names, dimnames)
end
function NamedArray(array::AbstractArray{T,N};
                    names::NTuple{N,AbstractVector}=tuple((defaultnames(d) for d in size(array))...),
                    dimnames::NTuple{N,Any}=defaultdimnames(array)) where {T,N}
    dicts = defaultnamesdict(names)
    NamedArray{T, N, typeof(array), typeof(dicts)}(array, dicts, dimnames)
end

## Deprecated: use tuples, as above
## vectors instead of tuples, with defaults (incl. no names or dimnames at all)
function NamedArray(array::AbstractArray{T,N},
                    names::AbstractVector{VT},
                    dimnames::AbstractVector=[defaultdimname(i) for i in 1:ndims(array)]) where {T,N,VT}
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

## I can't get this working
## @Base.deprecate NamedArray(array::AbstractArray{T,N}, names::AbstractVector{<:AbstractVector}, dimnames::AbstractVector) where {T,N} NamedArray(array::AbstractArray{T,N}, names::NTuple{N}, dimnames::NTuple{N}) where {T,N}

## special case for 1-dim array to circumvent Julia tuple-comma-oddity, #86
NamedArray(array::AbstractVector{T}, 
           names::AbstractVector{VT}=defaultnames(length(array)), 
           dimname=defaultdimname(1)) where {T,VT} = 
    NamedArray(array, (names,), (dimname,))

function NamedArray(array::AbstractArray{T,N}, names::NamedTuple) where {T, N}
    length(names) == N || error("Dimension mismatch")
    return NamedArray(array, values(names), keys(names))
end

## Type and dimensions
"""
`NamedArray(T::Type, dims::Int...)` creates an uninitialized array with default names
for the dimensions (`:A`, `:B`, ...) and indices (`"1"`, `"2"`, ...).
"""
NamedArray(T::DataType, dims::Int...) = NamedArray(Array{T}(undef, dims...))

NamedArray{T}(n...) where {T} = NamedArray(Array{T}(undef, n...))
