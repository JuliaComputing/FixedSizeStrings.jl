module SizedStrings

import Base:
    iterate, length, getindex, lastindex, sizeof,
    ncodeunits, codeunit, isvalid, read, write

using Base: @propagate_inbounds

export SizedString, @sized_str

include("sized.jl")
include("max-sized.jl")

end
