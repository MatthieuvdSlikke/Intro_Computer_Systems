##
##  Van der Slikke Matthieu, 260662602 
##

.data  # start data segment with bitmapDisplay so that it is at 0x10010000
.globl bitmapDisplay # force it to show at the top of the symbol table
bitmapDisplay:    .space 0x80000  # Reserve space for memory mapped bitmap display
bitmapBuffer:     .space 0x80000  # Reserve space for an "offscreen" buffer
width:            .word 512       # Screen Width in Pixels, 512 = 0x200
height:           .word 256       # Screen Height in Pixels, 256 = 0x100

lineCount   :     .space 4        # int containing number of lines
lineData:         .space 0x4800   # space for teapot line data
lineDataFileName: .asciiz "teapotLineData.bin"
errorMessage:     .asciiz "Error: File must be in directory where MARS is started."

# TODO: declare other data you need or want here!


testMatrix: .float 
		1 2 3 4
		16 6 7 8
     		9 10 11 12
   		2 14 15 16
    	      	
testVec1: .float 1 0 0 0
testVec2: .float 0 1 0 0
testVec3: .float 0 0 1 0
testVec4: .float 0 0 0 1
testResult: .space 16


myVec: .space 16


M: .float
331.3682, 156.83034, -163.18181, 1700.7253
-39.86386, -48.649902, -328.51334, 1119.5535
0.13962941, 1.028447, -0.64546686, 0.48553467
0.11424224, 0.84145665, -0.52810925, 6.3950152


R: .float
0.9994, 0.0349, 0, 0
-0.0349, 0.9994, 0, 0
0, 0, 1, 0
0, 0, 0, 1 

.text
##################################################################
# main entry point
# We will use save registers here without saving and restoring to
# the stack only because this is the main function!  All other 
# functions MUST RESPECT REGISTER CONVENTIONS
main:	la 	$a0 lineDataFileName
	la 	$a1 lineData
	la 	$a2 lineCount
	jal 	loadLineData
	la 	$s0 lineData 				# keep buffer pointer handy for later
	la 	$s1 lineCount
	lw 	$s1 0($s1)	   			# keep line count handy for later

	
	
	# TODO: write your test code here, as well as your final 
	# animation loop.  We will likewise test individually 
	# the functions that you implement below.
	
	
         
 infinloop:
 	
		li 	$a0 0x00000000				
		jal 	clearBuffer
		move 	$a0 $s0
		move 	$a1, $s1 					
		jal 	draw3DLines
		jal 	copyBuffer	
		move 	$a0, $s0
		move 	$a1, $s1 
		jal 	rotate3DLines
		beq 	$zero $zero infinloop			
		li 	$v0, 10      
		syscall        
        
        

###############################################################
# void clearBuffer( int colour )

 clearBuffer:	
		la  	$t0,bitmapBuffer		# loads the address of the bitmapbuffer
		add 	$t1, $t0, 0x00080000 		# stores the address of the last pixel 
	
	
	loop: 	
		bge 	$t0, $t1, end			# while i< address of the last pixel
		sw 	$a0, 0($t0) 			# stores address of t0 into a0
		addi 	$t0, $t0, 4			# go to the next pixel
		j 	loop
		
		
	end:	
		jr 	$ra

###############################################################
# copyBuffer()
copyBuffer:	
		la  	$t0, bitmapBuffer 		# loads the address of the bitmapbuffer
		la  	$t1, bitmapDisplay 		# loads the address of the bitmapdisplay
		add  	$t2, $t0, 0x00080000		# stores the address of the last pixel 
	
			
	do:	
		bge  	$t0, $t2, done			# while i< address of the last pixel
		lw   	$t4, 0($t0)			# loads the content of pixel P from the bitmapbuffer
		sw  	$t4, 0($t1) 			# stores P to the bitmapDisplay
		addi 	$t0, $t0, 4			# go to the next pixel 
		addi	$t1, $t1, 4 			# go to the next pixel
		j 	do
		
		
	done:	jr 	$ra

