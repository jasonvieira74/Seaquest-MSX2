set pause false
set log [open "C:/Users/jason/OneDrive/Documents/GitHub/seaquest-msx2/versions/v40-final/build/v40-psg-fallback-test.log" w]
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

proc inspect_fallback {} {
    global log failures
    set pause true
    expect_value "init-marker" [debug read memory 0xC0C8] 12
    expect_value "title-active" [debug read memory 0xC15F] 1
    expect_value "no-internal-msx-music" [debug read memory 0xC167] 0
    expect_value "psg-melody-advancing" [expr {[debug read memory 0xC16C] != 0}] 1
    puts $log "RESULT failures=$failures"
    close $log
    exit
}

after realtime 18 inspect_fallback
