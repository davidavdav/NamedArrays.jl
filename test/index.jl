## (c) 2016--2018 David A. van Leeuwen
## tests for ../src/index.jl

print("getindex, ")
## getindex
## Test Integer indices up to 5 dimensions, as well as CartesianIndexes
for i in 1:7
	dims = fill(3, i)
	global n1 = @inferred NamedArray(rand(dims...))
	for i in CartesianIndices(tuple(dims...))
		@test n1[i.I...] == n1.array[i.I...]
		@test n1[i] == n1.array[i]
		@test n1[[string(ii) for ii in i.I]...] == n1.array[i]
		n1[i.I...] +=  1 ## test setindex
	end
end

include("init-namedarrays.jl")

@test n[:] == view(n, :) == n.array[:] ## values
println(n)
println(names(n[:],1))
@test names(n[:], 1)[2] == ("two", "a")
@test names(n[:], 1)[5] == ("one", "c")
@test dimnames(n[:], 1) == (:A, :B)

n1 = @inferred NamedArray(rand(10))
@test n1[:] == n1
@test [x for x in n] == [x for x in n.array]

## more indexing
@test convert(Array, n["one", :]) == n.array[1,:]
@test n[Not("two"), :].array == n.array[1:1,:]
@test names(n[Not("two"), :]) == names(n[1:1, :])
@test n[:, ["b", "d"]] == view(n, :, ["b", "d"]) == n[:, [2, 4]]

@test names(n[Not("one"), :], 1) == ["two"]
@test names(n[1:1, Not("a")], 2) == ["b", "c", "d"]
## indexing by pair
@test n[:B=>"a", :A=>"two"] == n[2, 1]
@test n[:A=>"one", :B=>"d"] == n[1, 4]
@test n[:B => "b"] == n[:, "b"]
@test n[:A => "two"] == n["two", :]

## https://github.com/nalimilan/FreqTables.jl/issues/10
bi = [false, true, false, true] ## Array{Bool}
for i in 1:2
    @test n[:, bi] == view(n, :, bi) == n.array[:, bi]
    @test names(n[:, bi], 2) == ["b", "d"]
    global bi = BitArray(bi)
end

m = @inferred copy(n)
print("setindex, ")
## setindex
m[1,1] = 0
m[2,:] = 1:4
m[:,"c"] .= -1
m[1,[2,3]] = [10,20]
m["one", 4] = 5

@test m.array == [0. 10 20 5; 1 2 -1 4]
m2 = copy(m)
for i in eachindex(m)
	m[i] = 2*m[i]
end
@test 2*(m2.array) == m.array

m[:B=>"c", :A=>"one"] = π
@test m[1,3] == Float64(π)
m[:] = n
@test m == n

m[:] = 1:8
@test m[:] == collect(1:8)

m = @inferred NamedArray(rand(Int, 10))
m[2:5] .= -1
m[6:8] = 2:4
m[[1,9,10]] = 0:2
@test m == [0, -1, -1, -1, -1, 2, 3, 4, 1, 2]

n[1,1] = π
@test n.array[1,1] == Float64(π)
