using Test
using NamedArrays
using CSV

f = NamedArray([0 1 ; 2 3])
expected = CSV.read("writetest.csv")
println(expected)

NamedArrays.write("test.csv",f)
reread = CSV.read("test.csv")
@test reread == expected
