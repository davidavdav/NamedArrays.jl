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
			@test names(z) == names(x)
			z = ($op)(y, x)
			@test z.array == ($op)(y, x.array)
			@test names(z) == names(x)
		end
	end
end
for op in (:+, :-, :.+, :.-, :.*, :./)
	for T in (Bool, Int8, Int16, Int32, Int64, Float32, Float64)
		@eval begin
			z = ($op)(x, x)
			@test z.array == ($op)(x.array, x.array)
			@test names(z) == names(x)
			@test dimnames(z) == dimnames(x)
			y = rand($T, 5, 10)
			z = ($op)(x, y)
			@test z.array == ($op)(x.array, y)
			@test names(z) == names(x)
			@test dimnames(z) == dimnames(x)
			z = ($op)(y, x)
			@test z.array == ($op)(y, x.array)
			@test names(z) == names(x)
			@test dimnames(z) == dimnames(x)
		end
	end
end

include("init-namedarrays.jl")

for op in [:.*, :+, .-]
	@eval for b in NamedArray[bv, bm] ## NamedArray[] for julia-0.4
		@test (($op)(b, BitArray(b))).array == ($op)(b.array, BitArray(b))
		@test names(($op)(b, BitArray(b))) == names(b)
		@test ($op)(BitArray(b), b).array == ($op)(BitArray(b), b.array)
		@test names(($op)(BitArray(b), b)) == names(b)
		@test ($op)(b, true).array == ($op)(b.array, true)
		@test ($op)(true, b).array == ($op)(true, b.array)
	end
end


@test n / π == π \ n

@test (v - (1:6)).array == v.array - (1:6)
@test ((1:6) - v).array == (1:6) - v.array

## matmul
if VERSION ≥ v"0.5" ## v0.4 ambiguity-hell with AbstractTriangular c.s.
    ## Assume dimensions/names are correct
	c = NamedArray(Float64, 5, 5)
	r5x10 = randn(5, 10)
	r10x5 = randn(10, 5)
	@test A_mul_B!(c, r5x10, r10x5) == r5x10 * r10x5
	@test A_mul_Bc!(c, r5x10, r5x10) == r5x10 * r5x10'
	@test A_mul_Bt!(c, r5x10, r5x10) == r5x10 * r5x10'
	@test Ac_mul_B!(c, r10x5, r10x5) == r10x5' * r10x5
	@test At_mul_B!(c, r10x5, r10x5) == r10x5' * r10x5
	@test At_mul_Bt!(c, r10x5, r5x10) == r10x5' * r5x10'
end

for m in (NamedArray(rand(4)), NamedArray(rand(4,3)))
    @test m * m' == m.array * m.array'
    @test m' * m == m.array' * m.array
    @test n * m == n * m.array == n.array * m == n.array * m.array
    ## the first expression dispatches Ac_mul_Bc!:
    @test isapprox(m' * n.array', m' * n')
    @test isapprox(m' * n', m.array' * n')
    @test isapprox(m.array' * n', m.array' * n.array')
end
## bug #34
@test unique(names(n * n'))[1] == names(n,1)
@test unique(names(n' * n))[1] == names(n,2)

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
	@test names(fm) == names(m)
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
if VERSION ≥ v"0.5" ## v0.4 cholfact is different?
	@test isapprox(cholfact(s).factors.array, cholfact(s.array).factors)
end

@test isapprox(qrfact(s).factors.array, qrfact(s.array).factors)
# @test isapprox(qrfact(s).T, qrfact(s.array).T)

for field in [:values, :vectors]
	@test isapprox(eigfact(s)[field], eigfact(s.array)[field])
	@test eigfact!(copy(s))[field] == eigfact(s)[field]
end
@test eigvals(s) == eigvals!(copy(s)) == eigvals(s.array)

@test isapprox(hessfact(s).factors, hessfact(s.array).factors)
@test isapprox(hessfact(s).τ, hessfact(s.array).τ)
@test isapprox(hessfact!(copy(s)).factors, hessfact(s.array).factors)
@test isapprox(hessfact!(copy(s)).τ, hessfact(s.array).τ)

s2 = randn(10,10)
for field in [:T, :Z, :values]
	@test isapprox(schurfact(s)[field], schurfact(s.array)[field])
	@test isapprox(schurfact!(copy(s))[field], schurfact(s.array)[field])
	@test isapprox(schurfact(s, s2)[field], schurfact(s.array, s2)[field])
	@test isapprox(schurfact!(copy(s), copy(s2))[field], schurfact(s.array, s2)[field])
end

for field in [:U, :S, :Vt]
	@test isapprox(svdfact(s)[field], svdfact(s.array)[field])
end

@test svdvals(s) == svdvals!(copy(s)) == svdvals(s.array)

@test diag(s).array == diag(s.array)
@test names(diag(s), 1) == names(s, 1)
@test dimnames(diag(s), 1) == dimnames(s, 1)

@test diagm(v).array == diagm(v.array)
@test names(diagm(v)) == names(v)[[1,1]]

@test cond(n) == cond(n.array)

@test kron(n, n').array == kron(n.array, n.array')

a = randn(10, 10)
b = randn(10, 10)
@test lyap(s, a) == lyap(s.array, a)
@test sylvester(s, a, b).array == sylvester(s.array, a, b)

@test isposdef(s) == isposdef(s.array)
