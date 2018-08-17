using NamedArrays, BenchmarkTools, Test

function f1()
    x = Vector{Int}(10^6)
    y = NamedArray(x)
    for i in 1:10^6, j in 1:10
        x[i] = i
    end
end

function f2()
    x = Vector{Int}(10^6)
    y = NamedArray(x)
    for i in 1:10^6, j in 1:10
        y[i] = i
    end
end

function f3()
    x = Vector{Int}(10^6)
    y = NamedArray(x, (NamedArrays.defaultnamesdict(length(x)),), (:A,))
    for i in 1:10^6, j in 1:10
        y[i] = i
    end
end

println("@benchmark f1()")
