## arithmetic.jl operators for NamedArray

## (c) 2013--2014 David A. van Leeuwen

## This code is licensed under the MIT License
## See the file LICENSE.md in this distribution

import Base: +, -, *, /, .+, .-, .*, ./, \

-(n::NamedArray) = NamedArray(-n.array, n.dicts, n.dimnames)

## disambiguation magic
.*(n::NamedArray{Bool}, b::BitArray) = NamedArray(n.array .* b, n.dicts, n.dimnames)
.*{N}(n::NamedArray{Bool,N}, b::BitArray{N}) = NamedArray(n.array .* b, n.dicts, n.dimnames)
.*{N}(b::BitArray{N}, n::NamedArray{Bool,N}) = n .* b

for op in (:+, :-, :.+, :.-, :.*, :./)
    ## named %op% named
    @eval begin
        function ($op){T1<:Number, T2<:Number}(x::NamedArray{T1}, y::NamedArray{T2})
            if allnames(x)==allnames(y) && x.dimnames==y.dimnames
                NamedArray(($op)(x.array,y.array), x.dicts, x.dimnames)
            else
                warn("Dropping mismatching names")
                ($op)(x.array,y.array)
            end
        end
        ($op){T1<:Number,T2<:Number,N}(x::NamedArray{T1,N}, y::AbstractArray{T2,N}) = NamedArray(($op)(x.array, y), x.dicts, x.dimnames)
        ($op){T1<:Number,T2<:Number,N}(x::AbstractArray{T1,N}, y::NamedArray{T2,N}) = NamedArray(($op)(x, y.array), y.dicts, y.dimnames)
    end
end

## scalar arithmetic
## disambiguate
for op in (:+, :-)
    @eval begin
        ($op)(x::NamedArray{Bool}, y::Bool) = NamedArray(($op)(x.array, y), x.dimnames, x.dicts)
        ($op)(x::Bool, y::NamedArray{Bool}) = NamedArray(($op)(x, y.array), y.dimnames, y.dicts)
    end
end

## NamedArray, Number
for op in (:+, :-, :*, :/, :.+, :.-, :.*, :./, :\ )
    @eval begin
        ($op){T1<:Number,T2<:Number}(x::NamedArray{T1}, y::T2) = NamedArray(($op)(x.array, y), x.dicts, x.dimnames)
        ($op){T1<:Number,T2<:Number}(x::T1, y::NamedArray{T2}) = NamedArray(($op)(x, y.array), y.dicts, y.dimnames)
    end
end

## NamedArray, AbstractArray, same dimensions
for op in (:+, :-, :.+, :.-, :.*, :./)
    @eval begin
        ($op)(x::NamedArray, y::AbstractArray) = NamedArray(($op)(x,y), x.dicts, x.dimnames)
    end
end

import Base.LinAlg: Givens, BlasFloat, lufact!, LU, ipiv2perm, cholfact!, cholfact, qrfact!, qrfact, eigfact!, eigvals!, hessfact ,schurfact!, schurfact, svdfact!, svdfact, svdvals!, svdvals, svd, diag, diagm, scale!, scale, cond, null, kron, linreg, lyap, sylvester, isposdef


## matmul
## ambiguity, this can somtimes be a pain to resolve...
*{Tx,TiA,Ty}(x::SparseMatrixCSC{Tx,TiA},y::NamedMatrix{Ty}) = x*y.array
*{Tx,S,Ty}(x::SparseMatrixCSC{Tx,S},y::NamedVector{Ty}) = x*y.array
for t in (:Tridiagonal, :AbstractTriangular, :Givens, :Bidiagonal)
    @eval *(x::$t, y::NamedMatrix) = NamedArray(x*y.array, ([string(i) for i in 1:size(x,1)],names(y,2)), y.dimnames)
    @eval *(x::$t, y::NamedVector) = x*y.array
end

## Named * Named
*(x::NamedMatrix, y::NamedMatrix) = NamedArray(x.array*y.array, (names(x,1),names(y,2)), (x.dimnames[1], y.dimnames[2]))
*(x::NamedMatrix, y::NamedVector) = NamedArray(x.array*y.array, (names(x,1),), (x.dimnames[1],))

## Named * Abstract
*(x::NamedMatrix, y::AbstractMatrix) = NamedArray(x.array*y, (names(x,1),[string(i) for i in 1:size(y,2)]), x.dimnames)
*(x::AbstractMatrix, y::NamedMatrix) = NamedArray(x*y.array, ([string(i) for i in 1:size(x,1)],names(y,2)), y.dimnames)
*(x::NamedMatrix, y::AbstractVector) = NamedArray(x.array*y, (names(x,1),), (x.dimnames[1],))
*(x::AbstractMatrix, y::NamedVector) = x*y.array

