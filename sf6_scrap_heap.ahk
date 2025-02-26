#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

;-------------------------------------------------------------------------------
; STREET FIGHTER 6 - JUNKYARD SMALLZ FARMING SCRIPT
;-------------------------------------------------------------------------------
; OVERVIEW:
; This script automates farming in the Junkyard Smallz minigame in Street Fighter 6.
; It uses a simplified approach of spamming a single move to reliably hit the truck.
;
; CHARACTER CONFIGURATION:
; - Control Type: Modern Controls
; - Character: Cammy (though works with any character)
; - Primary Move: Spiral Arrow (Neutral+I)
;
; STRATEGY:
; - Spams Neutral+I (Spiral Arrow) with consistent timing
; - Periodically shifts right to counter leftward drift
; - Handles match completion and restart automatically
; - Optimized to use most of the available round time
;
; CONTROLS:
; - Numpad1: Start farming
; - Numpad2: Stop farming
; - Numpad3: Emergency exit
;-------------------------------------------------------------------------------

; Configuration
attackCount := 65
resultWaitTime := 5000
farmCount := 0

; Modern Controls
upKey := "w"
leftKey := "a"
downKey := "s"
rightKey := "d"
specialMove := "i"
confirmKey := "f"

; Start farming with Numpad1
Numpad1::
    $stop := 0
    $count := 0
    farmCount := 0
    
    ; Create status overlay
    Gui, +AlwaysOnTop
    Gui, Add, Text, vStatusText w200, Starting Junkyard Smallz farming...
    Gui, Show, NoActivate x20 y20, SF6 Farming Status
    
    Loop, {
        ; Reset position to ensure clean neutral input
        Send {%leftKey% up}
        Send {%rightKey% up}
        Send {%upKey% up}
        Send {%downKey% up}
        Sleep, 50
        
        ; Regular drift correction (every 4 attacks)
        if (Mod($count, 4) = 0) {
            Send {%rightKey% down}
            Sleep, 120
            Send {%rightKey% up}
            Sleep, 80
        }
        
        ; Execute Neutral+I (Cammy's Spiral Arrow)
        Send {%specialMove% down}
        Sleep, 50
        Send {%specialMove% up}
        
        ; Count attacks
        $count++
        
        ; Random delay between attacks
        Random, delay, 200, 300
        Sleep, delay
        
        ; Heavier position correction (every 10 attacks)
        if (Mod($count, 10) = 0) {
            Send {%rightKey% down}
            Sleep, 200
            Send {%rightKey% up}
            Sleep, 100
        }
        
        ; Match end handling
        if ($count >= attackCount) {
            ; Wait for results screen
            Sleep, resultWaitTime
            $count := 0
            farmCount++
            
            ; Update status
            GuiControl,, StatusText, Junkyard Smallz farming`nRuns completed: %farmCount%
            
            ; Press F to see results
            Send {%confirmKey% down}
            Sleep, 30
            Send {%confirmKey% up}
            Sleep, 2000
            
            ; Press LEFT to select "YES" and restart the minigame
            Send {%leftKey% down}
            Sleep, 100
            Send {%leftKey% up}
            Sleep, 300
            
            ; Press F to confirm rematch
            Send {%confirmKey% down}
            Sleep, 30
            Send {%confirmKey% up}
            Sleep, 4000
        }
        
        ; Check for stop command
        if ($stop) {
            Gui, Destroy
            MsgBox, Farming stopped. Completed %farmCount% runs.
            return
        }
    }
return

; Stop farming with Numpad2
Numpad2::
    $stop := 1
return

; Emergency exit with Numpad3
Numpad3::
    Gui, Destroy
    MsgBox, Script terminated
    ExitApp
return
