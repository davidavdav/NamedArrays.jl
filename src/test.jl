reload("src/NamedArray.jl")

n = NamedArray(rand(2,4))
setnames!(n, ["one", "two"], 1)     

## sum
@assert sum(n) == sum(n.array)
@assert sum(n, 1).array == sum(n.array, 1)
@assert sum(n, 2).array == sum(n.array, 2)
@assert sum(n, 2).names[1] == ["one", "two"]

## conversion
@assert convert(Array, n) == n.array

## indexing
first = n.array[1,:]
@assert n["one", :].array == first
@assert n[!"two", :].array == first
@assert n[1, 2:3].array == first[:,2:3]
@assert n["one", :].names[1] == ["one"]
@assert n[!"one", :].names[1] == ["two"]
@assert n[1, !"1"].names[2] == ["2", "3", "4"]

## copu
m = copy(n)
@assert m == n
