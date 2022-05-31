@def title = "A Perceptron from scratch with Julia"
@def hascode = true
@def tags = ["Machine Learnin", "Julia"]
@def reeval = true

# A Perceptron from scratch with Julia

## Implementing a perceptron learning algorithm in Julia

```julia
"""
    Perceptron(X)

Create a perceptron classifier object which holds the parameters `weight`, `bias`, and activation `σ`.

The input `X` is the feature matrix `m x n` where features are listed in rows `m` and observations or samples are by column `n`.

# Parameters
- `weight`: Learnable weight
- `bias`: Learnable bias
- `σ`: the activation function
"""
mutable struct Perceptron
    weight
    bias
    σ
    function Perceptron(X)
        weight = reshape((randn(size(X)[1]) / 100), 1, :)
        bias = 0.
        σ(net_input) = net_input[1] >= 0 ? 1 : 0
        new(weight, bias, σ)
    end
end

# Overload call to make an instance of the Perceptron act like a function that predicts a class label.
(ppn::Perceptron)(X) = ppn.σ(ppn.weight * reshape(X, :, 1).+ ppn.bias)
```

This turns out looking almost exactly like Flux.jl's Dense() layer, with the major difference being the perceptron's activation function (and fewer type declarations). I fiddled with this for a while before figuring that out, but the up side is I feel pretty good about reading Julia package source code. That's a solid stepping stone since they say Julia source "is Julia all the way down", and many usable Julia packages have room to grow with regard to their documentation.

```julia
using MLDatasets
using DataFrames
```

This is snippet loads the classic Iris dataset and "one-hot encodes" the target. In this case I'm just going to train a perceptron to classify "setosa" vs "not setosa".

```julia
X, y = Iris(as_df=false)[:]

Y = zeros(length(y))
for obs in 1:length(y)
    if y[obs] == "Iris-setosa"
        Y[obs] = 1
    end
end

```

This snippet instantiates a Perceptron object and trains it for 10 iterations, updating all of the weights in the weight vector once for each sample. In future I'll reorganize this into a function.

```julia
ppn = Perceptron(X)
η= 0.1
n_iter = 10
local errors_ = []

for epoch in 1:n_iter
    errors = 0
    for i in 1:150
        update = η * (Y[i] - ppn(X[:, i]))
        ppn.weight += update * reshape(X[:, i], 1, :)
        ppn.bias += update
        errors += Int(update != 0.0)
    end
    errors_ = [errors_; errors]
end


```

Plot the errors collected in each epoch. The perceptron converges after 4 epochs. Pretty cool.

```julia
using Plots
plot(errors_, xlabel = "Epochs", ylabel = "Number of updates", shape = :circle, legend = false)
```

\fig{ppn}

## Machine Learning with Julia

I first picked up [Dr. Sebastian Raschka](https://sebastianraschka.com/)'s excellent book, [Python Machine Learning](https://www.packtpub.com/product/python-machine-learning-third-edition/9781789955750), after finishing Dr. Andrew Ng's introduction to Machine Learning Coursera course in 2020. The book was naturally the next step to learn more about my new interest. It has the perfect mix of mathematics and python for a beginner in both fields. I bought the second edition of the book, which was based on Tensorflow 1, and read through much of it while still trying to learn python on the side as a first programming language. I even submitted a Kaggle notebook applying a random forest model to the classic UCI Cleveland Heart Disease dataset before medical school took my attention away from machine learning.

I'm not satisfied with what I've learned so far. In medical school we try to learn a lot of stuff, and we try a lot of things to "make it stick". To learn it once and for all. In reality, what sticks are the things we revisit over and over in the clinic. Nevertheless, I will attempt here to make all the machine learning knowledge I've learned "stick" by working through Dr. Sebastian Raschka's newest ML book, [Machine Learning with PyTorch and Scikit-Learn](https://www.packtpub.com/product/machine-learning-with-pytorch-and-scikit-learn/9781801819312), but instead of rewriting the book's example code in a jupyter notebook I am going to do it in Julia and learn two new things at the same time.

I highly recommend Machine Learning with PyTorch and Scikit-Learn. The example python for the book is hosted publicly on [github](https://github.com/rasbt/machine-learning-book).

