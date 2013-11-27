## rearrange.jl  methods the manipulated the dta inside an NamedArray

## (c) 2013 David A. van Leeuwen

## This code is licensed under the GNU General Public License, version 2
## See the file LICENSE in this distribution

## this does ' as well '
import Base.ctranspose
function ctranspose(a::NamedArray) 
    @assert ndims(a)<=2
    if ndims(a)==1
        NamedArray(a.array', (["1"], names(a)[1],), ("'", a.dimnames[1],))
    else
        NamedArray(a.array', reverse(names(a)), reverse(a.dimnames))
    end
end

import Base.flipdim
function flipdim(a::NamedArray, d::Int) 
    newdicts = copy(a.dicts)
    newdicts[d] = copy(a.dicts[d])
    n = size(a,d)+1
    for (k,v) in collect(newdicts[d])
        newdicts[d][k] = n - v
    end
    NamedArray(flipdim(a.array,d), a.dimnames, newdicts)
end

## circshift automagically works...
## :' automagically works, how is this possible? it is ctranspose!

import Base.permutedims
function permutedims(a::NamedArray, perm::Vector{Int})
    newdicts = a.dicts[perm]
    newdimnames = a.dimnames[perm]
    NamedArray(permutedims(a.array, perm), newdimnames, newdicts)
end
import Base.transpose
transpose(a::NamedArray) = permutedims(a, [2,1])

import Base.vec
vec(a::NamedArray) = vec(a.array)

import Base.rotl90, Base.rot180, Base.rotr90
rotr90(a::NamedArray) = transpose(flipud(a))
rotl90(a::NamedArray) = transpose(fliplr(a))
rot180(a::NamedArray) = fliplr(flipud(a))

import Base.nthperm, Base.nthperm!, Base.permute!, Base.ipermute!, Base.shuffle, Base.shuffle!, Base.reverse, Base.reverse!
function nthperm(v::NamedVector, n::Int)
    newnames = nthperm(names(v)[1], n)
    NamedArray(nthperm(v.array,n), (newnames,), (v.dimnames[1],))
end
function nthperm!(v::NamedVector, n::Int) 
    setnames!(v, nthperm(names(v)[1], n), 1)
    nthperm!(v.array,n)
    v
end
function permute!(v::NamedVector, perm::AbstractVector)
    setnames!(v, names(v)[1][perm], 1)
    permute!(v.array, perm)
    v
end
ipermute!(v::NamedVector, perm::AbstractVector) = permute!(v, iperm(perm))
shuffle(v::NamedVector) = permute!(copy(v), randperm(length(v)))
shuffle!(v::NamedVector) = permute!(v, randperm(length(v)))
reverse(v::NamedVector, start=1, stop=length(v)) = NamedArray(reverse(v.array, start, stop), (reverse(names(v)[1], start, stop),), (v.dimnames[1],))
function reverse!(v::NamedVector, start=1, stop=length(v))
    setnames!(v, reverse(names(v)[1], start, stop), 1)
    reverse!(v.array, start, stop)
    v
end
           