###############################################################
# drawPoint( int x, int y ) 
drawPoint:	
		lw   	$t0, width			# loads width of 512
		lw   	$t1, height			# loads height of 256
		sltu 	$t2, $t0, $a0			# checks if x is less than the width
		beq  	$t2, 1, exit			# if x is bigger than the width go to end
		sltu 	$t3, $t1, $a1			# checks if y is less than the height
		beq  	$t3, 1, exit			# if y is bigger than the height go to end
		
		la   	$t4, bitmapBuffer		# loads the address of the bitmapbuffer
		mul  	$t0, $t0, $a1			# t0 = w*y
		add  	$t0, $t0, $a0			# t0 = x + w*y
		add  	$t0, $t0, $t0			# t0 = t0*2
		add  	$t0, $t0, $t0			# t0 = t0*4
		add  	$t0, $t0, $t4			# t0 = b + 4(x + w*y)
		
		li   	$t5, 0x0000ff00			# loads immidiate pixel
		sw   	$t5, 0($t0)			# draw point 
	
	
	exit:	jr	 $ra

###############################################################
# void drawline( int x0, int y0, int x1, int y1 )
     drawLine:	
		addi	$t0, $zero, 1 			# int offsetX = 1
		addi 	$t1, $zero, 1 			# int offsetY = 1
		sub  	$t3, $a2, $a0 			# int dX = x1 - x0
		sub  	$t4, $a3, $a1 			# int dY = y1 - y0
		
		slt  	$t2, $t3, $zero 		# if ( dX < 0 )
		beq  	$t2, $zero, next 		
		sub  	$t3, $zero, $t3 		# dX = -dX
		subi 	$t0, $zero, 1 			# offsetX = -1
			
	next: 	
		slt 	$t2, $t4, $zero			
		beq 	$t2, $zero, next2 		# if ( dY < 0 )
		sub  	$t4, $zero, $t4	 		# dY = -dY
		subi 	$t1, $zero, 1 			# offset y = -1

	next2: 	
		addi 	$sp, $sp, -20 			# create space for 5 words on stack
		sw   	$ra, 0($sp) 			# first store the return address
		sw   	$t0, 4($sp) 			# second store offsetX
		sw   	$t1, 8($sp) 			# third  store offsetY
		sw   	$t3, 12($sp)			# fourth store dX
		sw   	$t4, 16($sp)			# fifth  store dY
		
		jal 	drawPoint 			# draw point 
		
		lw   	$t4, 16($sp) 			# load back dY
		lw   	$t3, 12($sp)			# load back dx
		lw   	$t1, 8($sp) 			# load back offsetY
		lw   	$t0, 4($sp) 			# load back offsetX
		lw   	$ra, 0($sp) 			# load back the return address
		addi 	$sp, $sp, 20 
		
		
		slt  	$t2, $t4, $t3 			#  if (dX > dY)
		beq  	$t2, $zero, else 		
		add  	$t2, $t3, $zero 		# int error = dX
		beq 	$a0 $a2 finish
		
	while1: 		
		add  	$t7, $t4, $t4 			# 2*dY
		sub  	$t2, $t2, $t7 			# error = error - 2*dY
		slt  	$t7, $t2, $zero 		# if (error < 0)
		beq  	$t7, $zero, next3 		
		add 	$a1, $a1, $t1 			# y = y + offsetY
		add  	$t7, $t3, $t3 			# 2*dX
		add 	$t2, $t2, $t7 			# error = error + 2dX
		
				
	next3: 	add  	$a0, $a0, $t0 			# x = x + offsetX
		addi 	$sp, $sp, -24	
		sw   	$ra, 0($sp) 			
		sw   	$t0, 4($sp) 			
		sw   	$t1, 8($sp) 			
		sw   	$t2, 12($sp) 			# store error
		sw   	$t3, 16($sp)
		sw   	$t4, 20($sp)
			
		jal 	drawPoint 			# draw point 
			
		lw  	$t4, 20($sp) 			
		lw   	$t3, 16($sp)
		lw   	$t2, 12($sp)
		lw   	$t1, 8($sp) 			
		lw   	$t0, 4($sp) 			
		lw   	$ra, 0($sp) 			
		addi 	$sp, $sp, 24 			
				
		bne 	$a2, $a0, while1 		# while (x != x1)
		beq 	$zero, $zero, finish

	else: 
		add  	$t2, $t4, $zero 		# int error = dY
		beq  	$a1 $a3 finish
	
	while2: 		
	
		add  	$t7, $t3, $t3 			# 2*dX
		sub  	$t2, $t2, $t7 			# error = error - 2dX
		slt  	$t7, $t2, $zero 		
		beq  	$t7, $zero, next3bis 		# if (error < 0)
		add  	$a0, $a0, $t0 			# x = x + offsetX
		add  	$t7, $t4, $t4 			# 2*dY
		add  	$t2, $t2, $t7 			# error = error + 2dY
		
	next3bis: 	
		
		add  	$a1, $a1, $t1 			# y = y + offsetY
		addi 	$sp, $sp, -24
		sw   	$ra, 0($sp) 			
		sw   	$t0, 4($sp) 			
		sw   	$t1, 8($sp) 		
		sw   	$t2, 12($sp) 			
		sw   	$t3, 16($sp)
		sw   	$t4, 20($sp)
			
		jal 	drawPoint 			# draw point 
			
		lw   	$t4, 20($sp) 			
		lw   	$t3, 16($sp)
		lw   	$t2, 12($sp)
		lw   	$t1, 8($sp) 			
		lw   	$t0, 4($sp) 			
		lw   	$ra, 0($sp) 			
		addi 	$sp, $sp, 24 
		bne  	$a1, $a3, while2 		# (y != y1)
	
	
	finish: 
	
		jr 	$ra


