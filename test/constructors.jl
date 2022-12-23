## (c) 2016--2020 David A. van Leeuwen

## Unit tests for ../src/constructors.jl

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

using DataStructures
using Test

print("construction, ")
## constructors
a = rand(2,3)
n1 = @inferred NamedArray(a, (OrderedDict(:a => 1, :b=>2), OrderedDict(:c=>3, :d=>2, :e=>1)), (:dim1, :dim2))
println(n1, " ", n1[1,1], " ", n1[:a, :e])
n2 = @inferred NamedArray(a, (OrderedDict(:a => 1, :b=>2), OrderedDict(:c=>3, :d=>2, :e=>1)))
println(n2)
n3 = @inferred NamedArray(a, ([:a, :b], [:c, :d, :e]), (:dim1, :dim2))
println(n3)
n4 = @inferred NamedArray(a, ([:a, :b], [:c, :d, :e]))
println(n4)
n5 = @inferred NamedArray(a, [[Char(64+i) for i in 1:d] for d in 2:3], ["a", "b"])
n6 = @inferred NamedArray(a, [[Char(64+i) for i in 1:d] for d in 2:3])
n7 = @inferred NamedArray(a)

n1 = @inferred NamedArray(ComplexF32, 5, 8)
n2 = @inferred NamedArray(a, (["s", "t"],[:a, :b, :c]), ("string", :symbol))

n = @inferred NamedArray(rand(2,4))
@inferred setnames!(n, ["one", "two"], 1)
@inferred setnames!(n, ["a", "b", "c", "d"], 2)

# keyword constructors
n8 = NamedArray(rand(2,2,2); names=( ["a", "b"], ["c", "d"], 1:2), dimnames=("Rows", "Cols", "Z"))
@test names(n8, 1) == ["a", "b"]
@test names(n8, 3) == [1, 2]

n9 = NamedArray(rand(2,2,2); dimnames=("Rows", "Cols", "Z"))
@test dimnames(n9) == ["Rows", "Cols", "Z"]

n10 = NamedArray(rand(2,2,2); names=(["a", "b"], ["c", "d"], 1:2))
@test names(n10, 1) == ["a", "b"]
@test names(n10, 2) == ["c", "d"]
@test names(n10, 3) == [1, 2]
@test dimnames(n10) == [:A, :B, :C]

a = [1 2 3; 4 5 6]
n3 = @inferred NamedArray(a, (["a","b"],["C","D","E"]))
n4 = @inferred NamedArray(a, (OrderedDict("a"=>1,"b"=>2), OrderedDict("C"=>1,"D"=>2,"E"=>3)))

@test n3.array == n4.array == a
@test dimnames(n3) == dimnames(n4) == Any[:A,:B]
@test names(n3, 1) == names(n4, 1) == ["a","b"]
@test names(n3, 2) == names(n4, 2) == ["C","D","E"]

## named tuples
n4 = @inferred NamedArray(a, (一=["α", "β"], 二=["أ", "ب", "ج"]))
@test dimnames(n4) == [:一, :二]
@test names(n4, 1) == ["α", "β"]
@test names(n4, 2) == ["أ", "ب", "ج"]

n1 = @inferred NamedArray([1], (BitArray([true]),))
n2 = @inferred NamedArray([1], BitArray([true]))
n3 = @inferred NamedArray([1], [true])
@test n1 == n2 == n3
@test names(n1) == names(n2) == names(n3)

## 0-dim case #21
n0 = @inferred NamedArray(Array{Int}(undef))
@test size(n0) == ()
@test n0[1] == n0.array[1]

## Calling constructors through convert, #38
@test convert(NamedArray, n.array) == NamedArray(n.array)
@test convert(NamedVector, [1, 2, 3]) == NamedArray([1, 2, 3])

## new uninitialized construction syntax, #46
for i in 1:5
	dims = 2*fill(1, i)
	global n1 = @inferred NamedArray(Int, dims...) # implicit assignment to global variable `n1`
	global n2 = @inferred NamedArray{Int}(dims...) # implicit assignment to global variable `n2`
end

## repeated indices #63
@test_throws ErrorException @inferred n[["one", "one"], :]

## Simplify vector constructor, #86
n8 = @inferred NamedArray([1, 2, 3], ["a", "b", "c"])
