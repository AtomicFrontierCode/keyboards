# ### SETUP ###
# ~~~ libraries ~~~
import Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()
using Plots
using Random
using Base.Threads
using BenchmarkTools
using Statistics


# ~~~ data ~~~
bookPath = "myBook.txt"

# ~~~ weights ~~~
distanceEffort = 1 # at 2 distance penalty is squared
doubleFingerEffort = 1
doubleHandEffort = 1 

fingerCPM = [223, 169, 225, 273, 343, 313, 259, 241] # how many clicks can you do in a minute
meanCPM = mean(fingerCPM)
stdCPM = std(fingerCPM)
zScoreCPM = -(fingerCPM .- meanCPM) ./ stdCPM # negative since higher is better
fingerEffort = zScoreCPM .- minimum(zScoreCPM)


rowCPM = [131, 166, 276, 192]
meanCPM = mean(rowCPM)
stdCPM = std(rowCPM)
zScoreCPM = -(rowCPM .- meanCPM) ./ stdCPM # negative since higher is better
rowEffort = zScoreCPM .- minimum(zScoreCPM)

effortWeighting = [0.7917, 1, 0, 0.4773, 0.00] # dist, finger, row. Also had room for other weightings but removed for simplicity

# ~~~ keyboard ~~~
# smart modified traditional (x, y, row, finger, home)
smartTraditionalLayoutMap = Dict(
    5=>  [0.5, 4.5, 1, 1, 0],
    6 =>  [1.5, 4.5, 1, 1, 0],
    9 =>  [2.5, 4.5, 1, 1, 0],
    10 =>  [3.5, 4.5, 1, 2, 0],
    19 =>  [4.5, 4.5, 1, 3, 0],
    20 =>  [5.5, 4.5, 1, 4, 0],
    7 =>  [6.5, 4.5, 1, 4, 0],
    8=>  [7.5, 4.5, 1, 5, 0],
    22 =>  [8.5, 4.5, 1, 6, 0],
    21 => [9.5, 4.5, 1, 7, 0],
    11 => [10.5, 4.5, 1, 8, 0],
    2 => [11.5, 4.5, 1, 8, 0],
    1 => [12.5, 4.5, 1, 8, 0],

    12 =>  [2, 3.5, 2, 1, 0],
    26 =>  [3, 3.5, 2, 2, 0],
    32 =>  [4, 3.5, 2, 3, 0],
    38 =>  [5, 3.5, 2, 4, 0],
    39 =>  [6, 3.5, 2, 4, 0],
    24 =>  [7, 3.5, 2, 5, 0],
    25 =>  [8, 3.5, 2, 5, 0],
    41 =>  [9, 3.5, 2, 6, 0],
    40 =>  [10, 3.5, 2, 7, 0],
    33 =>  [11, 3.5, 2, 8, 0],
    27 =>  [12, 3.5, 2, 8, 0],
    4 =>  [13, 3.5, 2, 8, 0],
    3 =>  [14, 3.5, 2, 8, 0],

    36 =>  [2.25, 2.5, 3, 1, 1],
    42 =>  [3.25, 2.5, 3, 2, 1],
    44 =>  [4.25, 2.5, 3, 3, 1],
    45 =>  [5.25, 2.5, 3, 4, 1],
    34 =>  [6.25, 2.5, 3, 4, 0],
    35 =>  [7.25, 2.5, 3, 5, 0],
    47 =>  [8.25, 2.5, 3, 5, 1],
    46 =>  [9.25, 2.5, 3, 6, 1],
    43 =>  [10.25, 2.5, 3, 7, 1],
    37 =>  [11.25, 2.5, 3, 8, 1],
    23 =>  [12.25, 2.5, 3, 8, 0],

    15 =>  [2.75, 1.5, 4, 1, 0],
    17 =>  [3.75, 1.5, 4, 2, 0],
    28 =>  [4.75, 1.5, 4, 3, 0],
    29 =>  [5.75, 1.5, 4, 4, 0],
    13 =>  [6.75, 1.5, 4, 4, 0],
    14 =>  [7.75, 1.5, 4, 5, 0],
    31 =>  [8.75, 1.5, 4, 5, 0],
    30 =>  [9.75, 1.5, 4, 6, 0],
    18 =>  [10.75, 1.5, 4, 7, 0],
    16 =>  [11.75, 1.5, 4, 8, 0],
)

