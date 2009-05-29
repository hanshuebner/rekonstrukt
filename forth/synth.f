
hex
B060 constant frequency
B064 constant velocity
B065 constant attack
B066 constant decay
B067 constant sustain
B068 constant release
B069 constant waveform

hex
: plong ( -- )
    FFFF frequency !
    60 sustain c!
    2 attack c!
    2 release c!
    FF00 0 do
        i frequency 2 + !
        80 velocity c!
        40 ms
        0 velocity c!
        20 ms
    1000 +loop ;
    