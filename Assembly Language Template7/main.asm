INCLUDE Irvine32.inc

FILETIME STRUCT       ;(in SmallWin.inc)
    loDateTime DWORD ?
    hiDateTime DWORD ?
FILETIME ENDS

.data
;for adjusting the count
hourCount DWORD 2
adjustedCount DWORD ? ;will use ebx as index to be adjusted

;prompts for menu
promptMenu BYTE "Choose ONE of the following:", 0
promptMenuOne BYTE "1- Start Clock", 0
promptMenuTwo BYTE "2- Set Clock and then Start", 0

invalidChoice BYTE "CHOICE IS NOT VALID", 0

;for setting new time
promptNewTime BYTE "Enter new time(hh:mm:ss): ", 0
byteCount DWORD ?
changedTime BYTE 9 DUP(0)

;current time
currentTime BYTE '0', '0', ':', '0', '0', ':', '0', '0', 0

;current date
dateTime FILETIME <> 

.code
main PROC

	CALL menu

	CALL readchar
	
	exit
main ENDP

menu PROC
	PUSHAD
	
	MOV edx, offset promptMenu
	CALL writestring
	CALL crlf

	MOV edx, offset promptMenuOne
	CALL writestring
	CALL crlf 

	MOV edx, offset promptMenuTwo
	CALL writestring
	CALL crlf

;	MOV edx, offset promptMenuThree
;	CALL writestring
;	CALL crlf

	CALL readint

	CMP eax, 1
	JE startClock

	CMP eax, 2
	JE setAndStartClock

	CMP eax, 3
	JE displayDate
	JMP invalidInput

	startClock:
		CALL clock
	JMP TERMINATE

	setAndStartClock:
		CALL resetTime
		CALL clock
	JMP TERMINATE

	displayDate:
		MOV edx, offset dateTime
		INVOKE GetDateTime,ADDR dateTime
	JMP TERMINATE

	invalidInput:
		MOV edx, offset invalidChoice
		CALL writestring
		CALL crlf

	TERMINATE:
	POPAD
	RET
menu ENDP

resetTime PROC

	PUSHAD
	MOV edx, offset promptNewTime
	CALL writestring

	MOV edx, offset changedTime
	MOV ecx, sizeof changedTime
	CALL readstring
	MOV byteCount, eax

	INVOKE str_copy, ADDR changedTime, ADDR currentTime
	POPAD

	RET
resetTime ENDP

countAdjusterUnits PROC
	
	PUSHAD
	MOV eax,0 
	MOV al, '9'    
	SUB al, [currentTime + ebx]    
	AAS            
	PUSHF          
	OR al,30h  
	POPF        
	.IF al == '0'
		MOV adjustedCount, 1
	.ELSEIF al == '1'
		MOV adjustedCount, 2
	.ELSEIF al == '2'
		MOV adjustedCount, 3
	.ELSEIF al == '3'
		MOV adjustedCount, 4
	.ELSEIF al == '4'
		MOV adjustedCount, 5
	.ELSEIF al == '5'
		MOV adjustedCount, 6
	.ELSEIF al == '6'
		MOV adjustedCount, 7
	.ELSEIF al == '7'
		MOV adjustedCount, 8
	.ELSEIF al == '8'
		MOV adjustedCount, 9
	.ELSEIF al == '9'
		MOV adjustedCount, 10
	.ENDIF
	POPAD

	RET
countAdjusterUnits ENDP

countAdjusterTens PROC
	
	PUSHAD
	MOV eax,0 
	MOV al, '6'    
	SUB al, [currentTime + ebx]    
	AAS            
	PUSHF          
	OR al,30h  
	POPF        
	.IF al == '0'
		MOV adjustedCount, 0
	.ELSEIF al == '1'
		MOV adjustedCount, 1
	.ELSEIF al == '2'
		MOV adjustedCount, 2
	.ELSEIF al == '3'
		MOV adjustedCount, 3
	.ELSEIF al == '4'
		MOV adjustedCount, 4
	.ELSEIF al == '5'
		MOV adjustedCount, 5
	.ELSEIF al == '6'
		MOV adjustedCount, 6
	.ENDIF
	POPAD

	RET
