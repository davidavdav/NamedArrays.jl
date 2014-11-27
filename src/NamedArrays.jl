## NamedArrays.jl
## (c) 2013 David A. van Leeuwen

## Julia type that implements a drop-in replacement of Array with named dimensions. 

## This code is licensed under the GNU General Public License, version 2
## See the file LICENSE in this distribution

module NamedArrays

using Compat

export NamedArray, NamedVector, Names

## type definition
include("namedarraytypes.jl")

export allnames, dimnames, setnames!, setdimnames!, array

include("compat.jl")
include("constructors.jl")
include("arithmetic.jl")
include("base.jl")
include("changingnames.jl")
include("index.jl")
include("keepnames.jl")
include("names.jl")
include("rearrange.jl")
include("show.jl")
include("convert.jl")

end
