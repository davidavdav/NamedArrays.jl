using NamedArrays

@testset "Issue 105" begin
    a = [10, 20, 30]
    n = NamedArray(a)
    filter!(x -> x > 15, n)
end
