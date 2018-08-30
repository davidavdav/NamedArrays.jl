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
    # TODO : @test isapprox(M' * n', M.array' * n')
    # TODO : @test isapprox(M.array' * n', M.array' * n.array')
end

## bug #34
@test unique(names(n * n'))[1] == names(n, 1)
@test unique(names(n' * n))[1] == names(n, 2)

## \
v = NamedArray(randn(2))
m = NamedArray(randn(2, 5))

@test (v \ v)[1] == v.array \ v == v.array \ v.array # v\v returns a NamedMatrix with one element

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
for f in (:inv, :sqrt, :pinv, :exp) # TODO : :chol
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
lufn = lu(n)
lufa = lu(n.array)
@test lufn.U == lufa.U
@test lufn.L == lufa.L
@test names(lufn.U, 2) == names(n, 2) # lu doesn't return NamedArrays now
@test dimnames(lufn.U, 2) == dimnames(n, 2)
@test names(lufn.L, 1) == names(n, 1)
@test dimnames(lufn.L, 1) == dimnames(n, 1)
@test lufn.p == lufa.p
@test lufn.P == lufa.P

a = randn(1000,10); s = NamedArray(a'a)

## The necessity for isapprox sugests we don't get BLAS implementations but a fallback...
# TODO: @test isapprox(cholfact(s).factors.array, cholfact(s.array).factors)

@test isapprox(qr(s).factors.array, qr(s.array).factors)
# @test isapprox(qr(s).T, qr(s.array).T)

@test isapprox(eigen(s).values, eigen(s.array).values)
@test eigen!(copy(s)).values == eigen(s).values

@test isapprox(eigen(s).vectors, eigen(s.array).vectors)
@test eigen!(copy(s)).vectors == eigen(s).vectors

@test eigvals(s) == eigvals!(copy(s)) == eigvals(s.array)

@test isapprox(hessenberg(s).factors, hessenberg(s.array).factors)
@test isapprox(hessenberg(s).τ, hessenberg(s.array).τ)
@test isapprox(hessenberg!(copy(s)).factors, hessenberg(s.array).factors)
@test isapprox(hessenberg!(copy(s)).τ, hessenberg(s.array).τ)

s2 = randn(10,10)
for field in [:T, :Z, :values]
	@test isapprox(getproperty(schur(s), field), getproperty(schur(s.array), field))
	@test isapprox(getproperty(schur!(copy(s)), field), getproperty(schur(s.array), field))
	@test isapprox(getproperty(schur(s, s2), field), getproperty(schur(s.array, s2), field))
	@test isapprox(getproperty(schur!(copy(s), copy(s2)), field), getproperty(schur(s.array, s2), field))
end

@test isapprox(svd(s).U, svd(s.array).U)
@test isapprox(svd(s).S, svd(s.array).S)
@test isapprox(svd(s).Vt, svd(s.array).Vt)

@test svdvals(s) == svdvals!(copy(s)) == svdvals(s.array)

# TODO : @test diag(s).array == diag(s.array)
# TODO : @test names(diag(s), 1) == names(s, 1)
# TODO : @test dimnames(diag(s), 1) == dimnames(s, 1)

# TODO : @test diagm(v).array == diagm(v.array)
# TODO : @test names(diagm(v)) == names(v)[[1,1]]

@test cond(n) == cond(n.array)

@test kron(n, n').array == kron(n.array, n.array')

a = randn(10, 10)
b = randn(10, 10)
@test lyap(s, a) == lyap(s.array, a)
@test sylvester(s, a, b).array == sylvester(s.array, a, b)

@test isposdef(s) == isposdef(s.array)
