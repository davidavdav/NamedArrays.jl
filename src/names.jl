## names.jl retrieve and set dimension names
## (c) 2013 David A. van Leeuwen

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

import Base.names

## `names` is somewhat loaded, as some of the semantics were transferred tp `fieldnames`
names(dict::Associative) = collect(keys(dict))
names(n::NamedArray) = [names(dict) for dict in n.dicts]
names(n::NamedArray, d::Integer) = names(n.dicts[d])
defaultnames(a::AbstractArray) = [defaultnames(a, d) for d in 1:ndims(a)]
defaultnames(a::AbstractArray, d::Integer) = defaultnames(size(a, d))

@deprecate allnames(n::NamedArray) names(n::NamedArray)
@deprecate allnames(a::AbstractArray) defaultnames(a::AbstractArray)

## dimnames gives array, for tuple use n.dimnames
dimnames(n::NamedArray) = [n.dimnames...]
dimnames(n::NamedArray, d::Integer) = n.dimnames[d]
dimnames(a::AbstractArray) = [defaultdimnames(a)...]
dimnames(a::AbstractArray, d::Integer) = defaultdimname(d)

## string versions of the above
strnames(dict::Associative) = [isa(name, String) ? name : sprint(showcompact, name) for name in names(dict)]
strnames(n::NamedArray) = [strnames(d) for d in n.dicts]
strnames(n::NamedArray, d::Integer) = strnames(n.dicts[d])
strdimnames(n::NamedArray) = [string(dn) for dn in n.dimnames]
strdimnames(n::NamedArray, d::Integer) = string(n.dimnames[d])


## seting names, dimnames
function setnames!(n::NamedArray, v::Vector, d::Integer)
    size(n.array, d) == length(v) || throw(DimensionMismatch("inconsistent vector length"))
    keytype(n.dicts[d]) == eltype(v) || throw(TypeError(:setnames!, "second argument", keytype(n.dicts[d]), eltype(v)))
    ## n.dicts is a tuple, so we need to replace it as a whole...
    vdicts = OrderedDict[]
    for i = 1:length(n.dicts)
        if i==d
            push!(vdicts, OrderedDict(zip(v, 1:length(v))))
        else
            push!(vdicts, n.dicts[i])
        end
    end
    n.dicts = tuple(vdicts...)
end

function setnames!(n::NamedArray, v, d::Integer, i::Integer)
    1 <= d <= ndims(n) || throw(BoundsError("dimension"))
    1 <= i <= size(n, d) || throw(BoundsError("index"))
    isa(v, keytype(n.dicts[d])) || throw(TypeError(:setnames!, "second argument", keytype(n.dicts[d]), typeof(v)))
    filter!((k,v) -> v!=i, n.dicts[d]) # remove old name
    n.dicts[d][v] = i
end

function setdimnames!{T,N}(n::NamedArray{T,N}, dn::NTuple{N})
    n.dimnames = dn
end

setdimnames!(n::NamedArray, dn::Vector) = setdimnames!(n, tuple(dn...))

function setdimnames!{T,N}(n::NamedArray{T,N}, v, d::Integer)
    1 <= d <= N || throw(BoundsError(size(n), d))
    vdimnames = Array(Any, N)
    for i=1:N
        if i==d
            vdimnames[i] = v
        else
            vdimnames[i] = n.dimnames[i]
        end
    end
    n.dimnames = tuple(vdimnames...)
end
