reload("src/NamedArray.jl")

n = NamedArray(rand(2,4))
setnames!(n, ["one", "two"], 1)     

## sum
@assert sum(n) == sum(n.array)
@assert sum(n, 1).array == sum(n.array, 1)
@assert sum(n, 2).array == sum(n.array, 2)
@assert names(sum(n, 2),1) == ["one", "two"]

## conversion
@assert convert(Array, n) == n.array

## indexing
first = n.array[1,:]
@assert n["one", :].array == first
@assert n[!"two", :].array == first
@assert n[1, 2:3].array == first[:,2:3]
@assert names(n["one", :],1) == ["one"]
@assert names(n[!"one", :],1) == ["two"]
@assert names(n[1, !"1"],2) == ["2", "3", "4"]

## copy
m = copy(n)
@assert m == n
