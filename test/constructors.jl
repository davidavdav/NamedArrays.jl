## (c) 2016 David A. van Leeuwen

## Unit tests for ../src/constructors.jl

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

using DataStructures
using Base.Test

print("construction, ")
## constructors
a = rand(2,3)
n1 = NamedArray(a, (OrderedDict(:a => 1, :b=>2), OrderedDict(:c=>3, :d=>2, :e=>1)), (:dim1, :dim2))
println(n1, " ", n1[1,1], " ", n1[:a, :e])
n2 = NamedArray(a, (OrderedDict(:a => 1, :b=>2), OrderedDict(:c=>3, :d=>2, :e=>1)))
println(n2)
n3 = NamedArray(a, ([:a, :b], [:c, :d, :e]), (:dim1, :dim2))
println(n3)
n4 = NamedArray(a, ([:a, :b], [:c, :d, :e]))
println(n4)
n5 = NamedArray(a, [[Char(64+i) for i in 1:d] for d in 2:3], ["a", "b"])
n6 = NamedArray(a, [[Char(64+i) for i in 1:d] for d in 2:3])
n7 = NamedArray(a)

n1 = NamedArray(Complex64, 5, 8)
n2 = NamedArray(a, (["s", "t"],[:a, :b, :c]), ("string", :symbol))

n = NamedArray(rand(2,4))
setnames!(n, ["one", "two"], 1)
setnames!(n, ["a", "b", "c", "d"], 2)

a = [1 2 3; 4 5 6]
n3 = NamedArray(a, (["a","b"],["C","D","E"]))
n4 = NamedArray(a, (OrderedDict("a"=>1,"b"=>2), OrderedDict("C"=>1,"D"=>2,"E"=>3)))

@test n3.array == n4.array == a
@test dimnames(n3) == dimnames(n4) == Any[:A,:B]
@test names(n3,1) == names(n4,1) == ["a","b"]
@test names(n3,2) == names(n4,2) == ["C","D","E"]

## 0-dim case #21
n0 = NamedArray(Array{Int}())
@test size(n0) == ()
@test n0[1] == n0.array[1]

## Calling constructors through convert, #38
@test convert(NamedArray, n.array) == NamedArray(n.array)
@test convert(NamedVector, [1, 2, 3]) == NamedArray([1, 2, 3])