# linear (x, y, row, finger)
linearLayoutMap = Dict(
    1 =>  [0.5, 4.5, 1, 1, 0],
    2 =>  [1.5, 4.5, 1, 1, 0],
    3 =>  [2.5, 4.5, 1, 1, 0],
    4 =>  [3.5, 4.5, 1, 2, 0],
    5 =>  [4.5, 4.5, 1, 3, 0],
    6 =>  [5.5, 4.5, 1, 4, 0],
    7 =>  [6.5, 4.5, 1, 4, 0],
    8 =>  [7.5, 4.5, 1, 5, 0],
    9 =>  [8.5, 4.5, 1, 5, 0],
    10 => [9.5, 4.5, 1, 6, 0],
    11 => [10.5, 4.5, 1, 7, 0],
    12 => [11.5, 4.5, 1, 8, 0],
    13 => [12.5, 4.5, 1, 8, 0],

    14 =>  [2.5, 3.5, 2, 1, 0],
    15 =>  [3.5, 3.5, 2, 2, 0],
    16 =>  [4.5, 3.5, 2, 3, 0],
    17 =>  [5.5, 3.5, 2, 4, 0],
    18 =>  [6.5, 3.5, 2, 4, 0],
    19 =>  [7.5, 3.5, 2, 5, 0],
    20 =>  [8.5, 3.5, 2, 5, 0],
    21 =>  [9.5, 3.5, 2, 6, 0],
    22 =>  [10.5, 3.5, 2, 7, 0],
    23 =>  [11.5, 3.5, 2, 8, 0],
    24 =>  [12.5, 3.5, 2, 8, 0],
    25 =>  [13.5, 3.5, 2, 8, 0],

    26 =>  [2.5, 2.5, 3, 1, 1],
    27 =>  [3.5, 2.5, 3, 2, 1],
    28 =>  [4.5, 2.5, 3, 3, 1],
    29 =>  [5.5, 2.5, 3, 4, 1],
    30 =>  [6.5, 2.5, 3, 4, 0],
    31 =>  [7.5, 2.5, 3, 5, 0],
    32 =>  [8.5, 2.5, 3, 5, 1],
    33 =>  [9.5, 2.5, 3, 6, 1],
    34 =>  [10.5, 2.5, 3, 7, 1],
    35 =>  [11.5, 2.5, 3, 8, 1],
    36 =>  [12.5, 2.5, 3, 8, 0],

    37 =>  [2.5, 1.5, 4, 1, 0],
    38 =>  [3.5, 1.5, 4, 2, 0],
    39 =>  [4.5, 1.5, 4, 3, 0],
    40 =>  [5.5, 1.5, 4, 4, 0],
    41 =>  [6.5, 1.5, 4, 4, 0],
    42 =>  [7.5, 1.5, 4, 5, 0],
    43 =>  [8.5, 1.5, 4, 5, 0],
    44 =>  [9.5, 1.5, 4, 6, 0],
    45 =>  [10.5, 1.5, 4, 7, 0],
    46 =>  [11.5, 1.5, 4, 8, 0],
) 

