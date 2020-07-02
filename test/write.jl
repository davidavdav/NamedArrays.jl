using Test
using CSV
using NamedArrays
using DataFrames

include("init-namedarrays.jl")


@testset "CSV writing" begin
	expected = DataFrame(CSV.File("CSVs/n2d.csv"))
	n2d = NamedArray([0 1 ; 2 3])
	NamedArrays.write("testn2d.csv",n2d)
	reread = DataFrame(CSV.File("testn2d.csv"))
	@test reread == expected

	expm4d = DataFrame(CSV.File("CSVs/m4d.csv"))
	m4d = NamedArray(reshape(1:16,2,2,2,2))
	setnames!(m4d,["A","B"],1)
	setnames!(m4d,["x","y"],2)
	setnames!(m4d,["11","22"],3)
	setnames!(m4d,["DO","RE"],4)

	NamedArrays.write("testm4d.csv",m4d)
	rereadm4d = DataFrame(CSV.File("testm4d.csv"))
	@test rereadm4d == expM 
end
