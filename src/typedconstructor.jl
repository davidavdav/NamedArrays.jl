## Only read this for julia-0.5 and up

## default / fallback Constructors
(::Type{NamedArray{T}}){T}(n) = NamedArray(Array{T}(n))
