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

n_sparray = NamedArray(SparseArrays.sprand(Int, 5, 5, 0.5))
@test isa(n_sparray.array, SparseMatrixCSC{Int,Int})
@test isa(convert(NamedArray{Float64}, n_sparray).array, SparseMatrixCSC{Float64,Int})
