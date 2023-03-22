## show.jl
## (c) 2013--2014 David A. van Leeuwen

## various tests for show()

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution
println("show,")

include("init-namedarrays.jl")

function showlines(x, args::Pair...)
    buf = IOBuffer()
    show(IOContext(buf, args...), x)
    return split(String(take!(copy(buf))), "\n")
end

function showlines(mime, x, args::Pair...)
    buf = IOBuffer()
    show(IOContext(buf, args...), mime, x)
    return split(String(take!(copy(buf))), "\n")
end

lines = showlines("text/plain", NamedArray(Array{Int}(undef)))
@test length(lines) == 2
if VERSION >= v"1.6.0"
    @test lines[1] == "0-dimensional Named Array{Int64, 0}"
else
    @test lines[1] == "0-dimensional Named Array{Int64,0}"
end

lines = showlines("text/plain", NamedArray([]))
@test length(lines) == 3
if VERSION >= v"1.6.0"
    @test lines[1] == "0-element Named Vector{Any}"
else
    @test lines[1] == "0-element Named Array{Any,1}"
end
@test split(lines[2]) == ["A", "│"]

for k in 0:5, (m,n) in ((k,0), (0,k))
    local lines = showlines("text/plain", NamedArray(Matrix{Int}(undef, m, n)))
    @test length(lines) == 3 + m
    if VERSION >= v"1.6.0"
        @test lines[1] == "$m×$n Named Matrix{Int64}"
    else
        @test lines[1] == "$m×$n Named Array{Int64,2}"
    end
    @test split(lines[2]) == [["A", "╲", "B", "│"]; string.(1:n)]
    for i in 1:m
        @test split(lines[3+i])[1] == string(i)
    end
end

_lines = showlines(MIME"text/plain"(), n)
@test length(_lines) == 5
if VERSION >= v"1.6.0"
    @test _lines[1] == "2×4 Named Matrix{Float64}"
else
    @test _lines[1] == "2×4 Named Array{Float64,2}"
end
@test split(_lines[2]) == vcat(["A", "╲", "B", "│"], letters[1:4])

## wide array abbreviated
lines = showlines("text/plain", NamedArray(randn(2,1000)), :limit => true)
@test length(lines) == 5
if VERSION >= v"1.6.0"
    @test lines[1] == "2×1000 Named Matrix{Float64}"
else
    @test lines[1] == "2×1000 Named Array{Float64,2}"
end
header = split(lines[2])
@test header[vcat(1:5, end)] == ["A", "╲", "B", "│", "1", "1000"]
@test "…" in header
for (_i, _line) in enumerate(lines[end-1:end])
    @test split(_line)[1] == string(_i)
end

## tall array abbreviated
lines = showlines("text/plain", NamedArray(randn(1000,2)), :limit => true)
@test length(lines) > 7
if VERSION >= v"1.6.0"
    @test lines[1] == "1000×2 Named Matrix{Float64}"
else
    @test lines[1] == "1000×2 Named Array{Float64,2}"
end
@test split(lines[2]) == ["A", "╲", "B", "│", "1", "2"]
@test split(lines[4])[1] == "1"
@test split(lines[end])[1] == "1000"

## tall vector abbreviated
lines = showlines("text/plain", NamedArray(randn(1000)), :limit => true)
@test length(lines) > 7
if VERSION >= v"1.6.0"
    @test lines[1] == "1000-element Named Vector{Float64}"
else
    @test lines[1] == "1000-element Named Array{Float64,1}"
end
@test split(lines[2]) == ["A", "│"]
@test split(lines[4])[1] == "1"
@test split(lines[end])[1] == "1000"

## non-standard integer indexing
zo = [0,1]
lines = showlines("text/plain", NamedArray(rand(2,2,2), (zo, zo, zo), ("base", "zero", "indexing")))
@test length(lines) == 13
if VERSION >= v"1.6.0"
    @test lines[1] == "2×2×2 Named Array{Float64, 3}"
else
    @test lines[1] == "2×2×2 Named Array{Float64,3}"
end

for (index, offset) in ([0, 3], [1, 9])
    @test lines[offset] == "[:, :, indexing=$index] ="
    @test split(lines[offset+1]) == ["base", "╲", "zero", "│", "0", "1"]
    @test split(lines[offset+3])[1] == "0"
    @test split(lines[offset+4])[1] == "1"
end

for ndim in 1:5
    global lines = showlines("text/plain", NamedArray(rand(fill(2,ndim)...)))
    if VERSION >= v"1.6.0"
        if (ndim == 1)
            line1 = "2-element Named Vector{Float64}"
        elseif (ndim == 2)
            line1 = "2×2 Named Matrix{Float64}"
        else
            line1 = join(repeat(["2"], ndim), "×") * " Named Array{Float64, $ndim}"
        end
    else
        if (ndim == 1)
            line1 = "2-element Named Array{Float64,1}"
        else
            line1 = join(repeat(["2"], ndim), "×") * " Named Array{Float64,$ndim}"
        end
    end
    @test lines[1] == line1
    if ndim ≥ 3
        @test startswith(lines[3], "[:, :, C=1")
        @test split(lines[4]) == ["A", "╲", "B", "│", "1", "2"]
    end
end
## various singletons
println(NamedArray(rand(1,2,2)))
println(NamedArray(rand(2,1,2)))
println(NamedArray(rand(2,2,1)))

## sparse array
nms = [string(hash(i)) for i in 1:1000]
lines = showlines("text/plain", NamedArray(sprand(1000,1000, 1e-4), (nms, nms)), :limit => true)
@test length(lines) > 7
@test startswith(lines[1], "1000×1000 Named sparse matrix with")
@test endswith(lines[1], "Float64 nonzero entries:")
@test sum([occursin("⋮", _line) for _line in lines]) == 1

# DEPRECATED: ## array with Nullable names
# DEPRECATED: lines = showlines(NamedArray(rand(2, 2), (Nullable["a", Nullable()], Nullable["c", "d"])))
# DEPRECATED: @test lines[1] == "2×2 Named Array{Float64,2}"
# DEPRECATED: @test split(lines[2]) == ["A", "╲", "B", "│", "\"c\"", "\"d\""]
# DEPRECATED: @test startswith(lines[4], "\"a\"")
# DEPRECATED: @test startswith(lines[5], "#NULL")

## no limits
for dims in [(1000,), (1000, 2)]
    global lines = showlines("text/plain", NamedArray(rand(dims...)), :limit => false)
    @test length(lines) == 1003
    @test startswith(lines[end-500], "500 ")
end
lines = showlines("text/plain", NamedArray(rand(10, 1000)), :limit => false)
@test length(split(lines[2])) == 1004 ##  "A"    "╲"    "B"    "│" ...
@test length(split(lines[end])) == 1002 # "10"   "│" ...

@test sprint(show, "text/plain", NamedArray([1 2; 3 4], (String1["A", "B"], ["C", "D"]), (String7("First"), String7("Second")))) =="""
2×2 Named Matrix{Int64}
First ╲ Second │ C  D
───────────────┼─────
A              │ 1  2
B              │ 3  4"""
