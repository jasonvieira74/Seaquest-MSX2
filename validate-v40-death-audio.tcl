set pause false
set log [open "C:/Users/jason/OneDrive/Documents/GitHub/seaquest-msx2/versions/v40-final/build/v40-death-audio-test.log" w]
set failures 0

proc expect_value {label actual expected} {
    global log failures
    if {$actual == $expected} {
        puts $log "PASS $label=$actual"
    } else {
        puts $log "FAIL $label=$actual expected=$expected"
        incr failures
    }
}

proc start_game {} {
    set pause true
    debug write "memory" 0xC165 12
    set pause false
    after realtime 4 begin_death
}

proc begin_death {} {
    set pause true
    debug write "memory" 0xC13E 0
    debug write "memory" 0xC0C3 23
    set pause false
    after realtime 0.45 inspect_first_phase
}

proc inspect_first_phase {} {
    global log failures
    set pause true
    set timer [debug read memory 0xC0C3]
    puts $log "FIRST timer=$timer mixer=[debug read memory 0xC15A] volume=[debug read memory 0xC158]"
    expect_value "timer-still-running-after-27-frames" [expr {$timer >= 15}] 1
    expect_value "poly5-tone-plus-noise" [debug read memory 0xC15A] 54
    expect_value "first-phase-perceptual-volume" [debug read memory 0xC158] 12
    set pause false
    after realtime 0.35 inspect_second_phase
}

proc inspect_second_phase {} {
    global log failures
    set pause true
    set timer [debug read memory 0xC0C3]
    set period [expr {[debug read memory 0xC15B] + 256 * [debug read memory 0xC15C]}]
    puts $log "SECOND timer=$timer period=$period mixer=[debug read memory 0xC15A] volume=[debug read memory 0xC158]"
    expect_value "timer-entered-second-phase" [expr {$timer > 0 && $timer < 15}] 1
    expect_value "poly9-tone-plus-noise" [debug read memory 0xC15A] 54
    expect_value "poly9-divider-16-period" $period 61
    set volume_map {0 7 9 10 11 12 12 13 13 14 14 15 15 15 15}
    expect_value "second-volume-perceptual-map" [debug read memory 0xC158] [lindex $volume_map $timer]
    set pause false
    after realtime 1.20 inspect_completion
}

proc inspect_completion {} {
    global log failures
    set pause true
    expect_value "death-sequence-completed" [debug read memory 0xC0C3] 0
    puts $log "RESULT failures=$failures"
    close $log
    exit
}

after realtime 18 start_game
