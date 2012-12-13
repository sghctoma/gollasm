GL_COLOR_BUFFER_BIT equ 0x4000
GL_DEPTH_BUFFER_BIT equ 0x0100
GL_PROJECTION equ 0x1701
GL_MODELVIEW equ 0x1700
GL_LEQUAL equ 0x203
GL_DEPTH_TEST equ 0xb71
GL_LIGHTING equ 0xb50
GL_LIGHT0 equ 0x4000
GL_SMOOTH equ 0x1d0
GL_FLAT equ 0x1D00
GL_QUADS equ 0x7
GL_COMPILE equ 0x1300

GL_BLEND equ 0x0BE2
GL_ZERO equ 0
GL_ONE equ 1
GL_SRC_COLOR equ 0x0300
GL_ONE_MINUS_SRC_COLOR equ 0x0301
GL_SRC_ALPHA equ 0x0302
GL_ONE_MINUS_SRC_ALPHA equ 0x0303
GL_DST_ALPHA equ 0x0304
GL_ONE_MINUS_DST_ALPHA equ 0x0305
GL_DST_COLOR equ 0x0306
GL_ONE_MINUS_DST_COLOR equ 0x0307
GL_SRC_ALPHA_SATURATE equ 0x0308

GL_LINE_SMOOTH equ 0x0B20
GL_LINE_SMOOTH_HINT equ 0x0C52
GL_DONT_CARE equ 0x1100

extern _gluPerspective
extern _gluOrtho2D

extern _glClearColor
extern _glClearDepth
extern _glDepthFunc
extern _glEnable
extern _glDisable
extern _glShadeModel
extern _glClear
extern _glLoadIdentity
extern _glMatrixMode
extern _glViewport
extern _glTranslatef
extern _glBegin
extern _glEnd
extern _glVertex3f
extern _glColor3f
extern _glColor4ub
extern _glColor3ub
extern _glGenLists
extern _glNewList
extern _glPushMatrix
extern _glPopMatrix
extern _glEndList
extern _glCallList
extern _gluLookAt
extern _glLineWidth
extern _glBlendFunc
extern _glHint
extern _glOrtho
extern _glRecti