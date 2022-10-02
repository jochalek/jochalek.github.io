@def title = "Julia on Kaggle"
@def tags = ["Machine Learning", "Julia", "Kaggle"]
@def published = "2 October 2022"
@def rss_description = "Competing on Kaggle with Julia."

# Julia on Kaggle

\toc

# Background

Julia is not on Kaggle. 

There are [a few ways](https://www.kaggle.com/code/marketneutral/julia-live-on-kaggle) to get Julia into a Jupyter notebook on the cloud. The tricky part is using Julia for a Code Competition where submissions run without internet access. This problem is half solved by [private Kaggle Datasets](https://www.kaggle.com/docs/datasets#creating-a-dataset). But how to organize your code as a Kaggle Dataset?

At first I turned to [PackageCompiler.jl](https://julialang.github.io/PackageCompiler.jl/dev/apps.html) and conveniently packed my whole inference pipeline into a standalone App that I could execute in a Kaggle Notebook environment. An added bonus was the ability to precompile every function in the pipeline significantly speeding up submission. One downside was the App became bloated with Julia Artifacts from project dependencies even if the inference pipeline did not use them. It seemed possible to cut down on the App size by being more explicit about what PackageCompiler.jl needs, but not without significant effort on my part when I would rather be iterating over my Kaggle submission. Ultimately my App broke after I transitioned from the latest [FastAI.jl](https://github.com/FluxML/FastAI.jl) release to the &rsquo;master&rsquo; branch to access some of the upcoming features. I will likely try this again with my next Kaggle competition and a hopefully more stable pipeline.

As a last resort I turned to packaging my pipeline into a handful of tarballs to unpack in the Kaggle Notebook environment and hoped for the best.


# Step By Step


## Setup

I started by downloading the competition dataset using the Kaggle API, training a model, and developing an inference & submission pipeline locally on my desktop. My inference pipeline was organized as a Julia package, for example:
```julia
julia> using Pkg
julia> Pkg.generate("Inference")
```

I developed my &ldquo;Inference&rdquo; package so that it could be called from the command line to produce a submission in the correct format.
```
julia --project=Inference/ Inference/src/Inference.jl
```


## Docker

It works on my machine, but will it work on Kaggle? Pull the [Kaggle Docker Image](https://github.com/Kaggle/docker-python) and setup a test production environment. Use Docker volumes to mount sample test data for inference as well as your &ldquo;Inference&rdquo; package.
```
docker run --runtime nvidia \
    -v /home/user/CompetitionData:/kaggle/input/testdata \
    -v /home/user/dev/Inference:/kaggle/input/Inference \
    -it gcr.io/kaggle-gpu-images/python /bin/bash
```
Set up Julia inside the container.
```
# Download the official binary
wget -nv https://julialang-s3.julialang.org/bin/linux/x64/1.8/julia-1.8.2-linux-x86_64.tar.gz -O /tmp/julia.tar.gz

# Unpack it.
tar -x -f /tmp/julia.tar.gz -C /usr/local --strip-components 1
```
Instantiate the Inference package and then test it.
```
julia --project=/kaggle/input/Inference -e "using Pkg; Pkg.instantiate()"
julia --project=/kaggle/input/Inference /kaggle/input/Inference/src/Inference.jl
```
If the pipeline works, pack ~/.julia into a tarball and move it to one of the shared Docker volumes in order to upload it to Kaggle later.
```
cd /root
tar -czvf dotjulia.tar.gz .julia
mv dotjulia.tar.gz /kaggle/input/testdata/dotjulia.tar.gz
```
Exit the production environment.



## Kaggle Private Datasets

Prepare to upload the following:

1.  dotjulia.tar.gz
2.  Inference package
3.  Julia binary
4.  Your model

All except the model must be uploaded as tarballs without the .tar extension. Kaggle recognizes .tar extension and automatically unpacks them in the Dataset container as read only, meaning nothing is executable.
```
# The Inference package for submission
tar -czvf Inference.tar.gz Inference
mv Inference.tar.gz inferenceapp

# The Julia binary.
wget -nv https://julialang-s3.julialang.org/bin/linux/x64/1.8/julia-1.8.2-linux-x86_64.tar.gz -O julia.tar.gz
mv julia.tar.gz julia

# ~/.julia from the Docker container is packaged already
mv dotjulia.tar.gz dotjulia

# The saved model can be uploaded as .bson or .jld2 directly.
```
Now we can create [private Kaggle Datasets](https://www.kaggle.com/datasets) to upload the following. I'll name it 'packedjulia' (model.jld2 will go into a separate dataset container 'models').

1.  dotjulia
2.  inferenceapp
3.  julia
4.  model.jld2



## Run the Notebook

Create a new competition Notebook and add as inputs your private Dataset.
```
# Unpack the Julia binary
!tar -x -f /kaggle/input/packedjulia/julia -C /usr/local --strip-components 1

# Unpack the dot julia directory
!tar -x -f /kaggle/input/packedjulia/dotjulia -C /root

# Unpack the inference package pipeline
!tar -x -f /kaggle/input/packedjulia/inference -C /tmp

# Run the inference on the test data
!julia -t auto --project=/tmp/Inference /tmp/Inference/src/Inference.jl --model /kaggle/input/models/model.jld2
```
I run the Notebook with internet access first to see if it tries to download any Artifacts. If it does I add them as dependencies to my Inference.jl package and go back to the Docker step to repackage and reupload everything. If it works, turn off internet access and save the Notebook version. Then submit!



## Final thoughts

See my [submission](https://www.kaggle.com/code/justinochalek/baseline-fastai-julia) and [competition repo](https://github.com/jochalek/HuBMAP) to see how I did it. Generally I followed the above. This was my first Kaggle submission. Although it ended with me at the back of the pack I learned a lot and I cannot wait to start again.


## TLDR;

1.  Pack your source code into a tarball.
2.  Download the Julia binary tarball.
3.  Test it in a &ldquo;production&rdquo; environment with docker.
    
        docker run --runtime nvidia -it gcr.io/kaggle-gpu-images/python /bin/bash
4.  Pack the &ldquo;production&rdquo; environment &rsquo;~/.julia&rsquo; directory into another tarball.
5.  Rename your tarballs from &rsquo;filename.tar.gz&rsquo; to &rsquo;filename&rsquo; and upload them as a private Kaggle Dataset. If the tar file extension is not removed, Kaggle will automatically unpack them in Dataset containers that are not executable.
6.  Create a new Kaggle notebook with your private datasets and unpack the tarballs.
7.  Run your Julia source with Jupyter magic.
    
        !julia inference.jl