Base.Ac_mul_Bc!(A::Matrix, B::NamedMatrix, C::Matrix) = Ac_mul_Bc!(A, B.array, C)

## \ --- or should we overload A_div_B?
## Named \ Named
\(x::NamedVector, y::NamedVector) = x.array \ y.array
\(x::NamedMatrix, y::NamedVector) = NamedArray(x.array\y.array, (names(x,2),), (x.dimnames[2],))
\(x::NamedVector, y::NamedMatrix) = NamedArray(x.array\y.array, (["1"],names(y,2)), (:A, y.dimnames[2]))
\(x::NamedMatrix, y::NamedMatrix) = NamedArray(x.array\y.array, (names(x,2),names(y,2)), (x.dimnames[2], y.dimnames[2]))

## Named \ Abstract
\(x::NamedVector, y::AbstractVecOrMat) = x.array \ y
\(x::NamedMatrix, y::AbstractVector) = NamedArray(x.array \ y, (x.dicts[2],), (x.dimnames[2],))
\(x::NamedMatrix, y::AbstractMatrix) = NamedArray(x.array \ y, (names(x,2),[string(i) for i in 1:size(y,2)]), (x.dimnames[2],:B))
## Abstract \ Named
## ambiguity
\{Tx<:Number,Ty<:Number}(x::Diagonal{Tx}, y::NamedVector{Ty}) = x \ y.array
\{Tx<:Number,Ty<:Number}(x::Union(Bidiagonal{Tx},AbstractTriangular{Tx}), y::NamedVector{Ty}) = x \ y.array
\{Tx<:Number,Ty<:Number}(x::Union(Bidiagonal{Tx},AbstractTriangular{Tx}), y::NamedMatrix{Ty}) = NamedArray(x \ y.array, ([string(i) for i in 1:size(x,2)], names(y,2)), (:A, y.dimnames[2]))
if VERSION >= v"0.4.0-dev"
    \(x::Bidiagonal,y::NamedVector) = NamedArray(x \ y.array, ([string(i) for i in 1:size(x,2)], names(y,2)), (:A, y.dimnames[2]))
    \(x::Bidiagonal,y::NamedMatrix) = NamedArray(x \ y.array, ([string(i) for i in 1:size(x,2)], names(y,2)), (:A, y.dimnames[2]))
end
## AbstractVectorOrMat gives us more ambiguities than separate entries...
\(x::AbstractVector, y::NamedVector) = x \ y.array
\(x::AbstractMatrix, y::NamedVector) = x \ y.array
\(x::AbstractVector, y::NamedMatrix) = NamedArray(x \ y.array, (["1"],names(y,2)), (:A, y.dimnames[2]))
\(x::AbstractMatrix, y::NamedMatrix) = NamedArray(x \ y.array, ([string(i) for i in 1:size(x,2)], names(y,2)), (:A, y.dimnames[2]))

## keeping names for some matrix routines
for f in (:inv, :chol, :sqrtm, :pinv, :expm)
    eval(Expr(:import, :Base, f))
    @eval ($f)(n::NamedArray) = NamedArray(($f)(n.array), n.dicts, n.dimnames)
end

## tril, triu
Base.tril!(n::NamedMatrix, k::Integer) = (tril!(n.array, k); n)
Base.triu!(n::NamedMatrix, k::Integer) = (triu!(n.array, k); n)
Base.triu(n::NamedMatrix, k::Integer) = triu!(copy(n), k)
Base.tril(n::NamedMatrix, k::Integer) = tril!(copy(n), k)

## LU factorization
function lufact!{T}(n::NamedArray{T}; pivot=true)
    luf = lufact!(n.array; pivot=pivot)
    LU{T,typeof(n),}(n, luf.ipiv, luf.info)
end

## after lu.jl, this could be merged at Base.
function Base.getindex{T,DT,AT}(A::LU{T,NamedArray{T,2,AT,DT}}, d::Symbol)
    m, n = size(A)
    if d == :L
        L = tril!(A.factors[1:m, 1:min(m,n)])
        for i = 1:min(m,n); L[i,i] = one(T); end
        setnames!(L, defaultnames(L,2), 2)
        setdimnames!(L, :LU, 2)
        return L
    end
    if d == :U
        U = triu!(A.factors[1:min(m,n), 1:n])
        setnames!(U, defaultnames(U,1), 1)
        setdimnames!(U, :LU, 1)
        return U
    end
    d == :p && return ipiv2perm(A.ipiv, m)
    if d == :P
        p = A[:p]
        P = zeros(T, m, m)
        for i in 1:m
            P[i,p[i]] = one(T)
        end
        return P
    end
    throw(KeyError(d))
