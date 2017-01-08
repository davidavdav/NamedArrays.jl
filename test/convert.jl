print("convert, ")

n = NamedArray(randn(5, 10))

@test array(n) == n.array
@test convert(Array, n) == n.array
@test convert(NamedArray, n) == n

for T in [Float32, Float16]
	for m in (map(T, n), convert(NamedArray{T}, n))
		@test m.array == map(T, n.array)
		@test names(m) == names(n)
		@test dimnames(m) == dimnames(n)
	end
end

# issue 43

x = NamedArray(Array([1 2; 3 4]), (["a","b"], [10,11]), (:rows,:cols))
@test convert(Array, x) == x.array
