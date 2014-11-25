## changingnames.jl  methods for NamedArray that change some of the names 

## (c) 2013 David A. van Leeuwen

## This code is licensed under the GNU General Public License, version 2
## See the file LICENSE in this distribution

## sum etc: keep names in one dimension
# import Base.sum, Base.prod, Base.maximum, Base.minimum, Base.mean, Base.std
for f = (:sum, :prod, :maximum, :minimum, :mean, :std, :var)
    eval(Expr(:import, :Base, f))
    @eval function ($f)(a::NamedArray, d::Dims)
        s = ($f)(a.array, d)
        newnames = [issubset(i,d) ? [string($f,"(",a.dimnames[i],")")] : names(a,i) for i=1:ndims(a)]
        NamedArray(s, tuple(newnames...), tuple(a.dimnames...))
    end
    @eval ($f)(a::NamedArray, d::Int) = ($f)(a, (d,))
end

function fan(f::Function, fname::String, a::NamedArray, dim::Int) 
    dimnames = copy(a.dimnames)
    dimnames[dim] = string(fname, "(", dimnames[dim], ")")
    NamedArray(f(a.array,dim), tuple(allnames(a)...), tuple(dimnames...))
end

## rename a dimension
for f in (:cumprod, :cumsum, :cumsum_kbn, :cummin, :cummax)
    eval(Expr(:import, :Base, f))
    @eval ($f)(a::NamedArray, d=1) = fan($f, string($f), a, d)
end