end

## TODO: wait until Cholesky and CholeskyPivoted contain abstractmatrix types
function cholfact!{T<:BlasFloat}(n::NamedArray{T}, uplo::Symbol=:U; pivot=false, tol=0.0)
    uplochar = string(uplo)[1]
    if pivot
        A, piv, rank, info = LAPACK.pstrf!(uplochar, n.array, tol)
        return CholeskyPivoted{T}(A, uplochar, piv, rank, tol, info)
    else
        C, info = LAPACK.potrf!(uplochar, n.array)
        return info==0 ?  Cholesky(C, uplochar) : throw(PosDefException(info))
    end
end

cholfact{T<:BlasFloat}(n::NamedArray{T}, uplo::Symbol=:U; pivot=false, tol=0.0) = cholfact!(copy(n), uplo, pivot=pivot, tol=tol)

## ldlt skipped

## TODO: Wait for factorization.jl to change type of QR: AbstractMatrix
## from factorization
qrfact!{T<:BlasFloat}(n::NamedMatrix{T}; pivot=false) = pivot ? QRPivoted{T}(LAPACK.geqp3!(n.array)...) : QRCompactWY(LAPACK.geqrt!(n.array, min(minimum(size(A)), 36))...)
qrfact{T<:Base.LinAlg.BlasFloat}(n::NamedMatrix{T}; pivot=false) = qrfact!(copy(n.array),pivot=pivot)

eigfact!(n::NamedMatrix; permute::Bool=true, scale::Bool=true) = eigfact!(n.array, permute=permute, scale=scale)

eigvals!(n::NamedMatrix; permute::Bool=true, scale::Bool=true) = eigvals!(n.array, permute=permute, scale=scale)

hessfact!(n::NamedMatrix) = hessfact!(n.array)

schurfact!(n::NamedMatrix) = schurfact!(n.array)
schurfact(n::NamedMatrix) = schurfact!(copy(n))
schurfact(A::NamedMatrix, B::AbstractMatrix) = schurfact!(A.array, B)

svdfact!(n::NamedMatrix; thin::Bool=true) = svdfact!(n.array; thin=thin)
svdfact{T<:BlasFloat}(A::NamedMatrix{T};thin=true) = svdfact!(copy(A),thin=thin)

svdvals!(n::NamedArray) = svdvals!(n.array)
svdvals(n::NamedArray) = svdvals(n.array)

diag(n::NamedMatrix) = NamedArray(diag(n.array), n.dicts[1:1], n.dimnames[1:1])

diagm(n::NamedVector) = NamedArray(diagm(n.array), n.dicts[[1,1]], n.dimnames[[1,1]])

scale!(C::NamedMatrix, b::AbstractVector, A::AbstractMatrix) = (scale!(C.array, b, A); C)
scale(A::NamedMatrix, b::AbstractVector) = NamedArray(scale(A.array, b), A.dicts, A.dimnames)
scale(b::AbstractVector, A::NamedMatrix) = NamedArray(scale(b, A.array), A.dicts, A.dimnames)

# rank, vecnorm, norm, condskeel, trace, det, logdet OK
cond(n::NamedArray) = cond(n.array)

null(n::NamedArray) = null(n.array)

function kron(a::NamedArray, b::NamedArray)
    n = Array(typeof(String[]), 2)
    dn = String[]
    for dim in 1:2
        n[dim] = String[]
        for i in names(a, dim)
            for j in names(b, dim)
                push!(n[dim], string(i, "×", j))
            end
        end
        push!(dn, string(dimnames(a,dim), "×", dimnames(b,dim)))
    end
    NamedArray(kron(a.array, b.array), tuple(n...), tuple(dn...))
end

linreg(x::NamedVecOrMat, y::AbstractVector) = linreg(x.array, y)
linreg(x::NamedVecOrMat, y::AbstractVector, w::AbstractVector) = linreg(x.array, y, w)

lyap(A::NamedMatrix, C::AbstractMatrix) = NamedArray(lyap(A.array,C), A.dicts, A.dimnames)

sylvester(A::NamedMatrix, B::AbstractMatrix, C::AbstractMatrix) = NamedArray(sylvester(A.array, B, C), A.dicts, A.dimnames)

## issym, istriu, istril OK
isposdef(n::NamedArray) = isposdef(n.array)

## eigs OK
