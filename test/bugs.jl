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

