## rearrange.jl  methods the manipulated the dta inside an NamedArray

## (c) 2013 David A. van Leeuwen

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

## this does ' as well '
import Base.ctranspose
function ctranspose(a::NamedArray)
    ndims(a) ≤ 2 || error("Number of dimension must be ≤ 2")
    if ndims(a) == 1
        NamedArray(a.array', (["1"], names(a,1)), ("'", a.dimnames[1]))
    else
        NamedArray(a.array', reverse(a.dicts), reverse(a.dimnames))
    end
end

import Base.flipdim
function flipdim{T,N}(a::NamedArray{T,N}, d::Int)
    vdicts = Array(OrderedDict, N)
    n = size(a,d)+1
    for i=1:N
        dict = copy(a.dicts[i])
        if i==d
            newnames = reverse(names(dict))
            empty!(dict)
            for (ind,k) in enumerate(newnames)
                dict[k] = ind
            end
        end
        vdicts[i] = dict
    end
    NamedArray(flipdim(a.array,d), tuple(vdicts...), a.dimnames)
end

## circshift automagically works...
## :' automagically works, how is this possible? it is ctranspose!

import Base.permutedims
function permutedims(a::NamedArray, perm::Vector{Int})
    dicts = a.dicts[perm]
    dimnames = a.dimnames[perm]
    NamedArray(permutedims(a.array, perm), dicts, dimnames)
end
import Base.transpose
transpose(a::NamedArray) = permutedims(a, [2,1])

import Base.vec
vec(a::NamedArray) = vec(a.array)

import Base.rotl90, Base.rot180, Base.rotr90
rotr90(n::NamedArray) = transpose(flipdim(n, 1))
rotl90(n::NamedArray) = transpose(flipdim(n, 2))
rot180(n::NamedArray) = NamedArray(rot180(n.array), tuple([reverse(name) for name in names(n)]...), n.dimnames)

if VERSION < v"0.5.0-dev"
    import Base.nthperm, Base.nthperm!
else
    import Combinatorics.nthperm, Combinatorics.nthperm!
end
import Base.permute!, Base.ipermute!, Base.shuffle, Base.shuffle!, Base.reverse, Base.reverse!
function nthperm(v::NamedVector, n::Int)
    newnames = nthperm(names(v,1), n)
    NamedArray(nthperm(v.array,n), (newnames,), v.dimnames)
end
function nthperm!(v::NamedVector, n::Int)
    setnames!(v, nthperm(names(v,1), n), 1)
    nthperm!(v.array, n)
    return v
end
function permute!(v::NamedVector, perm::AbstractVector)
    setnames!(v, names(v,1)[perm], 1)
    permute!(v.array, perm)
    return v
end
ipermute!(v::NamedVector, perm::AbstractVector) = permute!(v, invperm(perm))
shuffle(v::NamedVector) = permute!(copy(v), randperm(length(v)))
shuffle!(v::NamedVector) = permute!(v, randperm(length(v)))
reverse(v::NamedVector, start=1, stop=length(v)) = NamedArray(reverse(v.array, start, stop),  (reverse(names(v,1), start, stop),), v.dimnames)
function reverse!(v::NamedVector, start=1, stop=length(v))
    setnames!(v, reverse(names(v,1), start, stop), 1)
    reverse!(v.array, start, stop)
    v
end
