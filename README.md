# keyboards
Supporting simulated annealing code for [video](https://youtu.be/188fipF-i5I)https://youtu.be/188fipF-i5I

Written in Julia... because it's fast, easy to read, and annoys my labmates.

To run, download both filtes to the same directory and execute the Julia code. It should start by benchmarking your training data (MyBook.txt) against QWERTY followed by building it's own optimal layout. Change the number of iterations and cooling rates as desired within the SA() function. The terminal will give some indication of current progres (also stored by a new text file will give a iteration-by-iteration record of progress), and .png files of the current best solution will be saved to your same directory.

To train on your own custom dataset either point the "MyBook.txt" somewhere else or just replace its contents.

Good luck!
