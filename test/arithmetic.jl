## (c) 2016 David A. van Leeuwen

## Unit tests for ../src/arithmetic.jl

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

## test arithmetic operations
print("arithmetic, ")

dotops = [:.+, :.-, :.*, :./]

x = NamedArray(randn(5, 10))
@test @inferred -x == -(x.array)
for op in dotops
	@eval begin
		for y in (true, Int8(3), Int16(3), Int32(3), Int64(3), Float32(π), Float64(π), BigFloat(π))
			z = ($op)(x, y)
			println($op, z)
			@test z.array == ($op)(x.array, y)
			@test names(z) == names(x)
			z = ($op)(y, x)
			@test z.array == ($op)(y, x.array)
			@test names(z) == names(x)
		end
	end
end
for op in dotops
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


@test n / π == π \ n

@test (v - (1:6)).array == v.array - (1:6)
@test ((1:6) - v).array == (1:6) - v.array

## matmul
## Assume dimensions/names are correct
c = NamedArray(Float64, 5, 5)
r5x10 = randn(5, 10)
r10x5 = randn(10, 5)
@test mul!(c, r5x10, r10x5) ≈ r5x10 * r10x5
@test mul!(c, r5x10, adjoint(r5x10)) ≈ r5x10 * r5x10'
@test mul!(c, r5x10, transpose(r5x10)) ≈ r5x10 * r5x10'
@test mul!(c, adjoint(r10x5), r10x5) ≈ r10x5' * r10x5
@test mul!(c, transpose(r10x5), r10x5) ≈ r10x5' * r10x5
@test mul!(c, transpose(r10x5), transpose(r5x10)) ≈ r10x5' * r5x10'

for M in (NamedArray(rand(4)), NamedArray(rand(4,3)))
    @test M * M' ≈ M.array * M.array'
    value = M' * M
    @test (length(value) == 1 ? value[1] : value) ≈ M.array' * M.array # M' * M is always a NamedArray
    @test n * M ≈ n * M.array ≈ n.array * M ≈ n.array * M.array
    ## the first expression dispatches Ac_Mul_Bc!:
    @test isapprox(M' * n.array', M' * n')
    @test isapprox(M' * n', M.array' * n')
    @test isapprox(M.array' * n', M.array' * n.array')
end

## bug #34
# TODO: @test unique(names(n * n'))[1] == names(n, 1)
# TODO: @test unique(names(n' * n))[1] == names(n, 2)

## \
v = NamedArray(randn(2))
m = NamedArray(randn(2, 5))

# TODO: @test v \ v == v.array \ v == v.array \ v.array

# TODO: @test (n \ v).array == n.array \ v.array
# TODO: @test names(n \ v, 1) == names(n, 2)
# TODO: @test dimnames(n \ v, 1) == dimnames(n, 2)

# TODO: @test (v \ n).array == v.array \ n.array
# TODO: @test names(v \ n, 2) == names(n, 2)
# TODO: @test dimnames(v \ n, 2) == dimnames(n, 2)

# TODO: @test (v \ n.array) == v.array \ n.array
# TODO: @test (n \ m.array).array == n.array \ m.array
# TODO: @test names(n \ m.array, 1) == names(n, 2)
# TODO: @test dimnames(n \ m.array, 1) == dimnames(n, 2)
# TODO:
# TODO: @test (n \ m).array == n.array \ m.array
# TODO: @test names(n \ m, 1) == names(n, 2)
# TODO: @test names(n \ m, 2) == names(m, 2)
# TODO:
# TODO: @test n.array \ v == n.array \ v.array
# TODO: @test (v.array \ n).array == v.array \ n.array
# TODO: @test names(v.array \ n, 2) == names(n, 2)
# TODO: @test dimnames(v.array \ n, 2) == dimnames(n, 2)
# TODO:
# TODO: @test (n.array \ m).array == n.array \ m.array
# TODO: @test names(n.array \ m, 2) == names(m, 2)
# TODO: @test names(n.array \ m, 1) == NamedArrays.defaultnames(n.array, 2)
# TODO: @test dimnames(n.array \ m, 2) == dimnames(m, 2)

