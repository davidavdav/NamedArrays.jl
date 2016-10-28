## inspired by DataFrames
if VERSION < v"0.5.0-dev+2023"
    displaysize(io::IO) = Base.tty_size()
end

if !isdefined(Core, :String)
    String = ASCIIString
end
