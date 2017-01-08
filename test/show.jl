## show.jl
## (c) 2013--2014 David A. van Leeuwen

## various tests for show()

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution
println("show,")

include("init-namedarrays.jl")

if VERSION ≥ v"0.5"
    tostring(b::IOBuffer) = String(b)
    times = "×" ## \times
else
    tostring(b::IOBuffer) = UTF8String(b.data)
    times = "x" # ex
end

function showlines(x...)
    buf = IOBuffer()
    show(buf, x...)
    return split(tostring(buf), "\n")
end

lines = showlines(NamedArray(Array{Int}()))
@test length(lines) == 2
@test lines[1] == "0-dimensional Named Array{Int64,0}"

lines = showlines(NamedArray([]))
@test length(lines) == 2
@test lines[1] == "0-element Named Array{Any,1}"

for lines in Any[showlines(n), showlines(MIME"text/plain"(), n)]
    @test length(lines) == 5
    @test lines[1] == "2$(times)4 Named Array{Float64,2}"
    @test split(lines[2]) == vcat(["A", "╲", "B", "│"], letters[1:4])
end

## wide array abbreviated
lines = showlines(NamedArray(randn(2,1000)))
@test length(lines) == 5
@test lines[1] == "2$(times)1000 Named Array{Float64,2}"
header = split(lines[2])
@test header[vcat(1:5, end)] == ["A", "╲", "B", "│", "1", "1000"]
@test "…" in header
for (i, line) in enumerate(lines[end-1:end])
    @test split(line)[1] == string(i)
end

## tall array abbreviated
lines = showlines(NamedArray(randn(1000,2)))
@test length(lines) > 7
@test lines[1] == "1000$(times)2 Named Array{Float64,2}"
@test split(lines[2]) == ["A", "╲", "B", "│", "1", "2"]
@test split(lines[4])[1] == "1"
@test split(lines[end])[1] == "1000"

## tall vector abbreviated
lines = showlines(NamedArray(randn(1000)))
@test length(lines) > 7
@test lines[1] == "1000-element Named Array{Float64,1}"
@test split(lines[2]) == ["A", "│"]
@test split(lines[4])[1] == "1"
@test split(lines[end])[1] == "1000"

## non-standard integer indexing
zo = [0,1]
lines = showlines(NamedArray(rand(2,2,2), (zo, zo, zo), ("base", "zero", "indexing")))
@test length(lines) == 13
@test lines[1] == "2$(times)2$(times)2 Named Array{Float64,3}"

for (index, offset) in ([0, 3], [1, 9])
    @test lines[offset] == "[:, :, indexing=$index] ="
    @test split(lines[offset+1]) == ["base", "╲", "zero", "│", "0", "1"]
    @test split(lines[offset+3])[1] == "0"
    @test split(lines[offset+4])[1] == "1"
end

for ndim in 1:5
    lines = showlines(NamedArray(rand(fill(2,ndim)...)))
    if (ndim == 1)
        line1 = "2-element Named Array{Float64,1}"
    else
        line1 = join(repmat(["2"], ndim), times) * " Named Array{Float64,$ndim}"
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
lines = showlines(NamedArray(sprand(1000,1000, 1e-4), (nms, nms)))
@test length(lines) > 7
@test startswith(lines[1], "1000×1000 Named sparse matrix with")
@test endswith(lines[1], "Float64 nonzero entries:")
@test sum([contains(line, "⋮") for line in lines]) == 1

# array with Nullable names
lines = showlines(NamedArray(rand(2, 2), (Nullable["a", Nullable()], Nullable["c", "d"])))
@test lines[1] == "2$(times)2 Named Array{Float64,2}"
if VERSION >= v"0.5.0-"
    @test split(lines[2]) == ["A", "╲", "B", "│", "\"c\"", "\"d\""]
    @test startswith(lines[4], "\"a\"")
    @test startswith(lines[5], "#NULL")
else
    @test split(lines[2]) == ["A","╲","B","│","Nullable(\"c\")","Nullable(\"d\")"]
    @test startswith(lines[4], "Nullable(\"a\")")
    @test startswith(lines[5], "Nullable")
end
