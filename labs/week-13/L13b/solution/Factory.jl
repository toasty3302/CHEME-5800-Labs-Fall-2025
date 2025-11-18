function build(modeltype::Type{MyExperimentalContext}, data::NamedTuple)::MyExperimentalContext
    
    # create new context instance -
    context = modeltype()

    # populate context fields from data -
    context.K = data.K
    context.m = data.m
    context.γ = data.γ
    context.μ = data.μ
    context.B = data.B
    context.cost = data.cost
    context.levels = data.levels

    return context
end