###############################################################
# void mulMatrixVec( float* M, float* vec, float* result )
mulMatrixVec:
		lwc1  	$f1, 0($a0)		
		lwc1  	$f2, 0($a1)			# load first points
		mul.s 	$f3, $f1, $f2			# multiply them
		lwc1  	$f1, 4($a0)		
		lwc1  	$f2, 4($a1)			# load second points
		mul.s 	$f4, $f1, $f2			# multiply them
		add.s 	$f3, $f3, $f4			# add to the row the first result
		lwc1  	$f1, 8($a0)
		lwc1  	$f2, 8($a1)
		mul.s 	$f4, $f1, $f2		
		add.s 	$f3, $f3, $f4			# same procedure for third points
		lwc1  	$f1, 12($a0)
		lwc1  	$f2, 12($a1)
		mul.s 	$f4, $f1, $f2
		add.s 	$f3, $f3, $f4			# same procedure for fourth points
		swc1  	$f3, 0($a2)			# store the result in the vector
		
		
		addi  	$a0, $a0, 16			# same procedure for the second row
		
		lwc1  	$f1, 0($a0)		 
		lwc1  	$f2, 0($a1)
		mul.s 	$f3, $f1, $f2
		lwc1  	$f1, 4($a0)
		lwc1  	$f2, 4($a1)
		mul.s 	$f4, $f1, $f2		
		add.s 	$f3, $f3, $f4		
		lwc1  	$f1, 8($a0)
		lwc1  	$f2, 8($a1)
		mul.s 	$f4, $f1, $f2		
		add.s 	$f3, $f3, $f4		
		lwc1  	$f1, 12($a0)
		lwc1  	$f2, 12($a1)
		mul.s 	$f4, $f1, $f2
		add.s 	$f3, $f3, $f4
		swc1, 	$f3, 4($a2)
		
		
		addi  	$a0, $a0, 16			# same procedure for the third row
		
		lwc1  	$f1, 0($a0)		
		lwc1  	$f2, 0($a1)
		mul.s 	$f3, $f1, $f2
		lwc1  	$f1, 4($a0)
		lwc1  	$f2, 4($a1)
		mul.s 	$f4, $f1, $f2		
		add.s 	$f3, $f3, $f4		
		lwc1  	$f1, 8($a0)
		lwc1  	$f2, 8($a1)
		mul.s 	$f4, $f1, $f2		
		add.s 	$f3, $f3, $f4		
		lwc1  	$f1, 12($a0)
		lwc1  	$f2, 12($a1)
		mul.s 	$f4, $f1, $f2
		add.s 	$f3, $f3, $f4
		swc1  	$f3, 8($a2)
		
		
		addi  	$a0, $a0, 16			# same procedure for the third row
			
		lwc1  	$f1, 0($a0)		
		lwc1  	$f2, 0($a1)
		mul.s 	$f3, $f1, $f2
		lwc1  	$f1, 4($a0)
		lwc1  	$f2, 4($a1)
		mul.s 	$f4, $f1, $f2		
		add.s 	$f3, $f3, $f4		
		lwc1  	$f1, 8($a0)
		lwc1  	$f2, 8($a1)
		mul.s 	$f4, $f1, $f2		
		add.s 	$f3, $f3, $f4		
		lwc1  	$f1, 12($a0)
		lwc1  	$f2, 12($a1)
		mul.s 	$f4, $f1, $f2
		add.s 	$f3, $f3, $f4
		swc1  	$f3, 12($a2)
		subi  	$a0, $a0, 48
		
		jr 	$ra
        
