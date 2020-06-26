@testset "Enameration" begin
	names = [("one", "a"), ("two", "a"), ("one", "b"), ("two", "b"), ("one", "c"), ("two", "c"), ("one", "d"), ("two", "d")]
	i = 1 
	for (nameTuple, val) in enamerate(n)
		@test nameTuple == names[i] 
		i += 1
		@test val === n[nameTuple...]
	end
end
