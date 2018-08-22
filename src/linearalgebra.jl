Base.strides(n::NamedArray) = Base.strides(n.array)

Base.unsafe_convert(p::Type{Ptr{T}}, n::NamedArray) where T = Base.unsafe_convert(p, n.array)

# TODO: solve TODO problems in tests for arithmetic here using the new LinearAlgebra stdlib