###############################################################
# (int x,int y) = point2Display( float* vec )
point2Display:   

	        lwc1    $f1, 0($a0)		
		lwc1    $f2, 12($a0)		
		div.s   $f1, $f1, $f2 
		lwc1    $f3, 4($a0)
		div.s   $f3, $f3, $f2
		cvt.w.s $f0, $f1
		cvt.w.s $f4, $f3	
		mfc1    $v0, $f0
		mfc1    $v1, $f4

		     
	        jr 	$ra
        
###############################################################
# draw3DLines( float* lineData, int lineCount )
draw3DLines:	
		
		move  	$t0, $a1			# start to count the lines
		li    	$t1, 0				# line count = 0
		move  	$t2, $a0			# move the address of the line into t2
	
			
loop1:		addi 	$t1, $t1, 1 			# counter of the method
		addi 	$sp, $sp, -16			# create space for 6 words on stack
		sw   	$ra, 0($sp)			# store the return address
		sw   	$t0, 4($sp)			# store the number of lines
		sw   	$t1, 8($sp) 			# store the count of line
		sw   	$t2, 12($sp)			# store the address of lineData
		
		
		la 	$a0, M				# load M
		move 	$a1, $t2			# move the line data
		la 	$a2, testResult			# move a 16 bytes space to write the results
		
		
		jal 	mulMatrixVec
		
		
		lw   	$t2, 12($sp)			# load back the address of lineData
		lw   	$t1, 8($sp)			# load back count of line
		lw   	$t0, 4($sp) 			# load back number of lines
		lw   	$ra, 0($sp)			# load back return address
		addi 	$sp, $sp, 16			# bring back stack to original size
		
		la 	$a0, testResult			# load $a0 with result
		
		addi 	$sp, $sp, -16			# create space for 4 words on stack
		sw   	$ra, 0($sp)			# store the return address
		sw   	$t0, 4($sp)			# store the number of lines
		sw   	$t1, 8($sp) 			# store the count of line
		sw   	$t2, 12($sp)			# store the address of lineData
				
		jal 	point2Display			# change 4D to 2D
		
		lw   	$t2, 12($sp)			# load back the address of lineData
		lw   	$t1, 8($sp)			# load back count of line
		lw   	$t0, 4($sp) 			# load back number of lines
		lw   	$ra, 0($sp)			# load back return address
		addi 	$sp, $sp, 16			# bring back stack to original size
		
		move 	$t3, $v0			# move x0 to t3
		move 	$t4, $v1			# move y0 to t4
		
		addi  	$t2, $t2, 16			# go to the next points
		
		addi 	$sp, $sp, -24			# create space for 6 words on stack
		sw   	$ra, 0($sp)			# store the return address
		sw   	$t0, 4($sp)			# store the number of lines
		sw   	$t1, 8($sp) 			# store the count of line
		sw   	$t2, 12($sp)			# store the address of lineData
		sw   	$t3, 16($sp)			# store x0
		sw   	$t4, 20($sp)			# store y0
				
		la 	$a0, M
		move 	$a1, $t2
		la 	$a2, testResult
		
		jal 	mulMatrixVec
		
		lw   	$t4, 20($sp)			# load back y0
		lw   	$t3, 16($sp)			# load back x0
		lw   	$t2, 12($sp)			# load back the address of lineData
		lw   	$t1, 8($sp)			# load back count of line
		lw   	$t0, 4($sp) 			# load back number of lines
		lw   	$ra, 0($sp)			# load back return address
		addi 	$sp, $sp, 24			# bring back stack to original size
		
		la 	$a0, testResult			# load $a0 with result
		
		addi 	$sp, $sp, -24			# create space for 6 words on stack
		sw   	$ra, 0($sp)			# store the return address
		sw   	$t0, 4($sp)			# store the number of lines
		sw   	$t1, 8($sp) 			# store the count of line
		sw   	$t2, 12($sp)			# store the address of lineData
		sw   	$t3, 16($sp)			# store x0
		sw   	$t4, 20($sp)			# store y0
		
		jal 	point2Display			# go to second point
		
		lw   	$t4, 20($sp)			# load back y0
		lw   	$t3, 16($sp)			# load back x0
		lw   	$t2, 12($sp)			# load back the address of lineData
		lw   	$t1, 8($sp)			# load back count of line
		lw   	$t0, 4($sp) 			# load back number of lines
		lw   	$ra, 0($sp)			# load back return address
		addi 	$sp, $sp, 24			# bring back stack to original size
		
		move 	$a2, $v0			# move x1
		move 	$a3, $v1			# move y1
		move 	$a0, $t3			# store x0
		move 	$a1, $t4			# store y0
		
		addi 	$sp, $sp, -24			# create space for 6 words on stack
		sw   	$ra, 0($sp)			# store the return address
		sw   	$t0, 4($sp)			# store the number of lines
		sw   	$t1, 8($sp) 			# store the count of line
		sw   	$t2, 12($sp)			# store the address of lineData
		sw   	$t3, 16($sp)			# store x0
		sw   	$t4, 20($sp)			# store y0
		
		jal 	drawLine			# drawline
		
		lw   	$t4, 20($sp)			# load back y0
		lw   	$t3, 16($sp)			# load back x0
		lw   	$t2, 12($sp)			# load back the address of lineData
		lw   	$t1, 8($sp)			# load back count of line
		lw   	$t0, 4($sp) 			# load back number of lines
		lw   	$ra, 0($sp)			# load back return address
		addi 	$sp, $sp, 24			# bring back stack to original size
		
		slt  	$t3, $t1, $t0
		addi  	$t2, $t2, 16			# go to the next points
		bne  	$t3 ,$0, loop1 			# loop
		
                jr 	$ra


