set pause false
set log [open "C:/Users/jason/OneDrive/Documents/GitHub/seaquest-msx2/versions/v40-final/build/v40-title-return-test.log" w]
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

proc start_one_player {} {
    set pause true
    debug write "memory" 0xC165 12
    set pause false
    after realtime 4 force_game_over
}

proc force_game_over {} {
    set pause true
    expect_value "first-game-started" [debug read memory 0xC15F] 0
    expect_value "first-game-one-player" [debug read memory 0xC166] 1
    debug write "memory" 0xC13E 1
    keymatrixdown 8 1
    set pause false
    after realtime 0.15 { keymatrixup 8 1 }
    after realtime 1.0 inspect_returned_title
}

proc inspect_returned_title {} {
    global log failures
    set pause true
    expect_value "game-over-returns-title" [debug read memory 0xC15F] 1
    expect_value "returned-default-selection" [debug read memory 0xC160] 0
    expect_value "held-trigger-no-auto-start" [debug read memory 0xC165] 0
    set pause false
    keymatrixdown 8 64
    after realtime 0.15 { keymatrixup 8 64 }
    after realtime 0.60 inspect_two_player_choice
}

proc inspect_two_player_choice {} {
    global log failures
    set pause true
    expect_value "second-option-selected" [debug read memory 0xC160] 1
    expect_value "mode-changed-to-two" [debug read memory 0xC166] 2
    set pause false
    keymatrixdown 8 1
    after realtime 0.15 { keymatrixup 8 1 }
    after realtime 4 inspect_second_game
}

proc inspect_second_game {} {
    global log failures
    set pause true
    expect_value "second-game-started" [debug read memory 0xC15F] 0
    expect_value "second-game-two-player" [debug read memory 0xC166] 2
    expect_value "second-game-player-one-active" [debug read memory 0xC17A] 0
    expect_value "second-game-waiting-reserves" [debug read memory 0xC17E] 4
    puts $log "RESULT failures=$failures"
    close $log
    exit
}

after realtime 18 start_one_player
