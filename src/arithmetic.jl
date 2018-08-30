## arithmetic.jl operators for NamedArray

## (c) 2013--2014 David A. van Leeuwen

## This code is licensed under the MIT License
## See the file LICENSE.md in this distribution

import Base: +, -, *, /, \

-(n::NamedArray) = NamedArray(-n.array, n.dicts, n.dimnames)

## disambiguation magic

# disambiguation (Argh...)
for op in (:+, :-)
    @eval ($op)(x::AbstractRange{T1}, y::NamedVector{T2}) where {T1<:Number,T2<:Number} = NamedArray(($op)(x, y.array), y.dicts, y.dimnames)
    @eval ($op)(x::NamedVector{T1}, y::AbstractRange{T2}) where {T1<:Number,T2<:Number} = NamedArray(($op)(x.array, y), x.dicts, x.dimnames)
end

for op in (:+, :-)
    ## named %op% named
    @eval begin
        function ($op)(x::NamedArray{T1}, y::NamedArray{T2}) where {T1<:Number, T2<:Number}
            if names(x) == names(y) && x.dimnames == y.dimnames
                NamedArray(($op)(x.array, y.array), x.dicts, x.dimnames)
            else
                @warn("Dropping mismatching names")
                ($op)(x.array, y.array)
            end
        end
        ($op)(x::NamedArray{T1,N}, y::AbstractArray{T2,N}) where {T1<:Number,T2<:Number,N} = NamedArray(($op)(x.array, y), x.dicts, x.dimnames)
        ($op)(x::AbstractArray{T1,N}, y::NamedArray{T2,N}) where {T1<:Number,T2<:Number,N} = NamedArray(($op)(x, y.array), y.dicts, y.dimnames)
    end
end

## scalar arithmetic
## disambiguate
for op in (:+, :-)
    @eval begin
        ($op)(x::NamedArray{Bool}, y::Bool) = NamedArray(($op)(x.array, y), x.dicts, x.dimnames)
        ($op)(x::Bool, y::NamedArray{Bool}) = NamedArray(($op)(x, y.array), y.dicts, y.dimnames)
    end
end

## NamedArray, Number

for op in (:+, :-, :*)
    @eval begin
        ($op)(x::NamedArray{T1}, y::T2) where {T1<:Number,T2<:Number} = NamedArray(($op)(x.array, y), x.dicts, x.dimnames)
        ($op)(x::T1, y::NamedArray{T2}) where {T1<:Number,T2<:Number} = NamedArray(($op)(x, y.array), y.dicts, y.dimnames)
    end
end
/(x::NamedArray{T1}, y::T2) where {T1<:Number,T2<:Number} = NamedArray(x.array / y, x.dicts, x.dimnames)
\(x::T1, y::NamedArray{T2}) where {T1<:Number,T2<:Number} = NamedArray(x \ y.array, y.dicts, y.dimnames)

# import LinearAlgebra: A_mul_B!, A_mul_Bc!, A_mul_Bc, A_mul_Bt!, A_mul_Bt, Ac_mul_B, Ac_mul_B!, Ac_mul_Bc, Ac_mul_Bc!, At_mul_B, At_mul_B!, At_mul_Bt, At_mul_Bt!

## Assume dimensions/names are correct
for op in (:A_mul_B!, :A_mul_Bc!, :A_mul_Bt!, :Ac_mul_B!, :Ac_mul_Bc!, :At_mul_B!, :At_mul_Bt!)
    @eval ($op)(C::NamedMatrix, A::AbstractMatrix, B::AbstractMatrix) = ($op)(C.array, A, B)
end

for op in (:A_mul_Bc, :A_mul_Bt)
    @eval ($op)(A::NamedMatrix, B::NamedMatrix) = NamedArray(($op)(A.array, B.array), (A.dicts[1], B.dicts[1]), (A.dimnames[1], B.dimnames[1]))
    for T in [Union{LinearAlgebra.QRCompactWYQ, LinearAlgebra.QRPackedQ}, StridedMatrix, AbstractMatrix] ## v0.4 ambiguity-hell
        @eval ($op)(A::NamedMatrix, B::$T) = NamedArray(($op)(A.array, B), (A.dicts[1], defaultnamesdict(size(B,1))), (A.dimnames[1], :B))
        @eval ($op)(A::$T, B::NamedMatrix) = NamedArray(($op)(A, B.array), (defaultnamesdict(size(A,1)), B.dicts[1]), (:A, B.dimnames[1]))
    end