# TODO: m = NamedArray((x = randn(100, 10); x'x))
# TODO: for f in (:inv, :chol, :sqrtm, :pinv, :expm)
# TODO: 	@eval fm = ($f)(m)
# TODO: 	@test @eval fm.array == ($f)(m.array)
# TODO: 	@test names(fm) == names(m)
# TODO: 	@test dimnames(fm) == dimnames(m)
# TODO: end

## tril, triu
m = NamedArray(rand(5,5))
c = copy(m)
tril!(c)
@test tril(m).array == tril(m.array) == c.array
c = copy(m)
triu!(c)
@test triu(m).array == triu(m.array) == c.array

## lufact!
# TODO: lufn = lu(n)
# TODO: lufa = lu(n.array)
# TODO: @test lufn[:U].array == lufa[:U]
# TODO: @test lufn[:L].array == lufa[:L]
# TODO: @test names(lufn[:U], 2) == names(n, 2)
# TODO: @test dimnames(lufn[:U], 2) == dimnames(n, 2)
# TODO: @test names(lufn[:L], 1) == names(n, 1)
# TODO: @test dimnames(lufn[:L], 1) == dimnames(n, 1)
# TODO: @test lufn[:p] == lufa[:p]
# TODO: @test lufn[:P] == lufa[:P]

a = randn(1000,10); s = NamedArray(a'a)

## The necessity for isapprox sugests we don't get BLAS implementations but a fallback...
# TODO: @test isapprox(cholfact(s).factors.array, cholfact(s.array).factors)

# TODO: @test isapprox(qrfact(s).factors.array, qrfact(s.array).factors)
# @test isapprox(qrfact(s).T, qrfact(s.array).T)

# TODO: for field in [:values, :vectors]
# TODO: 	@test isapprox(eigfact(s)[field], eigfact(s.array)[field])
# TODO: 	@test eigfact!(copy(s))[field] == eigfact(s)[field]
# TODO: end
# TODO: @test eigvals(s) == eigvals!(copy(s)) == eigvals(s.array)

# TODO: @test isapprox(hessfact(s).factors, hessfact(s.array).factors)
# TODO: @test isapprox(hessfact(s).τ, hessfact(s.array).τ)
# TODO: @test isapprox(hessfact!(copy(s)).factors, hessfact(s.array).factors)
# TODO: @test isapprox(hessfact!(copy(s)).τ, hessfact(s.array).τ)

s2 = randn(10,10)
# TODO: for field in [:T, :Z, :values]
# TODO: 	@test isapprox(schurfact(s)[field], schurfact(s.array)[field])
# TODO: 	@test isapprox(schurfact!(copy(s))[field], schurfact(s.array)[field])
# TODO: 	@test isapprox(schurfact(s, s2)[field], schurfact(s.array, s2)[field])
# TODO: 	@test isapprox(schurfact!(copy(s), copy(s2))[field], schurfact(s.array, s2)[field])
# TODO: end
# TODO:
# TODO: for field in [:U, :S, :Vt]
# TODO: 	@test isapprox(svdfact(s)[field], svdfact(s.array)[field])
# TODO: end

# TODO: @test svdvals(s) == svdvals!(copy(s)) == svdvals(s.array)

@test diag(s).array == diag(s.array)
@test names(diag(s), 1) == names(s, 1)
@test dimnames(diag(s), 1) == dimnames(s, 1)

# TODO: @test diagm(v).array == diagm(v.array)
# TODO: @test names(diagm(v)) == names(v)[[1,1]]
# TODO:
# TODO: @test cond(n) == cond(n.array)
# TODO:
# TODO: @test kron(n, n').array == kron(n.array, n.array')
# TODO:
# TODO: a = randn(10, 10)
# TODO: b = randn(10, 10)
# TODO: @test lyap(s, a) == lyap(s.array, a)
# TODO: @test sylvester(s, a, b).array == sylvester(s.array, a, b)
# TODO:
# TODO: @test isposdef(s) == isposdef(s.array)
