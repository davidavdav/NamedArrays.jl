using NamedArrays

function compute_betas{T <: AbstractFloat}(factors::AbstractArray{T,2}, returns::AbstractArray{T,2})
    # make sure the dimension labels match
    if typeof(factors) <: NamedArrays.NamedArray && typeof(returns) <: NamedArrays.NamedArray
        @assert NamedArrays.names(factors,1) == NamedArrays.names(returns,1)
        @assert factors.dimnames[1] == returns.dimnames[1]
    end

    println("DEBUG: factors $factors")
    println("DEBUG: returns $returns")
    ff = factors' * factors
    fr = factors' * returns
    println("DEBUG: ff $ff")
    println("DEBUG: fr $fr")
    # return ff \ fr
    #TODO revert me after fixed!
    result = ff \ fr
    println("DEBUG: result $result")
    return result
end

nTimes = 1000
nSecurities = 100
nFactors = 5

r = rand(nTimes,nSecurities)
returns = NamedArray(r, (map(x->"Time$x",1:nTimes), map(x->"Sec$x",1:nSecurities)), ("Time","Security"))

f = rand(nTimes,nFactors)
factors = NamedArray(f, (names(returns,1), map(x->"Factor$x",1:nFactors)), (returns.dimnames[1],"Factor") )

betas = compute_betas(factors,returns)

# The labels get messed up during the calculations.  The labels should be:
# dim1: Factor -> Factor1, Factor2, ... Factor5
# dim2: Security -> Sec1, Sec2, ... Sec100
println("DEBUG: betas $betas")