end
for op in (:Ac_mul_B, :At_mul_B)
    @eval ($op)(A::NamedMatrix, B::NamedMatrix) = NamedArray(($op)(A.array, B.array), (A.dicts[2], B.dicts[2]), (A.dimnames[2], B.dimnames[2]))
    for T in [StridedMatrix, AbstractMatrix] ## v0.4 ambiguity-hell
        @eval ($op)(A::NamedMatrix, B::$T) = NamedArray(($op)(A.array, B), (A.dicts[2], defaultnamesdict(size(B,2))), (A.dimnames[2], :B))
        @eval ($op)(A::$T, B::NamedMatrix) = NamedArray(($op)(A, B.array), (defaultnamesdict(size(A,2)), B.dicts[2]), (:A, B.dimnames[2]))
    end
end
for op in (:Ac_mul_Bc, :At_mul_Bt)
    @eval ($op)(A::NamedMatrix, B::NamedMatrix) = NamedArray(($op)(A.array, B.array), (A.dicts[2], B.dicts[1]), (A.dimnames[2], B.dimnames[1]))
    for T in [StridedMatrix, AbstractMatrix] ## v0.4 ambiguity-hell
        @eval ($op)(A::NamedMatrix, B::$T) = NamedArray(($op)(A.array, B), (A.dicts[2], defaultnamesdict(size(B,1))), (A.dimnames[2], :B))
        @eval ($op)(A::$T, B::NamedMatrix) = NamedArray(($op)(A, B.array), (defaultnamesdict(size(A,2)), B.dicts[1]), (:A, B.dimnames[1]))
    end
end

import LinearAlgebra: Givens, LinearAlgebra.BlasFloat, lu!, lu, LU, ipiv2perm, qr!, qr, eigen!, eigen, eigvals!,
    eigvals, hessenberg, hessenberg!, schur!, schur, svd!, svd, svdvals!, svdvals, svd, diag,
    cond, kron, lyap, sylvester, isposdef

## matmul
## ambiguity, this can somtimes be a pain to resolve...
*(x::SparseMatrixCSC{Tx,TiA},y::NamedMatrix{Ty}) where {Tx,TiA,Ty} = x*y.array
*(x::SparseMatrixCSC{Tx,S},y::NamedVector{Ty}) where {Tx,S,Ty} = x*y.array
for t in (:Tridiagonal, :(LinearAlgebra.AbstractTriangular), :Givens, :Bidiagonal)
    @eval *(x::$t, y::NamedMatrix) = NamedArray(x*y.array, ([string(i) for i in 1:size(x,1)],names(y, 2)), y.dimnames)
    @eval *(x::$t, y::NamedVector) = x*y.array
end

## There is no such thing as a A_mul_B
## Named * Named
*(A::NamedMatrix, B::NamedMatrix) = NamedArray(A.array * B.array, (A.dicts[1], B.dicts[2]), (A.dimnames[1], B.dimnames[2]))
function *(A::NamedMatrix, B::NamedVector)
    result = A.array * B.array
    if isa(result, AbstractArray)
        return NamedArray(result, (A.dicts[1],), (B.dimnames[1],))
    else
        return result
    end
end

if  @isdefined RowVector
    *(A::NamedRowVector, B::NamedVector) = A.array * B.array
end
## Named * Abstract
*(A::NamedMatrix, B::AbstractMatrix) = NamedArray(A.array * B, (A.dicts[1], defaultnamesdict(size(B,2))), A.dimnames)
*(A::AbstractMatrix, B::NamedMatrix) = NamedArray(A * B.array, (defaultnamesdict(size(A,1)), B.dicts[2]), B.dimnames)
*(A::NamedMatrix, B::AbstractVector) = NamedArray(A.array * B, (A.dicts[1],), (A.dimnames[1],))
*(A::AbstractMatrix, B::NamedVector) = A * B.array
if @isdefined RowVector
    *(A::NamedRowVector, B::AbstractVector) = A.array * B
