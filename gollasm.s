;
;  gollasm
;
; .description
;  an IA-32 asm implementation of John H. Conway's cellular automaton, 
;  Game of Life, using OpenGL for visualisation
;
; .author
;  name: Tamas Szakaly
;  e-mail: sghctoma@gmail.com 
;  web: http://sghctoma.extra.hu
;
; .licence
;  This source code is released into the public domain in the hope that someday,
;  somewhere it will be useful for somebody. 
;
; .compile (OSX):
;  nasm -fmacho gollasm.asm
;  gcc -m32 -framework GLUT -framework OpenGL -o gollasm gollasm.o
;

%include 'glut.inc.s'
%include 'ogl.inc.s'
%include 'sys.inc.s'
%include 'macros.inc.s'

%define SIZE 512
%define TIME 6

;;;;;;;;;;;;;;; .bss section ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
section .bss
aspect_ratio		resq 1
xcoord				resd 1
ycoord				resd 1
zcoord				resd 1
listid				resd 1
filestat			resb 108
prevx				resd 1
prevy				resd 1
cells				resd SIZE*SIZE*TIME
cellnums			resd TIME
map_cells			resb SIZE*SIZE
map_cells_temp		resb SIZE*SIZE
map_neighbours		resb SIZE*SIZE
map_neighbours_temp	resb SIZE*SIZE
map_visited			resb SIZE*SIZE
numasstring			resb 16

;;;;;;;;;;;;;;; .data section ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
section .data

; error messages
errarg			db 'No pattern file specified!',10,'Usage: gollasm PATTERN.LIF',10
errarg_len		equ $-errarg
erropen			db 'Cannot open pattern file!',10
erropen_len		equ $-erropen
errgetsize		db 'Pattern file',"'",'s size cannot be determined!',10
errgetsize_len	equ $-errgetsize
errmap			db 'Pattern file cannot be mapped to memory!',10
errmap_len		equ $-errmap
errnotlif		db 'Pattern file is not a valid LIFE v1.05 file!',10
errnotlif_len	equ $-errnotlif
errtoobig		db 'The table is too small for this pattern!',10
errtoobig_len	equ $-errtoobig

; glut related stuff
glutgamemode	db '1680x1050:32',0
;glutgamemode	db '1280x800:32',0
title			db 'gollasm - Game of Life written in asm',0
btndown			dd -1

; LIF
fmttwoint	db '%d %d',0
lif_header	db '#Life 1.05'

; iteration
endofcells		dd 4*SIZE*SIZE*(TIME-1)
slice			dd 4*SIZE*SIZE
rowpitch		dd SIZE
actualslice		dd 0
actualtime		dd 0
doiterate		db 0xFF
sleepinframes	dd 8
elapsedframes	dd 0

; visualisation
cellsize	dq 1.0
thickline	dd 2.5
cellpos		dd 0.4
cellneg		dd -0.4

; hud
fmtint	db '%d',0
frames	dd 0

speed			db 'Speed: ',0
numofcells		db 'Number of cells: ',0
numofiterations	db 'Number of iterations: ',0

ctrlfullscreen	db 'Toggle fullscreen: F1',0
ctrltogglehud	db 'Toggle HUD: h',0
ctrlspeed		db 'Increase/decrease speed: ]/[',0
ctrlstep		db 'Step one iteration: s',0
ctrlgo			db 'Start iteration: i',0
ctrlquit		db 'Quit: ESC',0
ctrlzoom		db 'Zoom: middle mouse',0
ctrlrotate		db 'Rotate: right mouse',0
ctrltranslate	db 'Translate: left mouse',0

; frequently used floats/doubles
f0	dd 0.0
f1	dd 1.0
fm1	dd -1.0
d0	dq 0.0
d1	dq 1.0
dm1	dq -1.0

; clear color
rclear	dd 0.01
gclear	dd 0.01
bclear	dd 0.0

; camera
degtorad	dd 0.0174532888889 ; PI/180.0
fov			dq 45.0
farclip		dq 10000.0

zoom		dd 120.0
theta		dd 0.01
fi			dd 0.0

