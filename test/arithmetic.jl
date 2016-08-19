## test arithmetic operations
x = NamedArray(randn(5, 10))
@test (-x).array == -(x.array)
for op in (:+, :-, :*, :.+, :.-, :.*, :./)
	@eval begin
		for y in (true, Int8(3), Int16(3), Int32(3), Int64(3), Float32(π), Float64(π), BigFloat(π))
			z = ($op)(x, y)
			@test z.array == ($op)(x.array, y)
			@test allnames(z) == allnames(x)
			z = ($op)(y, x)
			@test z.array == ($op)(y, x.array)
			@test allnames(z) == allnames(x)
		end
	end
end
for op in (:+, :-, :.+, :.-, :.*, :./)
	for T in (Bool, Int8, Int16, Int32, Int64, Float32, Float64)
		@eval begin
			y = rand($T, 5, 10)
			z = ($op)(x, y)
			@test z.array == ($op)(x.array, y)
			@test allnames(z) == allnames(x)
			z = ($op)(y, x)
			@test z.array == ($op)(y, x.array)
			@test allnames(z) == allnames(x)
		end
	end
end
