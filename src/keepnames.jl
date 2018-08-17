## index.jl  methods for NamedArray that keep the names (some checking may be done)

## (c) 2013, 2014, 2017 David A. van Leeuwen

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

# Keep names for consistently named vectors, or drop them
function Base.hcat(N::NamedVecOrMat...)
    keepnames=true
    N1 = N[1]
    firstnames = names(N1, 1)
    for i in 2:length(N)
        keepnames &= names(N[i],1) == firstnames
    end
    a = hcat(map(n -> n.array, N)...)
    if keepnames
        colnames = defaultnamesdict(size(a,2))
        NamedArray(a, (N1.dicts[1], colnames), (N1.dimnames[1], :hcat))
    else
        NamedArray(a)
    end
end

function Base.vcat(N::NamedMatrix...)
    keepnames=true
    N1=N[1]
    firstnames = names(N1,2)
    for i=2:length(N)
        keepnames &= names(N[i],2)==firstnames
    end
    a = vcat(map(a -> a.array, N)...)
    if keepnames
        rownames = defaultnamesdict(size(a,1))
        NamedArray(a, (rownames, N1.dicts[2]), (:vcat, N1.dimnames[2]))
    else
        NamedArray(a)
    end
end

function Base.vcat(N::NamedVector...)
    a = vcat(map(n -> n.array, N)...)
    anames = vcat(map(n -> names(n, 1), N)...)
    if length(unique(anames)) == length(a)
        return NamedArray(a, (anames,), (:vcat,))
    else
        return NamedArray(a, (defaultnamesdict(length(a)),), (:vcat,))
    end
end

if VERSION < v"0.7"
    ## broadcast v0.5
    if isdefined(Base.Broadcast, :broadcast_t)
        function Base.Broadcast.broadcast_t(f, T, n::NamedArray, As...)
            broadcast!(f, similar(n, T, Base.Broadcast.broadcast_shape(n, As...)), n, As...)
        end
    end

    ## broadcast v0.6
    if isdefined(Base.Broadcast, :_containertype)
        Base.Broadcast._containertype(::Type{<:NamedArray}) = NamedArray
    end
    if isdefined(Base.Broadcast, :promote_containertype)
        Base.Broadcast.promote_containertype(::Type{NamedArray}, _) = NamedArray
        Base.Broadcast.promote_containertype(_, ::Type{NamedArray}) = NamedArray
        Base.Broadcast.promote_containertype(::Type{NamedArray}, ::Type{Array}) = NamedArray
        Base.Broadcast.promote_containertype(::Type{Array}, ::Type{NamedArray}) = NamedArray
        Base.Broadcast.promote_containertype(::Type{NamedArray}, ::Type{NamedArray}) = NamedArray
    end
    if isdefined(Base.Broadcast, :broadcast_c)
        array(n::NamedArray) = n.array
        array(a) = a
        function dictstype(n::NamedArray{T,N,AT,DT}, ::Type{Val{M}}) where {T,N,AT,DT,M}
            N > M && error("Cannot truncate array")
            return tuple(n.dicts..., fill(nothing, M - N)...)::NTuple{M, Any}
        end
        dictstype(rest, ::Type{Val{M}}) where {M} = tuple(fill(nothing, M)...)::NTuple{M}
        dictstypejoined(::Void, ::Void) = nothing
        dictstypejoined(t, ::Void) = t
        dictstypejoined(::Void, t) = t
        dictstypejoined(t1, t2) = t1
        function dictstyperecursive(::Type{Val{N}}, t1::Tuple, t2::Tuple) where N
            length(t1) == length(t2) || error("Inconsistent tuple lengths")
            return tuple([dictstypejoined(d1, d2) for (d1, d2) in zip(t1, t2)]...)
        end
        dictstyperecursive(::Type{Val{N}}, t1::Tuple, t2::Tuple, t::Tuple...) where N = dictstyperecursive(Val{N}, dictstyperecursive(Val{N}, t1, t2), t...)
        function Base.Broadcast.broadcast_c(f, t::Type{NamedArray}, As...)
            arrays = [array(a) for a in As]
            res = broadcast(f, arrays...)
            T = eltype(res)
            N = ndims(res)
            AT = typeof(res)
            ## is there a NamedArray with the same dimensions?
            for a in As
                isa(a, NamedArray) && size(a) == size(res) && return NamedArray{T, N, AT, typeof(a.dicts)}(res, a.dicts, a.dimnames)
            end
            ## can we collect the dimensions from individual namedarrays?
            dicts = OrderedDict[]
            dimnames = []
            found = false
            for d in 1:ndims(res)
                found = false
                for a in As
                    if isa(a, NamedArray) && size(a, d) == size(res, d)
                        push!(dicts, a.dicts[d])
                        push!(dimnames, a.dimnames[d])
                        found = true
                        break
                    end
                end
                if !found
                    push!(dicts, defaultnamesdict(size(res, d)))
                    push!(dimnames, defaultdimname(d))
                end
            end
            tdicts = tuple(dicts...)
            return NamedArray{T, N, AT, typeof(tdicts)}(res, tdicts, tuple(dimnames...))
        end
    end
else
    ## broadcast v1.0
    Base.BroadcastStyle(::Type{A}) where {A <: NamedArray} = Broadcast.ArrayStyle{A}()
    function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{A}},
                          ::Type{T}) where {A <: NamedArray, T}
        println("....................")
        namedarray = find_namedarray(bc)
        println(namedarray)
        similar(namedarray, T)
    end


    "`find_namedarray(As)` returns the first NamedArray among the arguments."
    find_namedarray(bc::Base.Broadcast.Broadcasted) = find_namedarray(bc.args)
    function find_namedarray(args::Tuple)
        find_namedarray(find_namedarray(args[1]), Base.tail(args))
    end
    find_namedarray(x::NamedArray) = x
    find_namedarray(a::NamedArray, rest) = a
    find_namedarray(::Any, rest) = find_aac(rest)
end



## reorder names
import Base: sort, sort!
function sort!(v::NamedVector; kws...)
    i = sortperm(v.array; kws...)
    newnames = names(v, 1)[i]
    empty!(v.dicts[1])
    for (ind, k) in enumerate(newnames)
        v.dicts[1][k] = ind
    end
    v.array = v.array[i]
    return v
end

sort(v::NamedVector; kws...) = sort!(copy(v); kws...)

## Note: I can't think of a sensible way to define sort!(a::NamedArray, dim>1)

## drop name of sorted dimension, as each index along that dimension is sorted individually
function sort(n::NamedArray, dim::Integer; kws...)
    if ndims(n)==1 && dim==1
        return sort(n; kws...)
    else
        nms = names(n)
        nms[dim] = [string(i) for i in 1:size(n, dim)]
        return NamedArray(sort(n.array, dim; kws...), tuple(nms...), n.dimnames)
    end
end