transx		dq 0.0
transy		dq 0.0
xeye		dq 0.0
yeye		dq 0.0
zeye		dq 0.0

rot_delta	dd 0.5
zoom_delta	dd 0.4
trans_delta	dd -0.002
zoom_min	dd 10.0
zoom_max	dd 80.0
theta_min	dd 0.01
theta_max	dd 80.0

; hud
displayhud	db 0xFF
width		dq 800.0
height		dq 600.0

;;;;;;;;;;;;;;; .text section ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .text
global	_main

;;;;;;;;;;;;;;; kernel ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
kernel:
	int 0x80
	ret

;;;;;;;;;;;;;;; maketempcell ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ebx - next slice of cells
; ebp - current slice of cells
; esi - offset
maketempcell:
	; map_cells
	mov byte [map_cells_temp+esi], 1
	
	; map_neighbours
	lea eax, [esi-SIZE-1]
	inc byte [map_neighbours_temp+eax]
	inc byte [map_neighbours_temp+eax+1]
	inc byte [map_neighbours_temp+eax+2]
	
	inc byte [map_neighbours_temp+eax+SIZE]
	inc byte [map_neighbours_temp+eax+SIZE+2]
	
	inc byte [map_neighbours_temp+eax+2*SIZE]
	inc byte [map_neighbours_temp+eax+2*SIZE+1]
	inc byte [map_neighbours_temp+eax+2*SIZE+2]
	
	; cells
	mov eax, dword [actualtime]			; eax=next actualtime
	mov ecx, dword [cellnums+eax*4]		; ecx=next number of cells
	mov dword [ebx+ecx*4], esi			; place cell into next slice
	inc dword [cellnums+eax*4]			; increment cell number
	
	ret

;;;;;;;;;;;;;;; checkcell ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ebx - next slice of cells
; ebp - current slice of cells
; esi - offset
checkcell:
	; have we checked this cell yet?
	cmp byte [map_visited+esi], 1
	je checkcell_end
	mov byte [map_visited+esi], 1
	
	; apply GoL rules (S23B3)
	cmp byte [map_neighbours+esi], 3
	je newcell
	
	mov al, byte [map_neighbours+esi]
	add al, byte [map_cells+esi]
	cmp al, 3
	jne checkcell_end

newcell:
	call maketempcell

checkcell_end:
	ret
		
;;;;;;;;;;;;;;; iterate ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
iterate:
	push esi
	push edi
	push ebx
	
	; calculate offsets to cells
	xor esi, esi
	mov ecx, dword [actualtime]
	lea eax, [ecx+1]
	cmp eax, TIME	; if on the end, wrap around
	cmove eax, esi
	mov dword [cellnums+4*eax], 0
	mov dword [actualtime], eax	
	mul dword [slice]
	lea ebx, [eax+cells] ; ebx=temp
	mov eax, ecx
	mul dword [slice]
	lea esi, [eax+cells] ; esi=cells

	; null temp 
	mov eax, -1
	mov ecx, SIZE*SIZE
	lea edi, [ebx]
	rep stosd
	
	; null temporary neighbours
	xor al, al
	mov ecx, SIZE*SIZE
	lea edi, [map_neighbours_temp]
	rep stosb
	
	; null temporary cells map
	mov ecx, SIZE*SIZE
	lea edi, [map_cells_temp]
	rep stosb
	
	; null visited
	mov ecx, SIZE*SIZE
	lea edi, [map_visited]
	rep stosb
	
	mov edi, esi ; edi=cells

iterate_loop_start:
	mov eax, dword [edi]
	cmp eax, -1
	je iterate_end

	lea esi, [eax-SIZE-1]
	call checkcell
	inc esi
	call checkcell
	inc esi
	call checkcell
	
	add esi, SIZE-2
	call checkcell
	add esi, 2
	call checkcell
	
	add esi, SIZE-2
	call checkcell
	inc esi
	call checkcell
	inc esi
	call checkcell
	
iterate_loop_end:
	add edi, 4
	jmp iterate_loop_start

