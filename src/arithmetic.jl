## arithmetic.jl operators for NamedArray

## (c) 2013 David A. van Leeuwen

## This code is licensed under the MIT License
## See the file LICENSE.md in this distribution

for op in (:+, :-, :.+, :.-, :.*, :./)
    ## named %op% named
    @eval function ($op)(x::NamedArray, y::NamedArray)
        if names(x)==names(y) && dimnames(x)==dimnames(y)
            NamedArray(($op)(x.array,y.array), names(x), dimnames(x))
        else
            warn("Dropping mismatching names")
            ($op)(x.array,y.array)
        end
    end
    ## named %op% array
    @eval ($op)(x::NamedArray, y::Array) = NamedArray(($op)(x.array, y), names(x), x.dimnames)
    @eval ($op)(x::Array, y::NamedArray) = NamedArray(($op)(x, y.array), names(y), y.dimnames)
end
## Let's say I don't understand promote
#for op in (:+, :-, :.+, :.-, :.*, :*, :/, :\ ) 
#    @eval ($op)(x::AbstractArray, y::AbstractArray) = ($op)(promote(x,y)...)
#end
## matmul
*(x::NamedArray, y::NamedArray) = NamedArray(x.array*y.array, (names(x,1),names(y,2)), (x.dimnames[1], y.dimnames[2]))
## scalar arithmetic
## disambiguate
for op in (:+, :-)
    @eval begin
        ($op)(x::NamedArray{Bool}, y::Bool) = NamedArray(($op)(x.array, y), x.dimnames, x.dicts)
        ($op)(x::Bool, y::NamedArray{Bool}) = NamedArray(($op)(x, y.array), y.dimnames, y.dicts)
    end
end
        
for op in (:+, :-, :*, :/, :.+, :.-, :.*, :./, :\ )
    @eval function ($op)(x::NamedArray, y::Number) 
        if promote_type(eltype(x),typeof(y)) == eltype(x)
            r = copy(x)
            r.array = $op(x.array,y)
        else
            NamedArray(($op)(x.array, y), x.dimnames, x.dicts)
        end
    end
    @eval function ($op)(x::Number, y::NamedArray) 
        if promote_type(typeof(x), eltype(y)) == eltype(y)
            r = copy(y)
            r.array = $op(x, y.array)
        else
            NamedArray(($op)(x, y.array), x.dimnames, x.dicts)
        end
    end
end

