; open flags
%define	O_RDONLY	0

; mmap flags
%define	PROT_READ	1
%define	MAP_SHARED	0x0001
%define MAP_FAILED	0xFFFFFFFF

; stat structure
struc stat
st_dev			resd	1	; = 0
st_ino			resd	1	; = 4
st_mode			resw	1	; = 8, size is 16 bits
st_nlink		resw	1	; = 10, ditto
st_uid			resd	1	; = 12
st_gid			resd	1	; = 16
st_rdev			resd	1	; = 20
st_atime		resd	1	; = 24
st_atimensec	resd	1	; = 28
st_mtime		resd	1	; = 32
st_mtimensec	resd	1	; = 36
st_ctime		resd	1	; = 40
st_ctimensec	resd	1	; = 44
st_size			resd	2	; = 48, size is 64 bits
st_blocks		resd	2	; = 56, ditto
st_blksize		resd	1	; = 64
st_flags		resd	1	; = 68
st_gen			resd	1	; = 72
st_lspare		resd	1	; = 76
st_qspare		resd	4	; = 80
endstruc


; syscalls
%define SYS_exit		1
%define SYS_write		4
%define SYS_open		5
%define SYS_close		6
%define	SYS_mmap		197
%define	SYS_munmap		73
%define	SYS_fstat		189

; libc
extern _sscanf
extern _sprintf
