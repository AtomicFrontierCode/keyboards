# <img src="https://raw.githubusercontent.com/JuliaLang/julia/3e4b38684e38a015446253f5752ee9cf840f50cc/contrib/julia.svg" width="32" alt="julia.png"/> keyboards

Supporting simulated annealing code for the [Why I Made The World's Worst Keyboard](https://youtu.be/188fipF-i5I) YouTube video.

Written in Julia... because it's fast, easy to read, and annoys my labmates.

To run, clone this repository and start Julia with `julia --project=.` and run `include("keyboardSA.jl")`. It should start by
benchmarking your training data (myBook.txt) against QWERTY followed by building
it's own optimal layout. Change the number of iterations and cooling rates as
desired within the SA() function. The terminal will give some indication of
current progress (also stored by a new text file will give a
iteration-by-iteration record of progress), and .png files of the current best
solution will be saved to your same directory.

To train on your own custom dataset either point the "myBook.txt" somewhere else or just replace its contents.

Good luck!

## Prerequisites

Make sure you have installed all of the following prerequisites on your development machine:

- Git - [Download & Install Git](https://git-scm.com/downloads). OSX and Linux machines typically have this already installed.
- Julia - [Download & Install Julia](https://julialang.org/downloads/#upcoming_release), and install the Julia language(version 1.10.0-rc1). Make sure to check

## Optional

If you want to play with the script, it's recommended to use the
[Revise.jl](https://github.com/timholy/Revise.jl) package to minimize latency.
You can find install instructions [here](https://timholy.github.io/Revise.jl/stable/#Installation)

## Running Application

Assuming `julia` is in your path, run

```bash
git clone https://github.com/AtomicFrontierCode/keyboards.git
cd keyboards
julia -L 'keyboardSA.jl'
```
