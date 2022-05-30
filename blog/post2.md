+++
title = "Tmp"
author = "Justin"
+++

## Test MLB torch 

```julia
"""
    Perceptron()
"""
mutable struct Perceptron
    weight
    bias
    σ
    function Perceptron(X)
        weight = reshape((randn(size(X)) / 100), 1, :)
        bias = 0.
        σ(net_input) = net_input[1] >= 0 ? 1 : 0
        new(weight, bias, σ)
    end
end

(ppn::Perceptron)(X) = ppn.σ(ppn.weight * reshape(X, :, 1).+ ppn.bias)
```
