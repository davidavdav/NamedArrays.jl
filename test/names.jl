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

@test_throws TypeError setnames!(n, [:a, :v], 1)
@test_throws TypeError setnames!(n, :a, 1, 1)
@test_throws DimensionMismatch setnames!(n, ["a"], 1)
for i in [0,5], j in 1:2
	@test_throws BoundsError setnames!(n, "a", j, i)
end