###############################################################
# rotate3DLines( float* lineData, int lineCount )
rotate3DLines:	
		move 	$t0, $a1
		li  	$t1, 0
		move 	$t2, $a0
		

loop3:		
		addi 	$t1, $t1, 1		# line counter 
		addi 	$sp, $sp, -16		
		sw   	$ra, 0($sp)		
		sw   	$t0, 4($sp)		
		sw   	$t1, 8($sp) 		
		sw   	$t2, 12($sp)			

		la   	$a0, R			# load R
		move 	$a1, $t2		
		move 	$a2, $t2		
		
		jal 	mulMatrixVec
		
		lw   	$t2, 12($sp)		
		lw   	$t1, 8($sp)		
		lw   	$t0, 4($sp) 		
		lw   	$ra, 0($sp)		
		addi 	$sp, $sp, 16		
		
		
		addi  	$t2, $t2, 16		
		addi 	$sp, $sp, -16		
		sw    	$ra, 0($sp)		
		sw    	$t0, 4($sp)		
		sw    	$t1, 8($sp) 		
		sw    	$t2, 12($sp)			

		la   	$a0, R			
		move 	$a1, $t2			
		move 	$a2, $t2			
		
		jal 	mulMatrixVec
		
		lw   	$t2, 12($sp)		
		lw   	$t1, 8($sp)		
		lw   	$t0, 4($sp) 		
		lw   	$ra, 0($sp)			
		addi 	$sp, $sp, 16		
		
		slt   	$t3, $t1, $t0
		addi  	$t2, $t2, 16		
		bne   	$t3 ,$0, loop3
		
		jr 	$ra 
      

        
