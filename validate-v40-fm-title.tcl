set pause false
set log [open "C:/Users/jason/OneDrive/Documents/GitHub/seaquest-msx2/versions/v40-final/build/v40-fm-title-test.log" w]
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

proc inspect_fm {} {
    global log failures
    set pause true
    set ptr [expr {[debug read memory 0xC18A] + 256 * [debug read memory 0xC18B]}]
    set timer [debug read memory 0xC16D]
    expect_value "init-marker" [debug read memory 0xC0C8] 12
    expect_value "title-active" [debug read memory 0xC15F] 1
    expect_value "internal-msx-music" [debug read memory 0xC167] 1
    expect_value "fm-score-pointer-live" [expr {$ptr >= 0x4000 && $ptr < 0xC000}] 1
    expect_value "variable-duration-event-live" [expr {$timer > 0 && $timer <= 64}] 1
    expect_value "psg-step-unused-by-fm" [debug read memory 0xC16C] 0
    puts $log "FM ptr=$ptr timer=$timer"
    puts $log "RESULT failures=$failures"
    close $log
    exit
}

after realtime 18 inspect_fm
