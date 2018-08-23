Base.strides(n::NamedArray) = Base.strides(n.array)

Base.unsafe_convert(p::Type{Ptr{T}}, n::NamedArray) where T = Base.unsafe_convert(p, n.array)

# # Based in LinearAlgebra/src/matmul.jl: *(A::AbstractArray{T,2}, B::AbstractArray{T,2})
# function Base.:*(A::NamedArray{TA, 2, ATA, NTA},
#                  B::NamedArray{TB, 2, ATB, NTB}) where {TA, TB, ATA, ATB, NTA, NTB}
#     TS = Base.promote_op(LinearAlgebra.matprod, TA, TB)
#     out_size = (size(A,1), size(B,2))
#     dump(out_size)
#     out = NamedArray(Array{TS}(undef, out_size),
#                      (A.dicts[1], B.dicts[2]),
#                      (A.dimnames[1], B.dimnames[2]))
#     mul!(out, A.array, B.array)
# end
#
# LinearAlgebra.qr(n::NamedArray, args...) = qr(n.array, args...)
