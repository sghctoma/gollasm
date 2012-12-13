gollasm
=======

An OpenGL/GLUT-based implementation of onway's Game of Life written in IA-32
assembly. I've written this for an assembly class at university years ago.
The program is written for OSX, but most of it should be usable on other
operating systems too. The code can be compiled with the following commands:

nasm -fmacho gollasm.s
gcc -m32 -framework GLUT -framework OpenGL -o gollasm gollasm.o