countAdjusterTens ENDP

countAdjusterHours PROC

	PUSHAD
	MOV eax,0 
	MOV al, '2'    
	SUB al, [currentTime + 0]    
	AAS            
	PUSHF          
	OR al,30h  
	POPF  
	.IF al == '0'
		MOV adjustedCount, 1
	.ELSEIF al == '1'
		MOV adjustedCount, 2
	.ELSEIF al == '2'
		MOV adjustedCount, 3
	.ENDIF
	POPAD

	RET
countAdjusterHours ENDP

clock PROC
	
	CALL hoursIncrement

	RET
clock ENDP

display PROC

	PUSHAD
	MOV edx, offset currentTime
	CALL writestring
	MOV eax, 1000
	CALL delay
	CALL clrscr
	MOV eax, 0
	POPAD
	RET

display ENDP
secondsIncrement PROC

	PUSHAD
	MOV ebx, 6
	CALL countAdjusterTens
	MOV ecx, adjustedCount
	tensIncrement:

		PUSH ecx
		MOV ebx, 7
		CALL countAdjusterUnits
		MOV ecx, adjustedCount
		MOV eax, 0

		unitIncrement:

			CALL display

			MOV al, [currentTime + 7]
			ADD al, '1'
			AAA
			OR ax, 3030h
			MOV [currentTime + 7], al

		LOOP unitIncrement

		MOV al, [currentTime + 6]
		ADD al, '1'
		AAA
		OR ax, 3030h
		MOV [currentTime + 6], al
		POP ecx

	LOOP tensIncrement
	POPAD

	RET

secondsIncrement ENDP

minutesIncrement PROC
	PUSHAD
	MOV ebx, 3
	CALL countAdjusterTens
	MOV ecx, adjustedCount
	tensIncrement:

		PUSH ecx
		MOV ebx, 4
		CALL countAdjusterUnits
		MOV ecx, adjustedCount
		MOV eax, 0

		unitIncrement:

			CALL secondsIncrement

			CALL resetSeconds

			MOV al, [currentTime + 4]
			ADD al, '1'
			AAA
			OR ax, 3030h
			MOV [currentTime + 4], al

		LOOP unitIncrement

		MOV al, [currentTime + 3]
		ADD al, '1'
		AAA
		OR ax, 3030h
		MOV [currentTime + 3], al
		POP ecx

	LOOP tensIncrement
	POPAD

	RET
minutesIncrement ENDP

hoursIncrement PROC

	PUSHAD
	CALL countAdjusterHours
	MOV ecx, adjustedCount
	tensIncrement:

		PUSH ecx
		MOV ebx, 1
		CALL countAdjusterUnits
		.IF adjustedCount == 7
			MOV adjustedCount, 8
			MOV hourCount, 0
		.ENDIF
		MOV ecx, adjustedCount
		MOV eax, 0

		unitIncrement:

			.IF ecx == 7 && hourCount == 0
				JMP TERMINATE
			.ENDIF

			CALL minutesIncrement
			CALL resetMinutes

			MOV al, [currentTime + 1]
			ADD al, '1'
			AAA
			OR ax, 3030h
			MOV [currentTime + 1], al

		LOOP unitIncrement

		MOV al, [currentTime + 0]
		ADD al, '1'
		AAA
		OR ax, 3030h
		MOV [currentTime + 0], al
		DEC hourCount
		POP ecx

	LOOP tensIncrement
	TERMINATE:
	POP ecx
	POPAD
	RET

hoursIncrement ENDP

resetSeconds PROC
	
	PUSHAD
	MOV [currentTime + 7], '0'
	MOV [currentTime + 6], '0'
	POPAD

	RET
resetSeconds ENDP

resetMinutes PROC
	
	PUSHAD
	CALL resetSeconds
	MOV [currentTime + 4], '0'
	MOV [currentTime + 3], '0'
	POPAD

	RET
resetMinutes ENDP

END main


