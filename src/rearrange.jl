## rearrange.jl  methods the manipulated the data inside an NamedArray

## (c) 2013 David A. van Leeuwen

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

## this does ' as well '
import Base.adjoint
function adjoint(a::NamedArray)
    ndims(a) ≤ 2 || error("Number of dimension must be ≤ 2")
    if ndims(a) == 1
        NamedArray(a.array', (["1"], names(a, 1)), ("'", a.dimnames[1]))
    else
        NamedArray(a.array', reverse(a.dicts), reverse(a.dimnames))
    end
end

import Base.reverse
function reverse(a::NamedArray{T,N}; dims::Int=1) where {T,N}
    vdicts = Array{OrderedDict}(undef, N)
    n = size(a,dims)+1
    for i=1:N
        dict = copy(a.dicts[i])
        if i==dims
            newnames = reverse(names(dict))
            empty!(dict)
            for (ind,k) in enumerate(newnames)
                dict[k] = ind
            end
        end
        vdicts[i] = dict
    end
    NamedArray(reverse(a.array, dims=dims), tuple(vdicts...), a.dimnames)
end

import Base.circshift
function circshift(n::NamedArray{T, N}, shifts::Tuple{Vararg{Integer, NT}}) where {T, N, NT}
    shifts = Base.fill_to_length(shifts, 0, Val(N))
    newnames = Tuple(circshift(names(n, i), s) for (i, s) in enumerate(shifts))
    return NamedArray(circshift(n.array, shifts), newnames, n.dimnames)
end
circshift(n::NamedArray, shift::Real) = circshift(n, Tuple(floor(Int, shift)))
circshift(n::NamedArray, shifts::AbstractArray) = circshift(n, Tuple(shifts))
## :' automagically works, how is this possible? it is ctranspose!

import Base.permutedims

function permutedims(v::NamedVector)
    NamedArray(reshape(v.array, (1, length(v.array))),
        (["1"], names(v, 1)),
        ("_", v.dimnames[1]))
end

permutedims(m::NamedMatrix) = permutedims(m, [2, 1])

function permutedims(a::NamedArray, perm::Vector{Int})
    dicts = a.dicts[perm]
    dimnames = a.dimnames[perm]
    NamedArray(permutedims(a.array, perm), dicts, dimnames)
end

permutedims(n::NamedArray, perm::Tuple{Vararg{Int}}) = permutedims(n, collect(perm))

import Base.transpose
transpose(a::NamedVector) = permutedims(a)
transpose(a::NamedArray) = permutedims(a, [2,1])

import Base.vec
vec(a::NamedArray) = vec(a.array)

import Base.rotl90, Base.rot180, Base.rotr90
rotr90(n::NamedArray) = transpose(reverse(n, dims=1))
rotl90(n::NamedArray) = transpose(reverse(n, dims=2))
rot180(n::NamedArray) = NamedArray(rot180(n.array), tuple([reverse(name) for name in names(n)]...), n.dimnames)

import Combinatorics.nthperm, Combinatorics.nthperm!
import Base.permute!, Base.invpermute!, Base.reverse, Base.reverse!
import Random.shuffle, Random.shuffle!

function nthperm(v::NamedVector, n::Int)
    newnames = nthperm(names(v, 1), n)
    NamedArray(nthperm(v.array,n), (newnames,), v.dimnames)
end
function nthperm!(v::NamedVector, n::Int)
    setnames!(v, nthperm(names(v, 1), n), 1)
    nthperm!(v.array, n)
    return v
end
function permute!(v::NamedVector, perm::AbstractVector)
    setnames!(v, names(v, 1)[perm], 1)
    permute!(v.array, perm)
    return v
end
invpermute!(v::NamedVector, perm::AbstractVector) = permute!(v, invperm(perm))
shuffle(v::NamedVector) = permute!(copy(v), randperm(length(v)))
shuffle!(v::NamedVector) = permute!(v, randperm(length(v)))
reverse(v::NamedVector, start::Integer=1, stop::Integer=length(v)) = NamedArray(reverse(v.array, start, stop),  (reverse(names(v, 1), start, stop),), v.dimnames)
function reverse!(v::NamedVector, start::Integer=1, stop::Integer=length(v))
    setnames!(v, reverse(names(v, 1), start, stop), 1)
    reverse!(v.array, start, stop)
    v
end

####################################
# Copied from Base in v1.10
# Works around inference's lack of ability to recognize partial constness
struct DimSelector{dims, T}
    A::T
end
DimSelector{dims}(x::T) where {dims, T} = DimSelector{dims, T}(x)
(ds::DimSelector{dims, T})(i) where {dims, T} = i in dims ? axes(ds.A, i) : (:,)

_negdims(n, dims) = filter(i->!(i in dims), 1:n)
####################################

function my_compute_itspace(A, ::Val{dims}) where {dims}
    negdims = _negdims(ndims(A), dims)
    axs = Iterators.product(ntuple(DimSelector{dims}(A), ndims(A))...)
    vec(permutedims(collect(axs), (dims..., negdims...))), negdims
end

Base.sortslices(A::NamedArray; dims, kws...) =
    _sortslices(A, Val{dims}(), kws...)

function _sortslices(A::NamedArray, d::Val{dims}; kws...) where dims
    itspace, negdims = my_compute_itspace(A, d)
    vecs = map(its->view(A, its...), itspace)
    p = sortperm(vecs; kws...)
    if ndims(A) == 2 && isa(dims, Integer) && isa(A.array, Array)
        # At the moment, the performance of the generic version is subpar
        # (about 5x slower). Hardcode a fast-path until we're able to
        # optimize this.
        return dims == 1 ? A[p, :] : A[:, p]
    else
        B = similar(A)
        for (x, its) in zip(p, itspace)
            B[its...] = vecs[x]
        end
        if ndims(A) == 2
            nd = negdims[1]
            setnames!(B, names(B, nd)[p], nd)
        else
            @warn("Can't keep dimnames in sortslices() for ndims ≠ 2")
        end
        B
    end
end

function Base.filter!(f, n::NamedVector)
    j = firstindex(n)
    for (name, i) in n.dicts[1]
        if f(n.array[i])
            n.array[j] = n.array[i]
            n.dicts[1][name] = j
            j += 1
        else
            delete!(n.dicts[1], name)
        end
    end
    deleteat!(n.array, j:length(n.array))
    return n
end
