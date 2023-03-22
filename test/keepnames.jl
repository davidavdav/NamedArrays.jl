@testset "hcat/vcat" begin
    include("init-namedarrays.jl")

    letters = [string(Char(96+i)) for i=1:26]

    @testset "vectors" begin
        m = @inferred NamedArray(rand(10), (letters[1:10],))
        @testset "same names" begin
            m2 = @inferred NamedArray(rand(10), (letters[1:10],))
            mm = hcat(m, m2)
            @test mm.array == hcat(m.array, m2.array)
            @test namesanddim(mm,1) == namesanddim(m,1)

            mm = @inferred vcat(m, m2)
            @test mm.array == vcat(m.array, m2.array)
            @test names(mm, 1) == [string(i) for i in 1:length(mm)]
        end

        @testset "different names" begin
            m2 = @inferred NamedArray(rand(10), (letters[11:20],))
            mm = @inferred hcat(m, m2)
            @test mm.array == hcat(m.array, m2.array)
            @test names(mm, 1) != names(m2, 1)

            mm = @inferred vcat(m, m2)
            @test mm.array == vcat(m.array, m2.array)
            @test names(mm, 1) == vcat(names(m, 1), names(m2, 1))
        end
    end

    @testset "matrix" begin
        m = @inferred NamedArray(rand(10, 10), (letters[1:10], letters[11:20]))
        @testset "same names" begin
            m2 = @inferred NamedArray(rand(10, 10), (letters[1:10], letters[11:20]))
            mm = @inferred hcat(m, m2)
            @test mm.array == hcat(m.array, m2.array)
            @test namesanddim(mm,1) == namesanddim(m,1)

            mm = @inferred vcat(m, m2)
            @test mm.array == vcat(m.array, m2.array)
            @test names(mm, 1) == [string(i) for i in 1:size(mm, 1)]
            @test names(mm, 2) == names(m, 2)
        end

        @testset "different names" begin
            m2 = @inferred NamedArray(rand(10, 10), (letters[11:20], letters[1:10]))
            mm = @inferred hcat(m, m2)
            @test mm.array == hcat(m.array, m2.array)
            @test names(mm, 1) != names(m2, 1)

            mm = @inferred vcat(m, m2)
            @test mm.array == vcat(m.array, m2.array)
            ## @test names(mm, 1) == vcat(names(m, 1), names(m2, 1))
            @test names(mm, 2) == [string(i) for i in 1:size(mm, 2)]
        end
    end
end
