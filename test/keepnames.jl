include("init-namedarrays.jl")

print("hcat/vcat, ")

letters = [string(Char(96+i)) for i=1:26]

## vectors
## same names
m = @inferred NamedArray(rand(10), (letters[1:10],))
m2 = @inferred NamedArray(rand(10), (letters[1:10],))
mm = hcat(m, m2)
@test mm.array == hcat(m.array, m2.array)
@test namesanddim(mm,1) == namesanddim(m,1)

mm = @inferred vcat(m, m2)
@test mm.array == vcat(m.array, m2.array)
@test names(mm, 1) == [string(i) for i in 1:length(mm)]

## different names
m2 = @inferred NamedArray(rand(10), (letters[11:20],))
mm = @inferred hcat(m, m2)
@test mm.array == hcat(m.array, m2.array)
@test names(mm, 1) != names(m2, 1)

mm = @inferred vcat(m, m2)
@test mm.array == vcat(m.array, m2.array)
@test names(mm, 1) == vcat(names(m, 1), names(m2, 1))

## matrix
## same names
m = @inferred NamedArray(rand(10, 10), (letters[1:10], letters[11:20]))
m2 = @inferred NamedArray(rand(10, 10), (letters[1:10], letters[11:20]))
mm = @inferred hcat(m, m2)
@test mm.array == hcat(m.array, m2.array)
@test namesanddim(mm,1) == namesanddim(m,1)

mm = @inferred vcat(m, m2)
@test mm.array == vcat(m.array, m2.array)
@test names(mm, 1) == [string(i) for i in 1:size(mm, 1)]
@test names(mm, 2) == names(m, 2)

## different names
m2 = @inferred NamedArray(rand(10, 10), (letters[11:20], letters[1:10]))
mm = @inferred hcat(m, m2)
@test mm.array == hcat(m.array, m2.array)
@test names(mm, 1) != names(m2, 1)

mm = @inferred vcat(m, m2)
@test mm.array == vcat(m.array, m2.array)
## @test names(mm, 1) == vcat(names(m, 1), names(m2, 1))
@test names(mm, 2) == [string(i) for i in 1:size(mm, 2)]
