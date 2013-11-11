NamedArray
==========

Julia type that implements a drop-in replacement of Array with named dimensions. 

Idea
----

We would want to have the possibility to give each row/column/... in an Array names, as well as the array 
dimensions themselves.  This could be used for pretty-printing, indexing, and perhaps even some sort of 
dimension-checking in certain matrix computations. 

In all other respects, a NamedArray should be the same as an Array. 

Synopsis
--------

    reload("src/NamedArray.jl")
    n = NamedArray(rand(2,4))
    setnames!(n, ["one", "two"], 1) 
    n["one", 2:3]
    n["two", :] = 11:14
    n
    sum(n,1)
    
Implementation status
---------------------

Construction

    NamedArray(a::Array)
    NamedArray(::Type{T}, dims...)
these constructors add default names to the array of type String, "1", "2", ... for each dimension, and names the 
dimensions "A", "B", ... (which will be all right for 26 dimensions to start with; 26 dimensions should be enough 
for anyone:-).  


