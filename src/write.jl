using NamedArrays
#= import CSV.write =#

#= function CSV.write(file, na::NamedArray; kwargs...) =#

function write(file::String, na::NamedArray)
    table = convert(DataFrame,na)
		println(table)
    CSV.write(file, table)
end