iterate_end:
	; copy temporary cells map to cells map
	lea esi, [map_cells_temp]
	lea edi, [map_cells]
	mov ecx, SIZE*SIZE
	rep movsb
	
	; copy temporary neighbours map to neighbours map
	lea esi, [map_neighbours_temp]
	lea edi, [map_neighbours]
	mov ecx, SIZE*SIZE
	rep movsb

	inc dword [frames]
	pop ebx
	pop edi
	pop esi
	ret
	
;;;;;;;;;;;;;;; camera ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
camera:
	; xeye
	finit
	fld dword [fi]
	fmul dword [degtorad]
	fcos				; cos(deg2rad(fi))
	fld dword [theta]
	fmul dword [degtorad]
	fsin				; sin(deg2rad(theta))
	fmul st0, st1		; st0 = cos(deg2rad(fi))*sin(deg2rad(theta))
	fmul dword [zoom]
	fadd qword [transx]
	fstp qword [xeye]
	
	; yeye
	finit
	fld dword [fi]
	fmul dword [degtorad]
	fsin				; sin(deg2rad(fi))
	fld dword [theta]
	fmul dword [degtorad]
	fsin				; sin(deg2rad(theta))
	fmul st0, st1		; st0 = sin(deg2rad(fi))*sin(deg2rad(theta))
	fmul dword [zoom]
	fadd qword [transy]
	fstp qword [yeye]
	
	; zeye
	finit
	fld dword [theta]
	fmul dword [degtorad]
	fcos				; cos(deg2rad(theta))
	fmul dword [zoom]
	fstp qword [zeye]

	ret
	
;;;;;;;;;;;;;;; putstring ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; [esp]		- str
; [esp+4]	- x
; [esp+8]	- y
putstring:
	push ebx
	prolog
	
	invoke3 _glColor3ub, 230, 230, 250
	cmp dword [ebp+16], -1
	je putstring_start
	invoke2 _glRasterPos2i, [ebp+16], [ebp+20]
	
putstring_start:
	mov ebx, dword [ebp+12]
	xor ecx, ecx
	
putstring_loop_start:
	mov cl, byte [ebx]
	cmp cl, 0
	je putstring_end
	invoke2 _glutBitmapCharacter, GLUT_BITMAP_TIMES_ROMAN_24, ecx
	
	inc ebx
	jmp putstring_loop_start
	
putstring_end:
	epilog
	pop ebx
	ret

	
;;;;;;;;;;;;;;; hud ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
hud:
	prolog
	
	call _glPushMatrix
	call _glLoadIdentity
	
	invoke1 _glMatrixMode, GL_PROJECTION
	call _glPushMatrix
	call _glLoadIdentity
	invoke12 _glOrtho, [d0], [d0+4], [width], [width+4], \
						[height], [height+4], [d0], [d0+4], \
						[dm1], [dm1+4], [d1], [d1+4]
	
	; write speed
	invoke3 putstring, speed, 10, 30
	mov eax, dword [sleepinframes]
	shr eax, 2
	mov ecx, 57
	sub ecx, eax
	invoke2 _glutBitmapCharacter, GLUT_BITMAP_TIMES_ROMAN_24, ecx

	; write number of iterations
	invoke3 putstring, numofiterations, 10, 48
	invoke3 _sprintf, numasstring, fmtint, [frames]
	invoke3 putstring, numasstring, -1, -1
	
	; write number of active cells
	invoke3 putstring, numofcells, 10, 66
	mov eax, dword [actualtime]
	mov eax, dword [cellnums+4*eax]
	invoke3 _sprintf, numasstring, fmtint, eax
	invoke3 putstring, numasstring, -1, -1

	; write controls
	invoke3 putstring, ctrlfullscreen, 10, 444
	invoke3 putstring, ctrltogglehud, 10, 462
	invoke3 putstring, ctrlspeed, 10, 480
	invoke3 putstring, ctrlstep, 10, 498
	invoke3 putstring, ctrlgo, 10, 516
	invoke3 putstring, ctrlzoom, 10, 534
	invoke3 putstring, ctrlrotate, 10, 552
	invoke3 putstring, ctrltranslate, 10, 570
	invoke3 putstring, ctrlquit, 10, 588

	call _glPopMatrix
	invoke1 _glMatrixMode, GL_MODELVIEW
	call _glPopMatrix

	epilog
	ret

