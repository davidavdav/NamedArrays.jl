using DataStructures

include("compat.jl")
if ! @isdefined NamedArray
    include("namedarraytypes.jl")
end

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