###############################################################
# void loadLineData( char* filename, float* data, int* count )
#
# Loads the line data from the specified filename into the 
# provided data buffer, and stores the count of the number 
# of lines into the provided int pointer.  The data buffer 
# must be big enough to hold the data in the file being loaded!
#
# Each line comes as 8 floats, x y z w start point and end point.
# This function does some error checking.  If the file can't be opened, it 
# forces the program to exit and prints an error message.  While other
# errors may happen on reading, note that no other errors are checked!!  
#
# Temporary registers are used to preserve passed argumnets across
# syscalls because argument registers are needed for passing information
# to different syscalls.  Temporary usage:
#
# $t0 int pointer for line count,  passed as argument
# $t1 temporary working variable
# $t2 filedescriptor
# $t3 number of bytes to read
# $t4 pointer to float data,  passed as an argument
#

loadLineData:	move 	$t4 $a1 		# save pointer to line count integer for later	 # space for teapot line data	
		move 	$t0 $a2 		# save pointer to line count integer for later
			     			# $a0 is already the filename
		li 	$a1 0     		# flags (0: read, 1: write)
		li 	$a2 0     		# mode (unused)
		li 	$v0 13    		# open file, $a0 is null-terminated string of file name
		syscall				# $v0 will contain the file descriptor
		slt 	$t1 $v0 $0   		# check for error, if ( v0 < 0 ) error! 
		beq 	$t1 $0 skipError
		la 	$a0 errorMessage 
		li 	$v0 4    		# system call for print string
		syscall
		li 	$v0 10    		# system call for exit
		syscall
skipError:	move 	$t2 $v0			# save the file descriptor for later
		move 	$a0 $v0         	# file descriptor (negative if error) as argument for write
  		move 	$a1 $t0       		# address of buffer to which to write
		li  	$a2 4	    		# number of bytes to read
		li  	$v0 14          	# system call for read from file
		syscall		     		# v0 will contain number of bytes read
		
		lw 	$t3 0($t0)	     	# read line count from memory (was read from file)
		sll 	$t3 $t3 5  	     	# number of bytes to allocate (2^5 = 32 times the number of lines)			  		
		
		move 	$a0 $t2			# file descriptor
		move 	$a1 $t4			# address of buffer 
		move 	$a2 $t3    		# number of bytes 
		li  	$v0 14           	# system call for read from file
		syscall               		# v0 will contain number of bytes read

		move 	$a0 $t2			# file descriptor
		li  	$v0 16           	# system call for close file
		syscall		     	
		
		jr 	$ra        


