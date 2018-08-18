using IndexedTables

import IndexedTables.NDSparse

function NDSparse(n::NamedArray)
	L = length(n) # elements in array
	cols = Dict{Symbol, Array}()
	factor = 1
	for d in 1:ndims(n)
		nlevels = size(n, d)
		nrep = L ÷ (nlevels * factor)
		data = repeat(vcat([fill(x, factor) for x in names(n, d)]...), nrep)
		cols[Symbol(dimnames(n, d))] = data
		factor *= nlevels
	end
	return NDSparse(Columns(;cols...), array(n)[:])
end
