using .Base: @propagate_inbounds
import .Base:
	size, length, iterate
# Overriding the base iterator gives errors when tested, probably best leave it alone.
#= Base.iterate(n::NamedArray, state=1) = state > length(n) ? nothing : begin  =#
#= 	( (flattenednames(n)[state],n[flattenednames(n)[state]...]), state +1) =#
#= end =#

function enamerate(n::NamedArray, state=1) 
	if state > length(n)
		return nothing
	else
		return ( (flattenednames(n)[state],n[flattenednames(n)[state]...]), state +1)
	end
end

# Named Iterator for NamedArray implemented similarly to enumerate from Iterators.jl

struct Enamerate
    na::NamedArray
end

#TODO: docs
"""
    enamerate(iter)

An iterator that yields `(i, x)` where `i` is a counter starting at 1,
and `x` is the `i`th value from the given iterator. It's useful when
you need not only the values `x` over which you are iterating, but
also the number of iterations so far. Note that `i` may not be valid
for indexing `iter`; it's also possible that `x != iter[i]`, if `iter`
has indices that do not start at 1. See the `pairs(IndexLinear(),
iter)` method if you want to ensure that `i` is an index.

# Examples
```jldoctest
julia> a = ["a", "b", "c"];

julia> for (index, value) in enumerate(a)
           println("\$index \$value")
       end
1 a
2 b
3 c
```
"""
enamerate(n) = Enamerate(n)

length(e::Enamerate) = length(e.na)
size(e::Enamerate) = size(e.na)
@propagate_inbounds function iterate(e::Enamerate, state=(1,))
    i, rest = state[1], tail(state)
    n = iterate(e.na, rest...)
    n === nothing && return n
    #= (i, n[1]), (i+1, n[2]) =#
		return (flattenednames(e.na)[i], n[1]), (flattenednames(e.na)[i+1], n[2])
end

#= eltype(::Type{Enumerate{I}}) where {I} = Tuple{Int, eltype(I)} =#
#= IteratorSize(::Type{Enumerate{I}}) where {I} = IteratorSize(I) =#
#= IteratorEltype(::Type{Enumerate{I}}) where {I} = IteratorEltype(I) =#

#= @inline function iterate(r::Reverse{<:Enumerate}) =#
#=     ri = reverse(r.itr.itr) =#
#=     iterate(r, (length(ri), ri)) =#
#= end =#
#= @inline function iterate(r::Reverse{<:Enumerate}, state) =#
#=     i, ri, rest = state[1], state[2], tail(tail(state)) =#
#=     n = iterate(ri, rest...) =#
#=     n === nothing && return n =#
#=     (i, n[1]), (i-1, ri, n[2]) =#
#= end =#
#=  =#

