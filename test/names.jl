include("init-namedarrays.jl")

@test names(n) == Array[["one", "two"], ["a", "b", "c", "d"]]
@test defaultnames(n.array) == Array[["1", "2"], ["1", "2", "3", "4"]]

@test dimnames(n) == [:A, :B]
@test dimnames(n.array) == [:A, :B]

@test dimnames(n.array, 1) == :A
@test dimnames(n.array, 2) == :B

if VERSION ≥ v"0.5" ## ascii and utf-8 are both String
	dn1 = ["一", "二"]
	dn2 = ["一", "二", "三", "四"]
else
	dn1 = ["yi", "er"]
	dn2 = ["yi", "er", "san", "si"]
end

setnames!(n, dn1, 1)
for (i, zh) in enumerate(dn2)
	setnames!(n, zh, 2, i)
end

@test names(n) == Array[dn1, dn2]

setdimnames!(n, ("thing1", :thing2))
@test dimnames(n) == ["thing1", :thing2]
setdimnames!(n, ["magnificent", 7])
@test dimnames(n) == ["magnificent", 7]

println(n)

@test_throws TypeError setnames!(n, [:a, :v], 1)
@test_throws TypeError setnames!(n, :a, 1, 1)
@test_throws DimensionMismatch setnames!(n, ["a"], 1)
for i in [0,5], d in 1:2
	@test_throws BoundsError setnames!(n, "a", d, i)
end
