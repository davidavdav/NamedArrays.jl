NamedArray
==========

Julia type that implements a drop-in replacement of Array with named dimensions. 

Idea
----

We would want to have the possibility to give each row/column/... in
an Array names, as well as the array dimensions themselves.  This
could be used for pretty-printing, indexing, and perhaps even some
sort of dimension-checking in certain matrix computations.

In all other respects, a NamedArray should be the same as an Array. 

Synopsis
--------

```julia
reload("src/NamedArray.jl")
n = NamedArray(rand(2,4))
setnames!(n, ["one", "two"], 1)         # give the names "one" and "two" to the rows (dimension 1)
n["one", 2:3]
n["two", :] = 11:14
n[!"two", :] = 4:7                      # all rows but the one called "two"
n
sum(n,1)
```
    
Implementation status
---------------------

 * Construction

```julia
NamedArray(a::Array)
NamedArray(::Type{T}, dims...)
```

these constructors add default names to the array of type String, "1",
"2", ... for each dimension, and names the dimensions "A", "B",
... (which will be all right for 26 dimensions to start with; 26
dimensions should be enough for anyone:-).  The former initializes
the NamedArray with the Array `a`, the latter makes an uninitialized
NamedArray of element type `T` with the specified dimensions `d...`. 

 * Copy

```julia
copy(a::NamedArray)
```

makes a deep-copy of all the elements in a, and returns a NamedArray

 * Convert

```julia
convert(::Type{Array}, a::NamedArray)
```

 converts a NamedArray to an Array by dropping al names information

 * Arithmetic:
  - `*` and `.*` between numbers and NamedArray.  

 This is just a first attempt.  Code should probably be generated in
meta programming. 

 * Print, Show:
  - basic printing, no pretty-printing yet. 

 * Size, ndims

 * Similar

```julia
similar(a::NamedArray, t::DataType, dims::NTuple)
```

 * Getindex

```julia
getindex(A::NamedArray, s0::String)
getindex(A::NamedArray, s::String...)
getindex(A::NamedArray, i0::Real) 
getindex(A::NamedArray, I::IndexOrNamed...)
```

 here type IndexOrNamed is a union of most indexable types:

```julia
typealias IndexOrNamed Union(Real, Range1, String, AbstractVector)
```

 This allows indexing of most combinations of integer, range, string,
vector of integer and Vector of String of any number of dimensions, as
long as the underlying Array supports the indexing. 

 * Setindex

```julia
setindex!(A::NamedArray, x, i0::Real)
setindex!(A::NamedArray, x, I::AbstractVector 
setindex!(A::NamedArray, X::ArrayOrNamed, I::Range1)
setindex!(A::NamedArray, X::AbstractArray, I::AbstractVector)
setindex!(A::NamedArray, x, I::IndexOrNamed...)
```

 various forms of setindex!(), allowing most indexed expressions as LHS
in an assignment. 

 * Concatenation

```julia
hcat(V::NamedVector...)
```

 concatenates (column) vectors to an array.  If the names are identical
for all vectors, these are retained in the results.  Otherwise
the names are reinitialized to the default "1", "2", ...

 * Sum, prod, minimum, maximum

 These functions, when operating along one dimension, keep the names in the orther dimensions, and name the left over singleton dimension as $function($dimname).

Methods that AbstractArray covers
---------------------------

Some methods work automatically with NamedArrays courtesy of the super
type AbstractArray.  However, they may not treat the names attributes
correctly

```julia
a::NamedArray
b::NamedArray
d::Int
function f
sum(a)
prod(a)
isequal(a,b)
==(a, b)
cumsum(a)
cumsum(a, d)
cumprod(a)
cumprod(a, d)
maximum(a)
eltype(a)
cummin(a)
cummin(a, d)
cummax(a)
cummanx(a, d)
repmat(a, d1, d2)
nnz(a)
minimum(a)
mapslices(f, a, d)
map(f, a)
```

Implementation
------------

Currently, the type is defined as

```julia
type NamedArray{T,N} <: AbstractArray{T,N}
    array::Array{T,N}
    names::Vector{Vector}
    dimnames::Vector
    dicts::Array{Dict}
}
```

but the inner constructor actually expects `NTuple`s for `names` and `dimnames`, which more easily allows somewhat stricter typechecking.   This is sometimes a bit annoying, if you want to initialize a new NamedArray from known `names` and `dimnames`.  You can use the expression `tuple(Vector)...` for that.

