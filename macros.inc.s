; OSX's ABI requires the stack to be aligned by 16 bytes,
; because of some SSE2 instructions requires it. I use 
; these macros to generate the appropriate pro- and epilog
; for functions
%macro prolog 0
	push ebp
	mov ebp, esp
	and esp, 0xFFFFFFF0
%endmacro

%macro epilog 0
	mov esp, ebp
	pop ebp
%endmacro

; function call helper macros
%macro invoke1 2
	sub esp, 12
	push dword %2
	call %1
	add esp, 16
%endmacro

%macro invoke2 3
	sub esp, 8
	push dword %3
	push dword %2
	call %1
	add esp, 16
%endmacro

%macro invoke3 4
	sub esp, 4
	push dword %4
	push dword %3
	push dword %2
	call %1
	add esp, 16
%endmacro

%macro invoke4 5
	push dword %5
	push dword %4
	push dword %3
	push dword %2
	call %1
	add esp, 16
%endmacro

%macro invoke8 9
	push dword %9
	push dword %8
	push dword %7
	push dword %6
	push dword %5
	push dword %4
	push dword %3
	push dword %2
	call %1
	add esp, 32
%endmacro

%macro invoke12 13
	push dword %13
	push dword %12
	push dword %11
	push dword %10
	push dword %9
	push dword %8
	push dword %7
	push dword %6
	push dword %5
	push dword %4
	push dword %3
	push dword %2
	call %1
	add esp, 48
%endmacro

%macro invoke18 19
	sub esp, 8
	push dword %19
	push dword %18
	push dword %17
	push dword %16
	push dword %15
	push dword %14
	push dword %13
	push dword %12
	push dword %11
	push dword %10
	push dword %9
	push dword %8
	push dword %7
	push dword %6
	push dword %5
	push dword %4
	push dword %3
	push dword %2
	call %1
	add esp, 80
%endmacro
