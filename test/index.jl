## (c) 2016 David A. van Leeuwen
## tests for ../src/index.jl

import Base.indices

print("getindex, ")
## getindex
## Test Integer indices up to 5 dimensions, as well as CartesianIndexes
for i in 1:5
	dims = fill(3, i)
	n1 = NamedArray(rand(dims...))
	for i in CartesianRange(tuple(dims...))
		@test n1[i.I...] == n1.array[i.I...]
		@test n1[i] == n1.array[i]
		@test n1[[string(ii) for ii in i.I]...] == n1.array[i]
		n1[i.I...] +=  1 ## test setindex
	end
end

include("init-namedarrays.jl")

@test n[:] == n.array[:]
n1 = NamedArray(rand(10))
@test n1[:] == n1
@test [x for x in n] == [x for x in n.array]

## more indexing
first = n.array[1,:]
@test convert(Array, n["one", :]) == first
@test n[Not("two"), :].array == n.array[1:1,:]
@test n[:, ["b", "d"]] == n[:, [2, 4]]

if VERSION < v"0.5.0-dev"
    @test names(n["one", :],1) == ["one"]
end
@test names(n[Not("one"), :],1) == ["two"]
@test names(n[1:1, Not("a")], 2) == ["b", "c", "d"]
## indexing by pair
@test n[:B=>"a", :A=>"two"] == n.array[2, 1]
@test n[:A=>"one", :B=>"d"] == n.array[1, 4]
## https://github.com/nalimilan/FreqTables.jl/issues/10
bi = [false, true, false, true] ## Array{Bool}
for i in 1:2
    @test n[:, bi].array == n.array[:, bi]
    @test names(n[:, bi], 2) == ["b", "d"]
    bi = BitArray(bi)
end
