## show.jl.  show and print methods for NamedArray
## (c) 2013-2016 David A. van Leeuwen

## Julia type that implements a drop-in replacement of Array with named dimensions.

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

## Displaying things in the REPL drives me crazy, there are all these things
## like print, show, display, writemime, etc., and I have no clue as to
## what gets called how in which circumstance.

import Base.print, Base.show, Base.summary, Base.display
import SparseArrays: nonzeros, getcolptr, rowvals, nnz

## fallback
function summary(n::NamedArray{T,N,AT}) where {T,N,AT}
    return Base.dims2string(size(n)) * string(" Named ", AT)
end

print(n::NamedArray) = print(n.array)

## This seems to be the essential function to overload for displaying in REPL:
Base.show(io::IO, ::MIME"text/plain", n::NamedArray) = show(io, n)

## ndims==1 is dispatched below
function show(io::IO, n::NamedArray)
    print(io, summary(n))
    s = size(n)
    limit = get(io, :limit, false)
    if ndims(n) == 0
        println(io)
        show(io, n.array[1])
    elseif ndims(n) == 2
        println(io)
        if limit
            maxnrow = displaysize(io)[1] - 7 # summary, header, dots, + 2 empty lines, + 2 Julia prompt...
            show(io, n, min(maxnrow, s[1]))
        else
            show(io, n, s[1])
        end
    else
        nlinesneeded = prod(s[3:end]) * (s[1] + 3) + 1
        if limit && nlinesneeded > displaysize(io)[1]
            maxnrow = clamp((displaysize(io)[1] - 3) ÷ (prod(s[3:end])) - 3, 3, s[1])
        else
            maxnrow = s[1]
        end
        maxrepeat = displaysize(io)[1] ÷ (maxnrow + 4)
        i = 1
        for idx in CartesianIndices(size(n)[3:end])
            if i > maxrepeat
                print(io, "\n⋮")
                break
            end
            cartnames = [string(strdimnames(n, 2+i), "=", strnames(n, 2+i)[ind]) for (i, ind) in enumerate(idx.I)]
            println(io, "\n")
            println(io, "[:, :, ", join(cartnames, ", "), "] =")
            show(io, n[:, :, idx], maxnrow)
            i += 1
        end
    end
end

#show(io::IO, x::NamedVector) = invoke(show, (IO, NamedArray), io, x)

function show(io::IO, v::NamedVector)
    println(io, summary(v))
    limit = get(io, :limit, false)
    if limit
        maxnrow = displaysize(io)[1] - 7
        show(io, v, min(maxnrow, length(v)))
    else
        show(io, v, length(v))
    end
end

## compute the ranges to be displayed, plus a total index comprising all ranges.
function compute_range(maxn, n)
    if maxn < n
        hn = div(maxn,2)
        r = (1:hn, n-hn+1:n)
    else
        r = (1:n,)
    end
    totr = vcat(map(collect, r)...)
    r, totr
end

leftalign(s, l) = rpad(s, l, " ")
rightalign(s, l) = lpad(s, l, " ")
sprint_colpart(width::Int, s::Vector) = join(map(s->lpad(s, width, " "), s), "  ")
function sprint_row(namewidth::Int, name, width::Int, names::Tuple; dots="…", sep=" │ ")
    s = string(leftalign(name, namewidth), sep, sprint_colpart(width, names[1]))
    if length(names)>1
        s = string(s, "  ", dots, "  ", sprint_colpart(width, names[2]))
    end
    s
end

