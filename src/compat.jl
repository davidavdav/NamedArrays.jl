## temporary compatibility hack
if VERSION < v"0.4.0-dev"
    Base.Dict(z::Base.Zip2) = Dict(z.a, z.b)
    typealias AbstractTriangular Triangular
else
    import Base.LinAlg.AbstractTriangular
end

## inspired by DataFrames
if VERSION < v"0.5.0-dev+2023"
    displaysize(io::IO) = Base.tty_size()
else
    using Combinatorics
end

if VERSION < v"0.5.0-dev"
    String = ASCIIString
end