# traditional (x, y, row, finger, home)
traditionalLayoutMap = Dict(
    1 =>  [0.5, 4.5, 1, 1, 0],
    2 =>  [1.5, 4.5, 1, 1, 0],
    3 =>  [2.5, 4.5, 1, 1, 0],
    4 =>  [3.5, 4.5, 1, 2, 0],
    5 =>  [4.5, 4.5, 1, 3, 0],
    6 =>  [5.5, 4.5, 1, 4, 0],
    7 =>  [6.5, 4.5, 1, 4, 0],
    8 =>  [7.5, 4.5, 1, 5, 0],
    9 =>  [8.5, 4.5, 1, 6, 0],
    10 => [9.5, 4.5, 1, 7, 0],
    11 => [10.5, 4.5, 1, 8, 0],
    12 => [11.5, 4.5, 1, 8, 0],
    13 => [12.5, 4.5, 1, 8, 0],

    14 =>  [2, 3.5, 2, 1, 0],
    15 =>  [3, 3.5, 2, 2, 0],
    16 =>  [4, 3.5, 2, 3, 0],
    17 =>  [5, 3.5, 2, 4, 0],
    18 =>  [6, 3.5, 2, 4, 0],
    19 =>  [7, 3.5, 2, 5, 0],
    20 =>  [8, 3.5, 2, 5, 0],
    21 =>  [9, 3.5, 2, 6, 0],
    22 =>  [10, 3.5, 2, 7, 0],
    23 =>  [11, 3.5, 2, 8, 0],
    24 =>  [12, 3.5, 2, 8, 0],
    25 =>  [13, 3.5, 2, 8, 0],

    26 =>  [2.25, 2.5, 3, 1, 1],
    27 =>  [3.25, 2.5, 3, 2, 1],
    28 =>  [4.25, 2.5, 3, 3, 1],
    29 =>  [5.25, 2.5, 3, 4, 1],
    30 =>  [6.25, 2.5, 3, 4, 0],
    31 =>  [7.25, 2.5, 3, 5, 0],
    32 =>  [8.25, 2.5, 3, 5, 1],
    33 =>  [9.25, 2.5, 3, 6, 1],
    34 =>  [10.25, 2.5, 3, 7, 1],
    35 =>  [11.25, 2.5, 3, 8, 1],
    36 =>  [12.25, 2.5, 3, 8, 0],

    37 =>  [2.75, 1.5, 4, 1, 0],
    38 =>  [3.75, 1.5, 4, 2, 0],
    39 =>  [4.75, 1.5, 4, 3, 0],
    40 =>  [5.75, 1.5, 4, 4, 0],
    41 =>  [6.75, 1.5, 4, 4, 0],
    42 =>  [7.75, 1.5, 4, 5, 0],
    43 =>  [8.75, 1.5, 4, 5, 0],
    44 =>  [9.75, 1.5, 4, 6, 0],
    45 =>  [10.75, 1.5, 4, 7, 0],
    46 =>  [11.75, 1.5, 4, 8, 0],
)


currentLayoutMap = traditionalLayoutMap

# comparisons 
QWERTYgenome = [
    "~",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "0",
    "-",
    "+",
    "Q",
    "W",
    "E",
    "R",
    "T",
    "Y",
    "U",
    "I",
    "O",
    "P",
    "[",
    "]",
    "A",
    "S",
    "D",
    "F",
    "G",
    "H",
    "J",
    "K",
    "L",
    ";",
    "'",
    "Z",  
    "X",  
    "C",  
    "V",  
    "B",  
    "N",  
    "M",  
    "<",
    ">",
    "?"
]

ABCgenome = [
    "~",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "0",
    "-",
    "+",
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "[",
    "]",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    ";",
    "'",
    "T",
    "U",
    "V",
    "W",
    "X",
    "Y",
    "Z",
    "<",
    ">",
    "?"
]

DVORAKgenome = [
    "~",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "0",
    "[",
    "]",
    "'",
    "<",
    ">",
    "P",
    "Y",
    "F",
    "G",
    "C",
    "R",
    "L",
    "?",
    "+",
    "A",
    "O",
    "E",
    "U",
    "I",
    "D",
    "H",
    "T",
    "N",
    "S",
    "-",
    ";",
    "Q",
    "J",
    "K",
    "X",
    "B",
    "M",
    "W",
    "V",
    "Z"
]

baselineLayout = QWERTYgenome

# alphabet
letterList = [
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W",
    "X",
    "Y",
    "Z",
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "~",
    "-",
    "+",
    "[",
    "]",
    ";",
    "'",
    "<",
    ">",
    "?"
]

