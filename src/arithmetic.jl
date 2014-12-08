## arithmetic.jl operators for NamedArray

## (c) 2013 David A. van Leeuwen

## This code is licensed under the MIT License
## See the file LICENSE.md in this distribution

## disambiguation
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
    end
end

## matmul
## ambiguity, this can somtimes be a pain to resolve...
*{Tx,TiA,Ty}(x::SparseMatrixCSC{Tx,TiA},y::NamedMatrix{Ty}) = x*y.array
*{Tx,S,Ty}(x::SparseMatrixCSC{Tx,S},y::NamedVector{Ty}) = x*y.array
for t in (:Tridiagonal, :Triangular, :(Base.LinAlg.Givens), :Bidiagonal)
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
