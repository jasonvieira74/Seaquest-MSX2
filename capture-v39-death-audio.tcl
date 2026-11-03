set pause false

proc start_game {} {
    set pause true
    debug write "memory" 0xC165 12
    set pause false
    after realtime 4 capture_death
}

proc capture_death {} {
    set pause true
    debug write "memory" 0xC13E 0
    debug write "memory" 0xC0C3 23
    soundlog start "C:/Users/jason/OneDrive/Documents/GitHub/seaquest-msx2/versions/v40-final/build/v39-death-reference.wav"
    set pause false
    after realtime 2.0 finish_capture
}

proc finish_capture {} {
    soundlog stop
    exit
}

after realtime 18 start_game
