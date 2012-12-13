GLUT_RGBA equ 0x0
GLUT_DOUBLE equ 0x2
GLUT_ALPHA equ 0x8
GLUT_DEPTH equ 0x10

; mouse buttons
GLUT_LEFT_BUTTON equ 0
GLUT_MIDDLE_BUTTON equ 1
GLUT_RIGHT_BUTTON equ 2

; mouse button state
GLUT_DOWN equ 0
GLUT_UP equ 1

GLUT_KEY_F1 equ 1

; fracking ugly. got the address with GDB..
; chances are, that this will not survive
; an update..
GLUT_BITMAP_TIMES_ROMAN_24 equ 0x3e047440

GLUT_GAME_MODE_ACTIVE equ 0

extern _glutInit
extern _glutInitDisplayMode
extern _glutInitWindowSize, 
extern _glutInitWindowPosition, 
extern _glutCreateWindow
extern _glutMainLoop
extern _glutDisplayFunc
extern _glutIdleFunc
extern _glutReshapeFunc, 
extern _glutKeyboardFunc
extern _glutSwapBuffers
extern _glutSolidCube
extern _glutWireCube
extern _glutGameModeString
extern _glutEnterGameMode
extern _glutMouseFunc
extern _glutMotionFunc
extern _glutKeyboardFunc
extern _glutSpecialFunc
extern _glRasterPos2i
extern _glutBitmapCharacter
extern _glutGameModeGet
extern _glutLeaveGameMode