end
## \ --- or should we overload A_div_B?
## Named \ Named
\(x::NamedVector, y::NamedVector) = x.array \ y.array
\(x::NamedMatrix, y::NamedVector) = NamedArray(x.array\y.array, (names(x, 2),), (x.dimnames[2],))
\(x::NamedVector, y::NamedMatrix) = NamedArray(x.array\y.array, (["1"],names(y, 2)), (:A, y.dimnames[2]))
\(x::NamedMatrix, y::NamedMatrix) = NamedArray(x.array\y.array, (names(x, 2),names(y, 2)), (x.dimnames[2], y.dimnames[2]))

## Named \ Abstract
\(x::NamedVector, y::AbstractVecOrMat) = x.array \ y
\(x::NamedMatrix, y::AbstractVector) = NamedArray(x.array \ y, (x.dicts[2],), (x.dimnames[2],))
\(x::NamedMatrix, y::AbstractMatrix) = NamedArray(x.array \ y, (names(x, 2),[string(i) for i in 1:size(y,2)]), (x.dimnames[2],:B))
## Abstract \ Named
## ambiguity
\(x::Diagonal{Tx}, y::NamedVector{Ty}) where {Tx<:Number,Ty<:Number} = x \ y.array
\(x::Union{Bidiagonal{Tx},LinearAlgebra.AbstractTriangular{Tx}}, y::NamedVector{Ty}) where {Tx<:Number,Ty<:Number} = x \ y.array
\(x::Union{Bidiagonal{Tx},LinearAlgebra.AbstractTriangular{Tx}}, y::NamedMatrix{Ty}) where {Tx<:Number,Ty<:Number} = NamedArray(x \ y.array, (defaultnamesdict(size(x,1)), y.dicts[2]), (:A, y.dimnames[2]))

\(x::Bidiagonal,y::NamedVector) = NamedArray(x \ y.array, ([string(i) for i in 1:size(x,2)], names(y, 2)), (:A, y.dimnames[2]))
\(x::Bidiagonal,y::NamedMatrix) = NamedArray(x \ y.array, ([string(i) for i in 1:size(x,2)], names(y, 2)), (:A, y.dimnames[2]))

## AbstractVectorOrMat gives us more ambiguities than separate entries...
\(x::AbstractVector, y::NamedVector) = x \ y.array
\(x::AbstractMatrix, y::NamedVector) = x \ y.array
\(x::AbstractVector, y::NamedMatrix) = NamedArray(x \ y.array, (["1"],names(y, 2)), (:A, y.dimnames[2]))
\(x::AbstractMatrix, y::NamedMatrix) = NamedArray(x \ y.array, ([string(i) for i in 1:size(x,2)], names(y, 2)), (:A, y.dimnames[2]))

## keeping names for some matrix routines
for f in (:inv, :sqrt, :pinv, :exp) # :chol
    @eval (LinearAlgebra.$f)(n::NamedArray) = NamedArray(($f)(n.array), n.dicts, n.dimnames)
end
# TODO :  `chol(A::AbstractMatrix)` is deprecated, use `(cholesky(A)).U` instead.

## tril, triu
LinearAlgebra.tril!(n::NamedMatrix, k::Integer) = (tril!(n.array, k); n)
LinearAlgebra.triu!(n::NamedMatrix, k::Integer) = (triu!(n.array, k); n)

## LU factorization
function LinearAlgebra.lu!(n::NamedArray{T, N, AT, DT}, pivot = Val(true); kargs...) where {T, N, AT, DT}
    luf = lu!(n.array, pivot; kargs...)
    LU(n, luf.ipiv, luf.info)
end

# From /stdlib/LinearAlgebra/src/lu.jl
function Base.getproperty(A::LU{T,NamedArray{T, N, AT, DT}}, d::Symbol) where {T, N, AT, DT}
    m, n = size(A)
    if d == :L
        L = tril!(getfield(A, :factors)[1:m, 1:min(m,n)])
        for i = 1:min(m,n); L[i,i] = one(T); end
        setnames!(L, defaultnames(L,2), 2)
        setdimnames!(L, :LU, 2)
        return L
    elseif d == :U
        U = triu!(getfield(A, :factors)[1:min(m,n), 1:n])
        setnames!(U, defaultnames(U,1), 1)
        setdimnames!(U, :LU, 1)
        return U
    elseif d == :p
        return ipiv2perm(getfield(A, :ipiv), m)
    elseif d == :P
        return Matrix{T}(I, m, m)[:,invperm(A.p)]
    else
        getfield(F, d)
    end