;;;;;;;;;;;;;;; draw ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
draw:
	push esi
	push edi
	push ebx
	prolog
	
	invoke1 _glClear, GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT
	call _glLoadIdentity
	
	invoke18 _gluLookAt, [xeye], [xeye+4], [yeye], [yeye+4], [zeye], [zeye+4], \
						  [transx], [transx+4], [transy], [transy+4], [d0], [d0+4],\
						  [d0], [d0+4], [d0], [d0+4], [d1], [d1+4]	
	
	mov eax, dword [actualtime]
	mul dword [slice]
	mov edi, eax
	
	mov ebx, TIME
	
timeloop_start:
	dec ebx
	
	cmp edi, -4*SIZE*SIZE
	cmove edi, [endofcells]
	
	xor esi, esi
	
	draw_loop_start:
		cmp dword [cells+edi+esi], -1
		je near timeloop_end
	
		xor edx, edx
		mov eax, dword [cells+edi+esi]
		div dword [rowpitch]
		mov dword [xcoord], edx
		mov dword [ycoord], eax
		sub dword [xcoord], SIZE/2-1
		sub dword [ycoord], SIZE/2-1
		fild dword [xcoord]
		fstp dword [xcoord]
		fild dword [ycoord]
		fstp dword [ycoord]
		mov dword [zcoord], ebx
		fild dword [zcoord]
		fstp dword [zcoord]
		
		call _glPushMatrix
		invoke3 _glTranslatef, [xcoord], [ycoord], [zcoord]
		cmp ebx, TIME-1
		je newestgen
		mov edx, ebx
		shl edx, 5
		invoke4 _glColor4ub, 128, 128, 128, edx
		invoke2 _glutSolidCube, [cellsize], [cellsize+4]
		mov edx, ebx
		shl edx, 3
		invoke4 _glColor4ub, 0, 0, 0, edx
		invoke2 _glutWireCube, [cellsize], [cellsize+4]
		jmp putcell_end
		
	newestgen:
		invoke4 _glColor4ub, 120, 200, 40, 225
		invoke2 _glutSolidCube, [cellsize], [cellsize+4]
		invoke4 _glColor4ub, 0, 0, 0, 255
		invoke2 _glutWireCube, [cellsize], [cellsize+4]
		
	putcell_end:
		call _glPopMatrix	
	
		add esi, 4
		jmp draw_loop_start
	
timeloop_end:
	sub edi, 4*SIZE*SIZE
	cmp ebx, 0
	jnz timeloop_start
	
	cmp byte [displayhud], 0
	jne flush
	call hud
	
flush:
	call _glutSwapBuffers
	
	cmp byte [doiterate], 0
	jne draw_end
	mov eax, dword [sleepinframes]
	cmp dword [elapsedframes], eax
	jb draw_end
	call iterate
	mov dword [elapsedframes], 0
	
draw_end:
	inc dword [elapsedframes]
	epilog
	pop ebx
	pop edi
	pop esi
	ret
	
;;;;;;;;;;;;;;; reshape ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; [esp]		- width
; [esp+4]	- height
reshape:
	prolog
	
	cmp dword[ebp+8], 0
	jne reshape_cont
	inc dword[ebp+8]

reshape_cont:
	fild dword[ebp+8]
	fidiv dword[ebp+12]
	fstp qword[aspect_ratio]
	invoke4 _glViewport, 0, 0, [ebp+8], [ebp+12]
	invoke1 _glMatrixMode, GL_PROJECTION
	call _glLoadIdentity	
	invoke8 _gluPerspective, [fov], [fov+4], [aspect_ratio], [aspect_ratio+4], \
							 [d1], [d1+4], [farclip], [farclip+4]
	invoke1 _glMatrixMode, GL_MODELVIEW
	
	epilog
	ret

