using .Base: 
	@propagate_inbounds, tail
import .Base:
	size, length, iterate, IteratorSize

struct Enamerate
    na::NamedArray
end

#TODO: docs
"""
    enamerate(iter)

An iterator that yields `(n, x)` where `n` is a tuple corresponding to
the names in the corresponding dimension of value x. Similar to enumerate
but with names.
"""
enamerate(n::NamedArray) = Enamerate(n)

length(e::Enamerate) = length(e.na)
size(e::Enamerate) = size(e.na)
@propagate_inbounds function iterate(e::Enamerate, state=(1,))
    i, rest = state[1], tail(state)
    n = iterate(e.na, rest...)
    n === nothing && return n
    #= (i, n[1]), (i+1, n[2]) =#
		return (flattenednames(e.na)[i], n[1]), (i+1, n[2])
end

# Possibly TODO:
# adapt this from enumerate
# eltype(::Type{Enumerate{I}}) where {I} = Tuple{Int, eltype(I)}
# IteratorSize(::Type{Enumerate{I}}) where {I} = IteratorSize(I)
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

