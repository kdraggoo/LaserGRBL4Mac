; Simple 50mm square test pattern
; Generated for LaserGRBL macOS testing

G21 ; Set units to millimeters
G90 ; Absolute positioning
M5 ; Laser off

; Move to start position
G0 X0 Y0 F3000

; Turn on laser
M3 S500

; Draw square (50mm x 50mm)
G1 X50 Y0 F1000
G1 X50 Y50
G1 X0 Y50
G1 X0 Y0

; Turn off laser
M5

; Return to origin
G0 X0 Y0

; End program

