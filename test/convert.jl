print("convert, ")

n = NamedArray(randn(5, 10))

@test array(n) == n.array
@test convert(Array, n) == n.array
@test convert(NamedArray, n) == n

for T in [Float32, Float16]
	for m in (map(T, n), convert(NamedArray{T}, n))
		@test m.array == map(T, n.array)
		@test allnames(m) == allnames(n)
		@test dimnames(m) == dimnames(n)
	end
end
