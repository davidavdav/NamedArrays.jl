NamedArrays
===========

Julia type that implements a drop-in wrapper for `AbstractArray` type, providing named indices and dimensions.

[![Build Status](https://travis-ci.org/davidavdav/NamedArrays.jl.svg)](https://travis-ci.org/davidavdav/NamedArrays.jl)
[![NamedArrays](http://pkg.julialang.org/badges/NamedArrays_0.5.svg)](http://pkg.julialang.org/?pkg=NamedArrays)
[![NamedArrays](http://pkg.julialang.org/badges/NamedArrays_0.6.svg)](http://pkg.julialang.org/?pkg=NamedArrays)
[![Coverage Status](https://coveralls.io/repos/github/davidavdav/NamedArrays.jl/badge.svg?branch=master)](https://coveralls.io/github/davidavdav/NamedArrays.jl?branch=master)

Idea
----

We would want to have the possibility to give each row/column/... in
an Array names, as well as the array dimensions themselves.  This
could be used for pretty-printing, indexing, and perhaps even some
sort of dimension-checking in certain matrix computations.

In all other respects, a `NamedArray` should behave the same as the underlying `AbstractArray`.

A `NamedArray` should adhere to the [interface definition](https://docs.julialang.org/en/latest/manual/interfaces/#man-interface-array-1) of an `AbstractArray` itself, if there are cases where this is not true, these should be considered bugs in the implementation of `NamedArrays`.

Synopsis
--------

```julia
using NamedArrays
n = NamedArray(rand(2,4))
setnames!(n, ["one", "two"], 1)         # give the names "one" and "two" to the rows (dimension 1)
n["one", 2:3]
n["two", :] = 11:14
n[Not("two"), :] = 4:7                  # all rows but the one called "two"
n
sum(n, 1)
```

Construction
-------

### Default names for indices and dimensions
```julia
# NamedArray(a::Array)
n = NamedArray([1 2; 3 4])
# NamedArray{T}(dims...)
n = NamedArray{Int}(2, 2)
```

These constructors add default names to the array of type String, `"1"`,
`"2"`, ... for each dimension, and names the dimensions `:A`, `:B`,
... (which will be all right for 26 dimensions to start with; 26
dimensions should be enough for anyone:-).  The former initializes
the NamedArray with the Array `a`, the latter makes an uninitialized
NamedArray of element type `T` with the specified dimensions `dims...`.

### Lower level constructors

The key-lookup for names is implemented by using `DataStructures.OrderedDict`s for each dimension.  At a lower level, you can construct `NamedArrays` this way:
```julia
using DataStructures
n = NamedArray([1 3; 2 4], ( OrderedDict("A"=>1, "B"=>2), OrderedDict("C"=>1, "D"=>2) ),
               ("Rows", "Cols"))
```
This is the basic constructor for a namedarray.  The second argument `names` must be a tuple of `OrderedDict`s whose range (the values) are exacly covering the range `1:size(a,dim)` for each dimension.   The keys in the various dictionaries may be of mixed types, but after construction, the type of the names cannot be altered.  The third argument `dimnames` is a tuple of the names of the dimensions themselves, and these names may be of any type.

### Vectors/tuples of names

```julia
# NamedArray{T,N}(a::AbstractArray{T,N}, names::NTuple{N,Vector}, dimnames::NTuple{N})
n = NamedArray([1 3; 2 4], ( ["a", "b"], ["c", "d"] ), ("Rows", "Cols"))
# NamedArray{T,N}(a::AbstractArray{T,N}, names::NTuple{N,Vector})
n = NamedArray([1 3; 2 4], ( ["a", "b"], ["c", "d"] ))
n = NamedArray([1, 2], ( ["A", "B"], ))  # note the comma after ["A", "B"] to ensure evaluation as tuple
```
This is a more friendly version of the basic constructor, where the range of the dictionaries is automatically assigned the values `1:size(a, dim)` for the `names` in order. If `dimnames` is not specified, the default values will be used (`:A`, `:B`, etc.).

In principle, there is no limit imposed to the type of the `names` used, but we discourage the use of `Real`, `AbstractArray` and `Range`, because they have a special interpretation in `getindex()` and `setindex`.

Indexing
------

### `Integer` indices

Single and multiple integer indices work as for the undelying array:

```julia
n[1, 1]
n[1]
```

Because the constructed `NamedArray` itself is an `AbstractArray`, integer indices always have precedence:

```julia
a = rand(2, 4)
dodgy = NamedArray(a, ([2, 1], [10, 20, 30, 40]))
dodgy[1, 1] == a[1, 1] ## true
dodgy[1, 10] ## BoundsError
```
In some cases, e.g., with contingency tables, it would be very handy to be able to use named Integer indices.  In this case, in order to circumvent the normal `AbstractArray` interpretation of the index, you can wrap the indexing argument in the type `Name()`
```julia
dodgy[Name(1), Name(30)] == a[2, 3] ## true
```

### Named indices

```julia
n = NamedArray([1 2 3; 4 5 6], (["one", "two"], [:a, :b, :c]))
n["one", :a] == 1
n[:, :b] == [2, 5]
n["two", [1, 3]] == [4, 6]
n["one", [:a, :b]] == [1, 2]
```

This is the main use of `NamedArrays`.  Names (keys) and arrays of names can be specified as an index, and these can be mixed with other forms of indexing.

### Slices

The example above just shows how the indexing works for the values, but there is a slight subtlety in how the return type of slices is determined

When a single element is selected by an index expression, a scalar value is returned.  When an array slice is selected, an attempt is made to return a NamedArray with the correct names for the dimensions.


```julia
julia> n[:, :b] ## this expression drops the singleton dimensions, and hence the names
2-element Named Array{Int64,1}
A   │
────┼──
one │ 2
two │ 5

julia> n[["one"], [:a]] ## this expression keeps the names
1×1 Named Array{Int64,2}
A ╲ B │ :a
──────┼───
one   │  1
```

### Negation / complement

There is a special type constructor `Not()`, whose function is to specify which elements to exclude from the array.  This is similar to negative indices in the language R.  The elements in `Not(elements...)` select all but the indicated elements from the array.

```julia
n[Not(1), :] == n[[2], :] ## true, note that `n` stays 2-dimensional
n[2, Not(:a)] == n[2, [:b, :c]] ## true
dodgy[1, Not(Name(30))] == dodgy[1, [1, 2, 4]] ## true
```
Both integers and names can be negated.

### Dictionary-style indexing

You can also use a dictionary-style indexing, if you don't want to bother about the order of the dimensions, or make a slice using a specific named dimension:
```julia
n[:A => "one"] == [1, 2, 3]
n[:B => :c, :A => "two"] == 6
```
This style cannot be mixed with other indexing styles, yet.

### Assignment

Most index types can be used for assignment as LHS
```julia
n[1, 1] = 0
n["one", :b] = 1
n[:, :c] = 101:102
n[:B=>:b, :A=>"two"] = 50
println(n) # ==>
2×3 Named Array{Int64,2}
A ╲ B │  :a   :b   :c
──────┼──────────────
one   │   0    1  101
two   │   4   50  102
```

General functions
--

 * Names, dimnames

```julia
allnames(a::NamedArray)
names(a::NamedArray, dim)
dimnames(a::NamedArray)
```

 return the names of the indices along dimension `dim` and the names of the dimensions themselves.

 ```julia
 setnames!(a::NamedArray, names::Vector, dim::Int)
 setnames!(a::NamedArray, name, dim::Int, index:Int)
 setdimnames!(a::NamedArray, name, dim:Int)
 ```

sets all the names of dimension `dim`, or only the name at index `index`, or the name of the dimension `dim`.

 * Copy

```julia
copy(a::NamedArray)
```

returns a copy of all the elements in a, and returns a NamedArray

 * Convert

```julia
convert(::Type{Array}, a::NamedArray)
```

 converts a NamedArray to an Array by dropping all name information

 * Arithmetic:
  - between NamedArray and NamedArray
  - between NamedArray and Array
  - between NamedArray and Number
    - `+`, `-`, `.+`, `.-`, `.*`, `./`
  - between NamedArray and Number
    - `*`, `/`, `\`
  - Matrix Multiplication `*` between NamedArray and NamedArray

 * `print`, `show`:
  - basic printing, limited support for pretty-printing.

 * `size`, `ndims`, `eltype`

 * Similar

```julia
similar(a::NamedArray, t::DataType, dims::NTuple)
```

Methods with special treatment of names / dimnames
--------------------------------------------------

 * Concatenation

```julia
hcat(V::NamedVector...)
```

 concatenates (column) vectors to an array.  If the names are identical
for all vectors, these are retained in the results.  Otherwise
the names are reinitialized to the default "1", "2", ...

 * Transposition

```julia
' ## transpose post-fix operator '
ctranspose
transpose
permutedims
circshift
```

 operate on the dimnames as well

 * Reordering of dimensions in NamedVectors

```julia
nthperm
nthperm!
permute!
shuffle
shuffle!
reverse
reverse!
```

 operate on the names of the rows as well


 * Broadcasts

```julia
broadcast
broadcast!
```

 these functions check consistency of the names of dimensions `d` with `length(d)>1`, and performs the normal `broadcast`

 * Aggregates

```julia
sum
prod
maximum
minimum
mean
std
```

 These functions, when operating along one dimension, keep the names in the orther dimensions, and name the left over singleton dimension as `$function($dimname)`.


Implementation
------------

Currently, the type is defined as

```julia
type NamedArray{T,N,AT,DT} <: AbstractArray{T,N}
    array::AT
    dicts::DT
    dimnames::NTuple{N, Any}
end
```

but the inner constructor actually expects `NTuple`s for `dicts` and `dimnames`, which more easily allows somewhat stricter typechecking.   This is sometimes a bit annoying, if you want to initialize a new NamedArray from known `dicts` and `dimnames`.  You can use the expression `tuple(Vector...)` for that.
