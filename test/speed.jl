## test.jl
## (c) 2013--2016 David A. van Leeuwen

## various tests for speed

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

## how are we doing for speed?
function sgetindex(x, r1=1:size(x,1), r2=1:size(x,2))
    a::Float64 = 0.
    for j=r2
        for i=r1
            a = x[i,j]
        end
    end
end

n = @inferred NamedArray(rand(1000,1000))
t1 = t2 = t3 = 0.0
for _ = 1:2
    global t1 = @elapsed sgetindex(n)
    global t2 = @elapsed sgetindex(n.array)
    si, sj = names(n)
    global t3 = @elapsed sgetindex(n, si, sj)
end
println("Timing named index: ", t1, ", array index: ", t2, ", named key: ", t3)

s = sparse(rand(1:1000, 10), rand(1:1000, 10), true)
n = @inferred NamedArray(s)
for _ = 1:2
    global t1 = @elapsed for _=1:10 sum(s, dims=1) end
    global t2 = @elapsed for _=1:10 sum(n, dims=1) end
end
println("Timing sum large sparse array: ", t1, ", named: ", t2)
