## names.jl retrieve and set dimension names
## (c) 2013--2020 David A. van Leeuwen

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

import Base.names

## `names` is somewhat loaded, as some of the semantics were transferred tp `fieldnames`
"""
    names(n::NamedArray, [d::Integer])

Extract the names of the indices along dimension `d`, or all dimentsions if `d` is unspecified.

# Example
```jldoctest
julia> n = NamedArray([1, 2, 3], (["one", "二", "trois"],))
3-element Named Vector{Int64}
A     │ 
──────┼──
one   │ 1
二    │ 2
trois │ 3

julia> names(n)
1-element Vector{Vector{String}}:
    ["one", "二", "trois"]
```
"""
names(dict::AbstractDict) = collect(keys(dict))
names(n::NamedArray) = [names(dict) for dict in n.dicts]
names(n::NamedArray, d::Integer) = names(n.dicts[d])
defaultnames(a::AbstractArray) = [defaultnames(a, d) for d in 1:ndims(a)]
defaultnames(a::AbstractArray, d::Integer) = defaultnames(size(a, d))

@deprecate allnames(n::NamedArray) names(n::NamedArray)
@deprecate allnames(a::AbstractArray) defaultnames(a::AbstractArray)

## dimnames gives array, for tuple use n.dimnames
"""
    dimnames(n::NamedArray, [d::Integer])

Return the names of the `d`'th dimension of NamedArray `n`, or of all dimensions if `d` is unspecified.

# Example 

```jldoctest
julia> n = NamedArray([1 2; 3 4; 5 6], (["一", "二", "三"], ["first", "second"]), ("cmn", "en"))
3×2 Named Matrix{Int64}
cmn ╲ en │  first  second
─────────┼───────────────
一       │      1       2
二       │      3       4
三       │      5       6

julia> dimnames(n)
2-element Vector{String}:
"cmn"
"en"
```
"""
dimnames(n::NamedArray) = [n.dimnames...]
dimnames(n::NamedArray, d::Integer) = n.dimnames[d]
dimnames(a::AbstractArray) = [defaultdimnames(a)...]
dimnames(a::AbstractArray, d::Integer) = defaultdimname(d)

## string versions of the above
strnames(dict::AbstractDict) = [sprint(print, name, context=:compact => true) for name in names(dict)]
strnames(n::NamedArray) = [strnames(d) for d in n.dicts]
strnames(n::NamedArray, d::Integer) = strnames(n.dicts[d])
strdimnames(n::NamedArray) = [string(dn) for dn in n.dimnames]
strdimnames(n::NamedArray, d::Integer) = string(n.dimnames[d])


## seting names, dimnames
"""
    setnames!(n::NamedArray, v::Vector{T}, d::Integer)

Set the names of `n` along dimension `d` to `v`.  

The NamedArray `n` must already have names of type `T`

# Example
```jldoctest
julia> n = NamedArray([1 2; 3 4; 5 6])
3×2 Named Matrix{Int64}
A ╲ B │ 1  2
──────┼─────
1     │ 1  2
2     │ 3  4
3     │ 5  6

julia> setnames!(n, ["一", "二", "三"], 1)
(OrderedCollections.OrderedDict{Any, Int64}("一" => 1, "二" => 2, "三" => 3), OrderedCollections.OrderedDict{Any, Int64}("1" => 1, "2" => 2))
```
"""
function setnames!(n::NamedArray{T,N}, v::Vector{KT}, d::Integer) where {T,N,KT}
    size(n.array, d) == length(v) || throw(DimensionMismatch("inconsistent vector length"))
    keytype(n.dicts[d]) == KT || throw(TypeError(:setnames!, "second argument", keytype(n.dicts[d]), KT))
    ## n.dicts is a tuple, so we need to replace it as a whole...
    vdicts = OrderedDict{Any,Int}[]
    for i = 1:length(n.dicts)
        if i==d
            push!(vdicts, OrderedDict(zip(v, 1:length(v))))
        else
            push!(vdicts, n.dicts[i])
        end
    end
    n.dicts = tuple(vdicts...)::NTuple{N}
end

function setnames!(n::NamedArray, v, d::Integer, i::Integer)
    1 <= d <= ndims(n) || throw(BoundsError("dimension"))
    1 <= i <= size(n, d) || throw(BoundsError("index"))
    isa(v, keytype(n.dicts[d])) || throw(TypeError(:setnames!, "second argument", keytype(n.dicts[d]), typeof(v)))
    newnames = names(n, d)
    newnames[i] = v
    setnames!(n, newnames, d)
end

function setdimnames!(n::NamedArray{T,N}, dn::NTuple{N,Any}) where {T,N}
    n.dimnames = dn
end

"""
    setdimnames(n::NamedArray, dimnames::Vector)

Set the dimension names of NamedArray `n` to `dimnames`.

# Example

```jldoctest
julia> n = NamedArray([1 2; 3 4; 5 6])
3×2 Named Matrix{Int64}
A ╲ B │ 1  2
──────┼─────
1     │ 1  2
2     │ 3  4
3     │ 5  6

julia> setdimnames!(n, ["fist", "second"])
("fist", "second")

julia> n
3×2 Named Matrix{Int64}
fist ╲ second │ 1  2
──────────────┼─────
1             │ 1  2
2             │ 3  4
3             │ 5  6
```
"""
setdimnames!(n::NamedArray, dn::Vector) = setdimnames!(n, tuple(dn...))

"""
    setdimnames!(n::NamedArray, name, d::Integer)

Set the name of the dimension `d` of NamedArray `n` to `name`. 

# Example
```jldoctest
julia> n = NamedArray([1 2 3; 4 5 6])
2×3 Named Matrix{Int64}
A ╲ B │ 1  2  3
──────┼────────
1     │ 1  2  3
2     │ 4  5  6

julia> setdimnames!(n, :second, 2)
(:A, :second)

julia> n
2×3 Named Matrix{Int64}
A ╲ second │ 1  2  3
───────────┼────────
1          │ 1  2  3
2          │ 4  5  6
```
"""
function setdimnames!(n::NamedArray{T,N}, v, d::Integer) where {T,N}
    1 <= d <= N || throw(BoundsError(size(n), d))
    vdimnames = Array{Any}(undef, N)
    for i=1:N
        if i==d
            vdimnames[i] = v
        else
            vdimnames[i] = n.dimnames[i]
        end
    end
    n.dimnames = tuple(vdimnames...)
end
