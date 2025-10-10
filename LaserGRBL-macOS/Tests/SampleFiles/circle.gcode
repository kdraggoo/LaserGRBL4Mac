; Circle test pattern using arc commands
; 25mm radius circle centered at (25,25)

G21 ; millimeters
G90 ; absolute positioning
M5 ; laser off

; Move to start position (right side of circle)
G0 X50 Y25 F3000

; Turn on laser
M3 S300

; Draw circle using two 180-degree arcs
; First arc: right to left (top half)
G2 X0 Y25 I-25 J0 F800

; Second arc: left to right (bottom half)
G2 X50 Y25 I25 J0

; Turn off laser
M5

; Return home
G0 X0 Y0

; End