## for 2D printing
function show(io::IO, n::NamedMatrix, maxnrow::Int)
    @assert ndims(n)==2
    nrow, ncol = size(n)
    limit = get(io, :limit, false)
    ## rows
    rowrange, totrowrange = compute_range(maxnrow, nrow)
    s = [sprint(show, n.array[i,j], context=:compact => true) for i=totrowrange, j=1:ncol]
    rowname, colname = strnames(n)
    strlen(x) = length(string(x))
    colwidth = max(maximum(map(length, s); init=0), maximum(map(strlen, colname); init=0))
    rownamewidth = max(maximum(map(strlen, rowname); init=0), sum(map(length, strdimnames(n)))+3)
    if limit
        maxncol = div(displaysize(io)[2] - rownamewidth - 4, colwidth+2) # dots, spaces between
    else
        maxncol = ncol
    end
    ## columns
    colrange, totcorange = compute_range(maxncol, ncol)
    ## header
    header = sprint_row(rownamewidth, rightalign(join(strdimnames(n), " ╲ "), rownamewidth),
                        colwidth, map(i->colname[i], colrange))
    println(io, header)
    print(io, "─"^(rownamewidth+1), "┼", "─"^(length(header)-rownamewidth-2))
    ## data
    l = 1
    for i in 1:length(rowrange)
        if i > 1
            vdots = map(i->["⋮" for i=1:length(i)], colrange)
            println(io)
            print(io, sprint_row(rownamewidth, "⋮", colwidth, vdots, dots="⋱", sep="   "))
        end
        r = rowrange[i]
        for j in 1:length(r)
            row = s[l,:]
            if (i == 1 && j == 1) || (i == length(rowrange) && j == length(r))
                dots = "…"
            else
                dots = " "
            end
            println(io)
            print(io, sprint_row(rownamewidth, rowname[totrowrange[l]], colwidth,
                                 map(r -> row[r], colrange), dots=dots))
            l += 1
        end
    end
end

## special case of sparse matrix, based on base/sparse/sparsematrix.c
function show(io::IO, n::NamedArray{T1,2,SparseMatrixCSC{T1,T2}}) where {T1,T2}
    S = n.array
    print(io, S.m, "×", S.n, " Named sparse matrix with ", nnz(S), " ", eltype(S), " nonzero entries", nnz(S) == 0 ? "" : ":")

    rownames, colnames = strnames(n)
    rowpad = maximum([length(s) for s in rownames])
    colpad = maximum([length(s) for s in colnames])
    sep = "\n\t"

    function format_line(r, col, rowpad, colpad)
        print(io, sep, '[', rpad(rownames[rowvals(S)[r]], rowpad), ", ", lpad(colnames[col], colpad), "]  =  ")
        if isassigned(nonzeros(S), r)
            Base.show(io, nonzeros(S)[r])
        else
            print(io, Base.undef_ref_str)
        end
    end

    function get_cols(from, to)
        idx = eltype(getcolptr(S))[]
        c = searchsortedlast(getcolptr(S), from)
        for i = from:to
            while i == getcolptr(S)[c+1]
                c +=1
            end
            push!(idx, c)
        end
        idx
    end

    maxnrows = displaysize(io)[1] - 4
    if !get(io, :limit, false) || maxnrows >= nnz(S)
        cols = get_cols(1, nnz(S))
        format_line.(1:nnz(S), cols, rowpad, colpad)
    else
        s1, e1 = 1, div(maxnrows - 1, 2) # -1 accounts for \vdots
        s2, e2 = nnz(S) - (maxnrows - 1 - e1) + 1, nnz(S)
        cols1 = get_cols(s1, e1)
        format_line.(s1:e1, cols1, rowpad, colpad)
        print(io, sep, lpad("⋮", rowpad + colpad + 7))
        cols2 = get_cols(s2, e2)
        format_line.(s2:e2, cols2, rowpad, colpad)
    end
    nothing
end

function show(io::IO, v::NamedVector, maxnrow::Int)
    nrow = size(v, 1)
    rownames = strnames(v,1)
    rowrange, totrowrange = compute_range(maxnrow, nrow)
    s = [sprint(show, v.array[i], context=:compact => true) for i=totrowrange]
    colwidth = maximum(map(length,s); init = 0)
    rownamewidth = max(maximum(map(length, rownames); init = 0), 1+length(strdimnames(v)[1]))
    ## header
    println(io, string(leftalign(strdimnames(v, 1), rownamewidth), " │ "))
    print(io, "─"^(rownamewidth+1), "┼", "─"^(colwidth+1))
    ## data
    l = 1
    for i in 1:length(rowrange)
        if i > 1
            vdots = ["⋮"]
            println(io)
            print(io, sprint_row(rownamewidth, "⋮", colwidth, (vdots,), sep="   "))
        end
        r = rowrange[i]
        for j in 1:length(r)
            row = s[l]
            println(io)
            print(io, sprint_row(rownamewidth, rownames[totrowrange[l]], colwidth, ([row],)))
            l += 1
        end
    end
end