;;;;;;;;;;;;;;; onkeypress ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; [esp]		- key
; [esp+4]	- x
; [esp+8]	- y
onkeypress:
	mov al, byte [esp+4]
	
	cmp al, 27
	je quit
	cmp al, 'i'
	je changeiterate
	cmp al, '['
	je slowdown
	cmp al, ']'
	je speedup
	cmp al, 'h'
	je changehud
	cmp al, 's'
	je onestep
	jmp noaction
	
quit:
	mov eax, SYS_exit
	invoke1 kernel, 0
	jmp noaction
	
changehud:
	not byte [displayhud]
	jmp noaction
	
onestep:
	call iterate
	jmp noaction

changeiterate:
	not byte [doiterate]
	jmp noaction
	
slowdown:
	cmp dword [sleepinframes], 36
	jge noaction
	add dword [sleepinframes], 4
	jmp noaction
	
speedup:
	cmp dword [sleepinframes], 0
	jbe noaction
	sub dword [sleepinframes], 4
	jmp noaction
	
noaction
	ret

;;;;;;;;;;;;;;; onspecialkey ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; [esp]		- key
; [esp+4]	- x
; [esp+8]	- y
onspecialkey:
	prolog
	mov al, byte [ebp+8]
	cmp al, GLUT_KEY_F1
	jne near onspecialkey_end
	
	invoke1 _glutGameModeGet, GLUT_GAME_MODE_ACTIVE
	or eax, eax
	jnz togglewindowed
	
	invoke1 _glutGameModeString, glutgamemode
	call _glutEnterGameMode
	jmp reset
	
togglewindowed:
	call _glutLeaveGameMode
	
reset:
	call setcallbacks
	call setupopengl
	
onspecialkey_end:
	epilog
	ret

;;;;;;;;;;;;;;; onmouse ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; [esp]		- button
; [esp+4]	- state
; [esp+8]	- x
; [esp+12]	- y
onmouse:
	cmp dword [esp+8], GLUT_DOWN
	je buttonpressed
	jmp buttonreleased
	
buttonpressed:
	mov eax, dword [esp+4]
	mov dword [btndown], eax
	mov eax, dword [esp+12]
	mov dword [prevx], eax
	mov eax, dword [esp+16]
	mov dword [prevy], eax
	jmp onmouse_end

buttonreleased:
	mov dword [btndown], -1
	
onmouse_end:
	ret

;;;;;;;;;;;;;;; onmousemove ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; [esp]		- x
; [esp+4]	- y
onmousemove:
	mov ecx, dword [esp+4]
	mov edx, dword [esp+8]
	sub esp, 8
	mov dword [esp], ecx
	mov dword [esp+4], edx
	mov eax, dword [prevx]
	sub dword [esp], eax	; [esp]=deltax
	mov eax, dword [prevy]
	sub dword [esp+4], eax	; [esp+4]=deltay
	
	cmp dword [btndown], GLUT_LEFT_BUTTON
	je near translate
	cmp dword [btndown], GLUT_MIDDLE_BUTTON
	je near dozoom
	cmp dword [btndown], GLUT_RIGHT_BUTTON
	je near rotate

translate:
	; dx = x*cos(fi)-y*sin(fi)
	; dy = y*cos(fi)+x*sin(fi)
	
	finit
	fld dword [fi]
	fmul dword [degtorad]
	fsin
	fld dword [fi]
	fmul dword [degtorad]
	fcos
	fild dword [esp]
	fild dword [esp+4]	; st0=x,st1=y,st2=cos(fi),st3=sin(fi)
	
	; transx
	fld st0
	fmul st3
	fmul dword [trans_delta]
	fmul dword [zoom]
	fadd qword [transx]
	fstp qword [transx]
	fld st1
	fmul st4
	fmul dword [trans_delta]
	fmul dword [zoom]
	fsubr qword [transx]
	fstp qword [transx]
	
	; transy
	fld st1
	fmul st3
	fmul dword [trans_delta]
	fmul dword [zoom]
	fadd qword [transy]
	fstp qword [transy]
	fld st0
	fmul st4
	fmul dword [trans_delta]
	fmul dword [zoom]
	fadd qword [transy]
	fstp qword [transy]
	jmp onmousemove_end
	
