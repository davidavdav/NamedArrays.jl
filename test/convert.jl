print("convert, ")

n = NamedArray(randn(5, 10))

@test convert(Array, n) == n.array
@test convert(NamedArray, n) == n

for T in [Float32, Float16]
 	for matrix in (map(T, n), convert(NamedArray{T}, n))
 		@test matrix.array == map(T, n.array)
 		@test names(matrix) == names(n)
 		@test dimnames(matrix) == dimnames(n)
 	end
end

# issue 43

x = @inferred NamedArray(Array([1 2; 3 4]), (["a","b"], [10,11]), (:rows,:cols))
@test convert(Array, x) == x.array

# Test convert don't change array type

using SparseArrays
n_sparray = NamedArray(SparseArrays.sprand(Int, 5, 5, 0.5))
@test isa(n_sparray.array, SparseMatrixCSC{Int,Int})
@test isa(convert(NamedArray{Float64}, n_sparray).array, SparseMatrixCSC{Float64,Int})

using DataFrames

@testset "convert DataFrame <-> NamedArray" begin
	# Test conversions to and from DataFrame.
	cn = convert(DataFrame,n)
	ccn = convert(NamedArray,cn)
	@test cn isa DataFrame
	@test all(map(x-> x in n, cn[!,:Values]))
	@test all(map(x-> x in propertynames(cn), dimnames(n)))
	@test ccn isa NamedArray
	@test ccn == n

	cm = convert(DataFrame,m)
	ccm = convert(NamedArray,cm)
	@test cm isa DataFrame
	@test all(map(x-> x in m, cm[!,:Values]))
	@test all(map(x-> x in propertynames(cm), dimnames(m)))
	@test ccm isa NamedArray
	@test ccm == m
end
