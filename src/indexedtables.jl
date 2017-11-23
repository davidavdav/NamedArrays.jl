using IndexedTables

import IndexedTables.IndexedTable

function IndexedTable(n::NamedArray)
	L = length(n) # elements in array
	cols = Dict{Symbol, Array}()
	factor = 1
	for d in 1:ndims(n)
		nlevels = size(n, d)
		nrep = L ÷ (nlevels * factor)
		data = repmat(vcat([fill(x, factor) for x in names(n, d)]...), nrep)
		cols[Symbol(dimnames(n, d))] = data
		factor *= nlevels
	end
	return IndexedTable(Columns(;cols...), array(n)[:])
end