rotate:
	finit
	fld dword [theta_min]
	fld dword [theta_max]
	fild dword [esp+4]
	fmul dword [rot_delta]
	fadd dword [theta]
	fcomi st2
	fcmovb st2
	fcomi st1
	fcmovnb st1
	fstp dword [theta]
	
	finit
	fild dword [esp]
	fmul dword [rot_delta]
	fadd dword [fi]
	fstp dword [fi]
	jmp onmousemove_end
	
dozoom:
	finit
	fld dword [zoom_min]
	fild dword [esp+4]
	fmul dword [zoom_delta]
	fadd dword [zoom]
	fcomi st1
	fcmovb st1
	fstp dword [zoom]
	jmp onmousemove_end
	
onmousemove_end:
	add esp, 8
	call camera
	mov dword [prevx], ecx
	mov dword [prevy], edx
	ret

;;;;;;;;;;;;;;; readconfig ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; [esp] - filename
readconfig:
	push ebx
	push esi
	push edi
	prolog

	; open config file
	mov eax, SYS_open
	invoke2 kernel, [ebp+20], O_RDONLY
	; if open fails, eax should be a negative number according to
	; documentation. it is not negative, it is 2. what the frack????
	;test eax, eax 
	;jns getsize
	cmp eax, 2
	jng near err_open
	
	; get size:
	mov ebx, eax ; ebx = filedesc
	mov eax, SYS_fstat
	invoke2 kernel, ebx, filestat
	or eax, eax
	jne near err_getsize
	
	; map file
	mov eax, SYS_mmap
	invoke8 kernel, 0, [filestat+st_size], PROT_READ, MAP_SHARED, ebx, 0, 0, 0
	cmp eax, MAP_FAILED
	je near err_map
	mov esi, eax ; esi - address of mapped file

	; check for LIF header
	lea edi, [lif_header]
	mov ecx, 10
	cld
	repe cmpsb
	jne near err_notlif
	add esi, 2
	
process_comments:
	cmp word [esi], '#R'
	je custom_rule
	cmp word [esi], '#P'
	je pattern_start
	inc esi
	jmp process_comments
	
custom_rule:
	add esi, 2
	invoke4 _sscanf, esi, fmttwoint, xcoord, ycoord
	; TODO: custom rules...
	
pattern_start:
	cmp word [esi], '#P'
	jne getpattern
	add esi, 3
	invoke4 _sscanf, esi, fmttwoint, xcoord, ycoord
	mov ecx, dword [xcoord]
	mov edi, dword [ycoord]
	
crunch:
	inc esi
	cmp byte [esi], 13
	jne crunch
	
getpattern:
	cmp byte [esi], 13
	je eol
	cmp byte [esi], '*'
	je addcell
	cmp byte [esi], '.'
	je getpattern_cont
	jmp err_notlif
	
getpattern_cont:
	inc esi
	inc ecx
	jmp getpattern
	
eol:
	add esi, 2
	cmp byte [esi], 0
	jne eol_cont
	jmp readconfig_end
	
eol_cont:
	inc edi
	mov ecx, dword [xcoord]
	jmp pattern_start
	
addcell:
	mov eax, ecx
	add eax, SIZE/2-1
	mov edx, SIZE
	mul edx
	add eax, edi
	add eax, SIZE/2-1
	cmp eax, SIZE*SIZE-1
	jg err_toobig				; index is greater than max possible index
	test eax, eax
	js err_toobig				; index is lower than 0
	
	; map_cells
	mov byte [map_cells+eax], 1
	
	; map_neighbours
	lea eax, [eax-SIZE-1]
	inc byte [map_neighbours+eax]
	inc byte [map_neighbours+eax+1]
	inc byte [map_neighbours+eax+2]
	
	inc byte [map_neighbours+eax+SIZE]
	inc byte [map_neighbours+eax+SIZE+2]
	
	inc byte [map_neighbours+eax+2*SIZE]
	inc byte [map_neighbours+eax+2*SIZE+1]
	inc byte [map_neighbours+eax+2*SIZE+2]
	add eax, SIZE+1
	
	; cells
	mov edx, dword [cellnums]
	mov dword [cells+edx*4], eax
	inc dword [cellnums]
	
	inc ecx
	inc esi
	jmp getpattern