# map dictionary
keyMapDict = Dict(
    'a' => [1,0], 'A' => [1,1],
    'b' => [2,0], 'B' => [2,1],
    'c' => [3,0], 'C' => [3,1],
    'd' => [4,0], 'D' => [4,1],
    'e' => [5,0], 'E' => [5,1],
    'f' => [6,0], 'F' => [6,1],
    'g' => [7,0], 'G' => [7,1],
    'h' => [8,0], 'H' => [8,1],
    'i' => [9,0], 'I' => [9,1],
    'j' => [10,0], 'J' => [10,1],
    'k' => [11,0], 'K' => [11,1],
    'l' => [12,0], 'L' => [12,1],
    'm' => [13,0], 'M' => [13,1],
    'n' => [14,0], 'N' => [14,1],
    'o' => [15,0], 'O' => [15,1],
    'p' => [16,0], 'P' => [16,1],
    'q' => [17,0], 'Q' => [17,1],
    'r' => [18,0], 'R' => [18,1],
    's' => [19,0], 'S' => [19,1],
    't' => [20,0], 'T' => [20,1],
    'u' => [21,0], 'U' => [21,1],
    'v' => [22,0], 'V' => [22,1],
    'w' => [23,0], 'W' => [23,1],
    'x' => [24,0], 'X' => [24,1],
    'y' => [25,0], 'Y' => [25,1],
    'z' => [26,0], 'Z' => [26,1],
    '0' => [27,0], ')' => [27,1],
    '1' => [28,0], '!' => [28,1],
    '2' => [29,0], '@' => [29,1],
    '3' => [30,0], '#' => [30,1],
    '4' => [31,0], '$' => [31,1],
    '5' => [32,0], '%' => [32,1],
    '6' => [33,0], '^' => [33,1],
    '7' => [34,0], '&' => [34,1],
    '8' => [35,0], '*' => [35,1],
    '9' => [36,0], '(' => [36,1],
    '`' => [37,0], '~' => [37,1],
    '-' => [38,0], '_' => [38,1],
    '=' => [39,0], '+' => [39,1],
    '[' => [40,0], '{' => [40,1],
    ']' => [41,0], '}' => [41,1],
    ';' => [42,0], ':' => [42,1],
    ''' => [43,0], '"' => [43,1],
    ',' => [44,0], '<' => [44,1],
    '.' => [45,0], '>' => [45,1],
    '/' => [46,0], '?' => [46,1]
)

handList = [1, 1, 1, 1, 2, 2, 2, 2] # what finger is with which hand

# ### KEYBOARD FUNCTIONS ###
function createGenome()
    # setup
    myGenome = shuffle(letterList)

    # return
    return myGenome
end

function drawKeyboard(myGenome, id)
    plot()
    namedColours = ["yellow", "blue", "green", "orange", "pink", "green", "blue", "yellow"]

    for i in 1:46
        letter = myGenome[i]
        x, y, row, finger, home = currentLayoutMap[i]
        # myColour = namedColours[Int(finger)]

        myColour = "gray69"
        if letter in ["E"]
            myColour = "cyan" 
        elseif letter in ["T", "A", "O", "I", "N", "S", "R", "H", "L"]
            myColour = "springgreen2" 
        #elseif letter in ["D", "H", "L", "M", "U", "W", "Y"]
        #    myColour = "darkgreen" 
        elseif letter in ["[", "]", "~", "+", "7", "4", "6", "3", "8", "5"]
            myColour = "tomato"
        end

        if home == 1.0
            plot!([x], [y], shape=:rect, fillalpha=0.2, linecolor=nothing, color = myColour, label ="", markersize= 16.5 , dpi = 100)
        end
        
        plot!([x - 0.45, x + 0.45, x + 0.45, x - 0.45, x - 0.45], [y - 0.45, y - 0.45, y + 0.45, y + 0.45, y - 0.45], color = myColour, fillalpha = 0.2, label ="", dpi = 100)
        
        annotate!(x, y, text(letter, :black, :center, 10))
    end
    
    plot!(aspect_ratio = 1, legend = false)
    savefig("$id.png")

end

function countCharacters()
    char_count = Dict{Char, Int}()
    
    # Open the file for reading
    io = open(bookPath, "r")
    
    # Read each line from the file
    for line in eachline(io)
        for char in line
            char = uppercase(char)
            char_count[char] = get(char_count, char, 0) + 1
        end
    end
    
    # Close the file
    close(io)
    
    return char_count
end

# ### SAVE SCORE ###
function appendUpdates(updateLine)
    file = open("iterationScores.txt", "a")
    write(file, updateLine, "\n")
    close(file)
end

# ### OBJECTIVE FUNCTIONS ###
function determineKeypress(currentCharacter)
    # setup
    keyPress = "NONE"

    # proceed if valid key (e.g. we dont't care about spaces now)
    if haskey(keyMapDict, currentCharacter)
        keyPress, _ = keyMapDict[currentCharacter]
    end
   
    # return
    return keyPress
end

function doKeypress(myFingerList, myGenome, keyPress, oldFinger, oldHand)
    # setup
    # ~ get the key being pressed ~
    namedKey = letterList[keyPress]
    actualKey = findfirst(x -> x == namedKey, myGenome)

    # ~ get its location ~
    x, y, row, finger, home = currentLayoutMap[actualKey]
    currentHand = handList[Int(finger)]
    
    # loop through fingers
    for fingerID in 1:8
        # load
        homeX, homeY, currentX, currentY, distanceCounter, objectiveCounter = myFingerList[fingerID,:]

        if fingerID == finger # move finger to key and include penalty
            # ~ distance
            distance = sqrt((x - currentX)^2 + (y - currentY)^2)

            distancePenalty = distance^distanceEffort # i.e. squared
            newDistance = distanceCounter + distance

            # ~ double finger ~
            doubleFingerPenalty = 0
            if finger != oldFinger && oldFinger != 0 && distance != 0
                doubleFingerPenalty = doubleFingerEffort
            end
            oldFinger = finger


            # ~ double hand ~
            doubleHandPenalty = 0
            if currentHand != oldHand && oldHand != 0
                doubleHandPenalty = doubleHandEffort
            end
            oldHand = currentHand

            # ~ finger
            fingerPenalty = fingerEffort[fingerID]

            # ~ row
            rowPenalty = rowEffort[Int(row)]

            # ~ combined weighting
            penalty = sum([distancePenalty, doubleFingerPenalty, doubleHandPenalty, fingerPenalty, rowPenalty] .* effortWeighting)
            newObjective = objectiveCounter + penalty

            # ~ save
            myFingerList[fingerID, 3] = x
            myFingerList[fingerID, 4] = y
            myFingerList[fingerID, 5] = newDistance
            myFingerList[fingerID, 6] = newObjective
        else # re-home unused finger
            myFingerList[fingerID, 3] = homeX
            myFingerList[fingerID, 4] = homeY
        end
    end

    # return
    return myFingerList, oldFinger, oldHand
end

function objectiveFunction(myGenome)
    # setup
    objective = 0
   
    # ~ create hand ~
    myFingerList = zeros(8, 6) # (homeX, homeY, currentX, currentY, distanceCounter, objectiveCounter)

    for i in 1:46
        x, y, _, finger, home = currentLayoutMap[i]

        if home == 1.0
            myFingerList[Int(finger), 1:4] = [x, y, x, y]
        end
    end
    
    # load text
    file = open(bookPath, "r")
    oldFinger = 0
    oldHand = 0

    try
        while !eof(file)
            currentCharacter = read(file, Char)

            # determine keypress
            keyPress = determineKeypress(currentCharacter)

            # do keypress
            if keyPress != "NONE"
                myFingerList, oldFinger, oldHand = doKeypress(myFingerList, myGenome, keyPress, oldFinger, oldHand)
            end
        end
    finally
        close(file)
    end

    # calculate objective
    objective = sum(myFingerList[:, 6])
    objective = (objective / QWERTYscore - 1) * 100

    # return
    return objective
end

function baselineObjectiveFunction(myGenome) # same as previous but for getting QWERTY baseline
    # setup
    objective = 0
   
    # ~ create hand ~
    myFingerList = zeros(8, 6) # (homeX, homeY, currentX, currentY, distanceCounter, objectiveCounter)

    for i in 1:46
        x, y, _, finger, home = currentLayoutMap[i]

        if home == 1.0
            myFingerList[Int(finger), 1:4] = [x, y, x, y]
        end
    end
    
    # load text
    file = open(bookPath, "r")
    oldFinger = 0
    oldHand = 0

    try
        while !eof(file)
            currentCharacter = read(file, Char)

            # determine keypress
            keyPress = determineKeypress(currentCharacter)

            # do keypress
            if keyPress != "NONE"
                myFingerList, oldFinger, oldHand = doKeypress(myFingerList, myGenome, keyPress, oldFinger, oldHand)
            end
        end
    finally
        close(file)
    end

    # calculate objective
    objective = sum(myFingerList[:, 6])
    objective = objective

    # return
    return objective
end

# ### SA OPTIMISER ###
function shuffleGenome(currentGenome, temperature)
    # setup
    noSwitches = Int(maximum([2, minimum([floor(temperature/100), 46])]))

    # positions of switched letterList
    switchedPositions = randperm(46)[1:noSwitches]
    newPositions = shuffle(copy(switchedPositions))

    # create new genome by shuffeling
    newGenome = copy(currentGenome)
    for i in 1:noSwitches
        og = switchedPositions[i]
        ne = newPositions[i]

        newGenome[og] = currentGenome[ne]
    end

    # return
    return newGenome

end


function runSA()
    println("Running code...")
    # baseline
    print("Calculating raw baseline: ")
    global QWERTYscore = baselineObjectiveFunction(baselineLayout) # yes its a global, fight me
    println(QWERTYscore)

    println("From here everything is reletive with + % worse and - % better than this baseline \n Note that best layout is being saved as a png at each step. Kill program when satisfied.")

    println("Temperature \t Best Score \t New Score")


    # setup
    currentGenome = createGenome()
    currentObjective = objectiveFunction(currentGenome)

    bestGenome = currentGenome
    bestObjective = currentObjective

    temperature  = 500
    epoch = 20
    coolingRate = 0.99
    num_iterations = 25000

    drawKeyboard(bestGenome, 0)

    # run SA
    staticCount = 0.0
    for iteration in 1:num_iterations
        # ~ create new genome ~
        newGenome = shuffleGenome(currentGenome, 2)

        # ~ asess ~
        newObjective = objectiveFunction(newGenome)
        delta = newObjective - currentObjective

        println(round(temperature, digits = 2), "\t", round(bestObjective, digits=2), "\t", round(newObjective, digits=2))

        

        
        if delta < 0
            currentGenome = copy(newGenome)
            currentObjective = newObjective

            updateLine = string(round(temperature, digits = 2), ", ",  iteration, ", ", round(bestObjective, digits=5), ", ", round(newObjective, digits=5))
            appendUpdates(updateLine)

            if newObjective < bestObjective
                bestGenome = newGenome
                bestObjective = newObjective

                #staticCount = 0.0

                println("(new best, png being saved)")
                

                drawKeyboard(bestGenome, iteration)
            end
        elseif exp(-delta/temperature) > rand()
            #print(" *")
            currentGenome = newGenome
            currentObjective = newObjective
        end

        #print("\n")


        staticCount += 1.0

        if staticCount > epoch
            staticCount = 0.0
            temperature = temperature * coolingRate

            if rand() < 0.5
                currentGenome = bestGenome
                currentObjective = bestObjective
            end
        end
    end

    # save
    drawKeyboard(bestGenome, "final")

    # return
    return bestGenome

end


# ### RUN ###
runSA()
