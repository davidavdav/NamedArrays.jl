using NamedArrays

@testset "Issue 110" begin
    n = NamedArray([1 2; 3 4], ([11,12], [13,14]))

    s = sum(n, dims=1)

    println( n ./ s )
end