; error handlers
err_toobig:
	mov ecx, errtoobig
	mov edx, errtoobig_len
	jmp err

err_open:
	mov ecx, erropen
	mov edx, erropen_len
	jmp err

err_getsize
	mov ecx, errgetsize
	mov edx, errgetsize_len
	jmp err

err_map:
	mov ecx, errmap
	mov edx, errmap_len
	jmp err

err_notlif:
	mov ecx, errnotlif
	mov edx, errnotlif_len

err:
	mov eax, SYS_write
	invoke3 kernel, 1, ecx, edx
	mov ecx, 1
	jmp readconfig_realend

readconfig_end:
	xor ecx, ecx
	
readconfig_realend:
	mov eax, SYS_close
	invoke1 kernel, ebx
	mov eax, ecx

	epilog
	pop edi
	pop esi
	pop ebx
	ret

;;;;;;;;;;;;;;; setcallbacks ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
setcallbacks:
	prolog
	
	invoke1 _glutDisplayFunc, draw
	invoke1 _glutIdleFunc, draw
	invoke1 _glutReshapeFunc, reshape
	invoke1 _glutKeyboardFunc, onkeypress
	invoke1 _glutMouseFunc, onmouse
	invoke1 _glutMotionFunc, onmousemove
	invoke1 _glutSpecialFunc, onspecialkey
	
	epilog
	ret

;;;;;;;;;;;;;;; setupopengl ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
setupopengl
	prolog
	
	invoke4 _glClearColor, [rclear], [gclear], [bclear], [f1]
	invoke2 _glClearDepth, [d1], [d1+4]
	invoke1 _glDepthFunc, GL_LEQUAL
	invoke1 _glEnable, GL_DEPTH_TEST
	invoke1 _glShadeModel, GL_FLAT
	invoke1 _glEnable, GL_BLEND
	invoke2 _glBlendFunc, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA
	invoke1 _glEnable, GL_LINE_SMOOTH
	invoke2 _glHint, GL_LINE_SMOOTH_HINT, GL_DONT_CARE
	invoke1 _glLineWidth, [thickline]
	
	epilog
	ret

;;;;;;;;;;;;;;; main ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; [esp]		- argc
; [esp+4]	- argv
_main:
	prolog

	cmp dword [ebp+8], 2
	je setupgraphics
	mov eax, SYS_write
	invoke3 kernel, 1, errarg, errarg_len
	epilog
	mov eax, 1
	ret

setupgraphics:
	lea eax, [ebp+8]
	invoke2 _glutInit, eax, [ebp+12]	
	invoke1 _glutInitDisplayMode, GLUT_RGBA | GLUT_DOUBLE | GLUT_ALPHA | GLUT_DEPTH
	
	call camera
	
	invoke2 _glutInitWindowSize, 1024, 768
	invoke2 _glutInitWindowPosition, 100, 100
	invoke1 _glutCreateWindow, title
	
	call setcallbacks
	call setupopengl

	; null cells
	mov eax, -1
	mov ecx, SIZE*SIZE*TIME
	lea edi, [cells]
	rep stosd
	
	; null cellnums
	xor eax, eax
	mov ecx, TIME
	lea edi, [cellnums]
	rep stosd
	
	; null map_cells
	mov ecx, SIZE*SIZE
	lea edi, [map_cells]
	rep stosb
	
	; null map_neighbours
	mov ecx, SIZE*SIZE
	lea edi, [map_neighbours]
	rep stosb
	
	; read starting configuration from .lif file
	mov eax, [ebp+12]
	invoke1 readconfig, [eax+4]
	or eax, eax
	jne end
	
	; start rendering
	call _glutMainLoop

end:
	epilog
	mov eax, 0
	ret