using DataFrames
using CSV
import Base.write

function write(file, na::NamedArray; kwargs...)
    table = convert(DataFrame,na)
		println(table)
    CSV.write(file, table; kwargs...)
end