end

# TODO: function cholfact!(n::NamedArray{T}, uplo::Symbol=:U) where T<:LinearAlgebra.BlasFloat
# TODO:     ishermitian(n) || LinearAlgebra.non_hermitian_error("cholfact!")
# TODO:     return cholfact!(Hermitian(n, uplo))
# TODO: end

# TODO: cholfact(n::NamedArray{T}, uplo::Symbol=:U) where {T<:LinearAlgebra.BlasFloat} = cholfact!(copy(n), uplo)

## ldlt skipped

## from factorization
function qr!(n::NamedMatrix, pivot)
    qr = qr!(n.array, pivot)
    LinearAlgebra.QRCompactWY(NamedArray(qr.factors, n.dicts, n.dimnames), qr.T)
end
qr!(n::NamedArray) = qr!(n, Val(false))

LAPACK.gemqrt!(side::Char, trans::Char, V::NamedArray{BF}, T::StridedMatrix{BF}, C::StridedVecOrMat{BF}) where {BF<:LinearAlgebra.BlasFloat} = LAPACK.gemqrt!(side, trans, V.array, T, C)

qr(n::NamedMatrix{T}, pivot = Val(false)) where {T<:LinearAlgebra.BlasFloat} = qr!(copy(n), pivot)

eigen!(n::NamedMatrix; permute::Bool=true, scale::Bool=true) = eigen!(n.array, permute=permute, scale=scale)
eigen(n::NamedMatrix; permute::Bool=true, scale::Bool=true) = eigen!(copy(n.array), permute=permute, scale=scale)

eigvals!(n::NamedMatrix; permute::Bool=true, scale::Bool=true) = eigvals!(n.array, permute=permute, scale=scale)
eigvals(n::NamedMatrix; permute::Bool=true, scale::Bool=true) = eigvals!(copy(n.array), permute=permute, scale=scale)

hessenberg!(n::NamedMatrix) = hessenberg!(n.array)
hessenberg(n::NamedMatrix) = hessenberg(copy(n.array))

schur!(n::NamedMatrix) = schur!(n.array)
schur(n::NamedMatrix) = schur!(copy(n.array))
schur(A::NamedMatrix, B::AbstractMatrix) = schur(A.array, B)
schur!(A::NamedMatrix, B::AbstractMatrix) = schur!(A.array, B)

svd!(n::NamedMatrix; full::Bool=false) = svd!(n.array; full=full)
svd(A::NamedMatrix{T}; full=false) where {T<:LinearAlgebra.BlasFloat} = svd!(copy(A), full=full)

svdvals!(n::NamedArray) = svdvals!(n.array)
svdvals(n::NamedArray) = svdvals(copy(n.array))

# TODO : diag(n::NamedMatrix) = NamedArray(diag(n.array), n.dicts[1:1], n.dimnames[1:1])

# TODO : diagm(n::NamedVector) = NamedArray(diagm(n.array), n.dicts[[1,1]], n.dimnames[[1,1]])

# rank, vecnorm, norm, condskeel, trace, det, logdet OK
cond(n::NamedArray) = cond(n.array)

# null(n::NamedArray) = null(n.array)

function kron(a::NamedArray, b::NamedArray)
    n = Array{typeof(AbstractString[])}(undef, 2)
    dn = AbstractString[]
    for dim in 1:2
        n[dim] = AbstractString[]
        for i in names(a, dim)
            for j in names(b, dim)
                push!(n[dim], string(i, "×", j))
            end
        end
        push!(dn, string(dimnames(a,dim), "×", dimnames(b,dim)))
    end
    NamedArray(kron(a.array, b.array), tuple(n...), tuple(dn...))
end

# linreg(x::NamedVector, y::AbstractVector) = linreg(x.array, y)

lyap(A::NamedMatrix, C::AbstractMatrix) = NamedArray(lyap(A.array,C), A.dicts, A.dimnames)

sylvester(A::NamedMatrix, B::AbstractMatrix, C::AbstractMatrix) = NamedArray(sylvester(A.array, B, C), A.dicts, A.dimnames)

## issym, istriu, istril OK
isposdef(n::NamedArray) = isposdef(n.array)

## eigs OK
