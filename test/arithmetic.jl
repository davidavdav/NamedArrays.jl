## (c) 2016 David A. van Leeuwen

## Unit tests for ../src/arithmetic.jl

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

## test arithmetic operations
print("arithmetic, ")

x = NamedArray(randn(5, 10))
@test (-x).array == -(x.array)
for op in (:+, :-, :*, :.+, :.-, :.*, :./)
	@eval begin
		for y in (true, Int8(3), Int16(3), Int32(3), Int64(3), Float32(π), Float64(π), BigFloat(π))
			z = ($op)(x, y)
			@test z.array == ($op)(x.array, y)
			@test allnames(z) == allnames(x)
			z = ($op)(y, x)
			@test z.array == ($op)(y, x.array)
			@test allnames(z) == allnames(x)
		end
	end
end
for op in (:+, :-, :.+, :.-, :.*, :./)
	for T in (Bool, Int8, Int16, Int32, Int64, Float32, Float64)
		@eval begin
			z = ($op)(x, x)
			@test z.array == ($op)(x.array, x.array)
			@test allnames(z) == allnames(x)
			@test dimnames(z) == dimnames(x)
			y = rand($T, 5, 10)
			z = ($op)(x, y)
			@test z.array == ($op)(x.array, y)
			@test allnames(z) == allnames(x)
			@test dimnames(z) == dimnames(x)
			z = ($op)(y, x)
			@test z.array == ($op)(y, x.array)
			@test allnames(z) == allnames(x)
			@test dimnames(z) == dimnames(x)
		end
	end
end

include("init-namedarrays.jl")

@test n / π == π \ n

@test (v - (1:6)).array == v.array - (1:6)

## matmul
if VERSION >= v"0.5.0-dev" ## v0.4 ambiguity-hell with AbstractTriangular c.s.
    ## Assume dimensions/names are correct
	c = NamedArray(Float64, 5, 5)
	A_mul_B!(c, randn(5, 10), randn(10, 5))
	A_mul_Bc!(c, randn(5, 10), randn(5, 10))
	A_mul_Bt!(c, randn(5, 10), randn(5, 10))
	Ac_mul_B!(c, randn(10, 5), randn(10, 5))
	At_mul_B!(c, randn(10, 5), randn(10, 5))
	At_mul_Bt!(c, randn(10,5), randn(5, 10))
end

for m in (NamedArray(rand(4)), NamedArray(rand(4,3)))
    m * m'
    m' * m
    @test n * m == n * m.array == n.array * m == n.array * m.array
    ## the first expression dispatches Ac_mul_Bc!:
    @test isapprox(m' * n.array', m' * n')
    @test isapprox(m' * n', m.array' * n')
    @test isapprox(m.array' * n', m.array' * n.array')
end
## bug #34
@test unique(allnames(n * n'))[1] == names(n,1)
@test unique(allnames(n' * n))[1] == names(n,2)

## \
v = NamedArray(randn(2))
m = NamedArray(randn(2, 5))

@test v \ v == v.array \ v == v.array \ v.array

@test (n \ v).array == n.array \ v.array
@test names(n \ v, 1) == names(n, 2)
@test dimnames(n \ v, 1) == dimnames(n, 2)

@test (v \ n).array == v.array \ n.array
@test names(v \ n, 2) == names(n, 2)
@test dimnames(v \ n, 2) == dimnames(n, 2)

@test (v \ n.array) == v.array \ n.array
@test (n \ m.array).array == n.array \ m.array
@test names(n \ m.array, 1) == names(n, 2)
@test dimnames(n \ m.array, 1) == dimnames(n, 2)

@test (n \ m).array == n.array \ m.array
@test names(n \ m, 1) == names(n, 2)
@test names(n \ m, 2) == names(m, 2)

@test n.array \ v == n.array \ v.array
@test (v.array \ n).array == v.array \ n.array
@test names(v.array \ n, 2) == names(n, 2)
@test dimnames(v.array \ n, 2) == dimnames(n, 2)

@test (n.array \ m).array == n.array \ m.array
@test names(n.array \ m, 2) == names(m, 2)
@test names(n.array \ m, 1) == NamedArrays.defaultnames(n.array, 2)
@test dimnames(n.array \ m, 2) == dimnames(m, 2)

m = NamedArray((x = randn(100, 10); x'x))
for f in (:inv, :chol, :sqrtm, :pinv, :expm)
	@eval fm = ($f)(m)
	@test @eval fm.array == ($f)(m.array)
	@test allnames(fm) == allnames(m)
	@test dimnames(fm) == dimnames(m)
end

## tril, triu
m = NamedArray(rand(5,5))
c = copy(m)
tril!(c)
@test tril(m).array == tril(m.array) == c.array
c = copy(m)
triu!(c)
@test triu(m).array == triu(m.array) == c.array

## lufact!
lufn = lufact(n)
lufa = lufact(n.array)
@test lufn[:U].array == lufa[:U]
@test lufn[:L].array == lufa[:L]
@test names(lufn[:U], 2) == names(n, 2)
@test dimnames(lufn[:U], 2) == dimnames(n, 2)
@test names(lufn[:L], 1) == names(n, 1)
@test dimnames(lufn[:L], 1) == dimnames(n, 1)
@test lufn[:p] == lufa[:p]
@test lufn[:P] == lufa[:P]

a = randn(1000,10); s = NamedArray(a'a)

## The necessity for isapprox sugests we don't get BLAS implementations but a fallback...
if VERSION >= v"0.5.0-dev" ## v0.4 cholfact is different?
	@test isapprox(cholfact(s).factors.array, cholfact(s.array).factors)
end

@test isapprox(qrfact(s).factors.array, qrfact(s.array).factors)
# @test isapprox(qrfact(s).T, qrfact(s.array).T)

for field in [:values, :vectors]
	@test isapprox(eigfact(s)[field], eigfact(s.array)[field])
end

@test isapprox(hessfact(s).factors, hessfact(s.array).factors)
@test isapprox(hessfact(s).τ, hessfact(s.array).τ)

for field in [:T, :Z, :values]
	@test isapprox(schurfact(s)[field], schurfact(s.array)[field])
end

for field in [:U, :S, :Vt]
	@test isapprox(svdfact(s)[field], svdfact(s.array)[field])
end

@test svdvals(s) == svdvals(s.array)

@test diag(s).array == diag(s.array)
@test names(diag(s), 1) == names(s, 1)
@test dimnames(diag(s), 1) == dimnames(s, 1)

@test diagm(v).array == diagm(v.array)
@test allnames(diagm(v)) == allnames(v)[[1,1]]

@test cond(n) == cond(n.array)

@test kron(n, n').array == kron(n.array, n.array')

a = randn(10, 10)
b = randn(10, 10)
@test lyap(s, a) == lyap(s.array, a)
@test sylvester(s, a, b).array == sylvester(s.array, a, b)

@test isposdef(s) == isposdef(s.array)
