#73
na = NamedArray([1, 2], ([1, missing],), ("A",))
let one = na[Name(1)], two = na[Name(missing)]
    @test one == 1
    @test two == 2
end

#39
include("init-namedarrays.jl")
v = n[1, :]
@test sin.(v).array == sin.(v.array)
@test namesanddim(sin.(v)) == namesanddim(v)

#110
n = NamedArray([1 2; 3 4], ([11,12], [13,14]))
s = sum(n, dims=1)
table = n ./ s 
@test namesanddim(table) == namesanddim(n)

#105
a = [10, 20, 30]
n = NamedArray(a)
filter!(x -> x > 15, n)
@test n == a == [20, 30]
@test names(n, 1) == ["2", "3"]
