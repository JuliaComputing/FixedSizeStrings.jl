module SizedStrings

import Base:
    iterate, length, getindex, lastindex, getindex, sizeof,
    ncodeunits, codeunit, isvalid, read, write

using Base: @propagate_inbounds

export SizedString

include("sized.jl")
include("max-sized.jl")

end
