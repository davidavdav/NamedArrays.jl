using Test
using CSV
using NamedArrays
using DataFrames

f = NamedArray([0 1 ; 2 3])
expected = DataFrame(CSV.File("writetest.csv"))

NamedArrays.write("test.csv",f)
reread = DataFrame(CSV.File("test.csv"))
@test reread == expected
