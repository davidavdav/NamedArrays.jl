## names.jl retrieve and set dimension names
## (c) 2013 David A. van Leeuwen

## This code is licensed under the GNU General Public License, version 2
## See the file LICENSE in this distribution## access to the names of the dimensions

names(dict::Dict) = collect(keys(dict))[sortperm(collect(values(dict)))] 
names(a::NamedArray) = map(dict -> names(dict), a.dicts)
names(a::NamedArray, d::Int) = names(a.dicts[d])
dimnames(a::NamedArray) = a.dimnames
dimnames(a::NamedArray, d::Int) = a.dimnames[d]

## seting names, dimnames
function setnames!(a::NamedArray, v::Vector, d::Int)
    @assert size(a.array,d) == length(v)
    a.dicts[d] = Dict(v, 1:length(v))
end

