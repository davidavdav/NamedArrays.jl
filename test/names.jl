## Test names.jl retrieve and set dimension names
## (c) 2013--2020 David A. van Leeuwen

include("init-namedarrays.jl")

@test names(n) == Array[["one", "two"], ["a", "b", "c", "d"]]
@test defaultnames(n.array) == Array[["1", "2"], ["1", "2", "3", "4"]]

@test dimnames(n) == [:A, :B]
@test dimnames(n.array) == [:A, :B]

@test dimnames(n.array, 1) == :A
@test dimnames(n.array, 2) == :B

dn1 = ["一", "二"]
dn2 = ["一", "二", "三", "四"]

@inferred setnames!(n, dn1, 1)
for (i, zh) in enumerate(dn2)
	@inferred setnames!(n, zh, 2, i)
end

@test names(n) == Array[dn1, dn2]

@inferred setdimnames!(n, ("thing1", :thing2))
@test dimnames(n) == ["thing1", :thing2]
setdimnames!(n, ["magnificent", 7]) ## can't infer mixed types
@test dimnames(n) == ["magnificent", 7]

println(n)

## replacing a single index name, and then accessing it was never tested, #83
for (dim, numerals) in enumerate(defaultnames(n.array))
	for (index, name) in enumerate(numerals)
		setnames!(n, name, dim, index)
		@test names(n, dim)[index] == name
	end
end

## I am sure this can be done more nicely with CartesianIndices
for i in 1:2, j in 1:4
	@test n[string(i), string(j)] == n[i, j]
end

println(n)

@test_throws TypeError setnames!(n, [:a, :v], 1)
@test_throws TypeError setnames!(n, :a, 1, 1)
@test_throws DimensionMismatch setnames!(n, ["a"], 1)
for i in [0,5], j in 1:2
	@test_throws BoundsError setnames!(n, "a", j, i)
end
