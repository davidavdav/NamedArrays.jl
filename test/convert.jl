print("convert, ")

n = NamedArray(randn(5, 10))

@test convert(Array, n) == n.array
# TODO: @test convert(NamedArray, n) == n

for T in [Float32, Float16]
# TODO: 	for m in (map(T, n), convert(NamedArray{T}, n))
# TODO: 		@test m.array == map(T, n.array)
# TODO: 		@test names(m) == names(n)
# TODO: 		@test dimnames(m) == dimnames(n)
# TODO: 	end
end

# issue 43

x = @inferred NamedArray(Array([1 2; 3 4]), (["a","b"], [10,11]), (:rows,:cols))
@test convert(Array, x) == x.array
