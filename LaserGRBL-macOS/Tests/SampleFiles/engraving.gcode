; Complex engraving pattern test
; Star pattern with varying power levels

G21 ; millimeters
G90 ; absolute positioning
M5 ; laser off

; Move to center
G0 X25 Y25 F3000

; Turn on laser with low power
M3 S200

; Draw star pattern (5 points)
; Point 1
G1 X25 Y40 F1000
G0 X25 Y25

; Point 2
M3 S300
G1 X38 Y29 F1000
G0 X25 Y25

; Point 3
M3 S400
G1 X35 Y15 F1000
G0 X25 Y25

; Point 4
M3 S500
G1 X15 Y15 F1000
G0 X25 Y25

; Point 5
M3 S600
G1 X12 Y29 F1000
G0 X25 Y25

; Draw center circle
M3 S800
G2 X25 Y25 I3 J0 F500

; Turn off laser
M5

; Return to origin
G0 X0 Y0

; End program

