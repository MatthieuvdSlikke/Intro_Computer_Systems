# VAN DER SLIKKE
# Matthieu
# 260662602

#Q1/ The base addresses of the image and the error buffers fall into the same block of the direct mapped because they have the same index
#Q2/ Yes, because it will have to change the values of the block thus taking more time
.data
displayBuffer:  .space 0x40000 # space for 512x256 bitmap display 
errorBuffer:    .space 0x40000 # space to store match function
templateBuffer: .space 0x100   # space for 8x8 template
imageFileName:    .asciiz "pxlcon512x256cropgs.raw" 
templateFileName: .asciiz "template8x8gs.raw"
# struct bufferInfo { int *buffer, int width, int height, char* filename }
imageBufferInfo:    .word displayBuffer  512 128  imageFileName
errorBufferInfo:    .word errorBuffer    512 128 0
templateBufferInfo: .word templateBuffer 8   8    templateFileName

.text
main:	la $a0, imageBufferInfo
	jal loadImage
	la $a0, templateBufferInfo
	jal loadImage
	la $a0, imageBufferInfo
	la $a1, templateBufferInfo
	la $a2, errorBufferInfo
	jal matchTemplateFast    # MATCHING DONE HERE
	la $a0, errorBufferInfo
	jal findBest
	la $a0, imageBufferInfo
	move $a1, $v0
	jal highlight
	la $a0, errorBufferInfo	
	jal processError
	li $v0, 10		# exit
	syscall
	

##########################################################
# matchTemplate( bufferInfo imageBufferInfo, bufferInfo templateBufferInfo, bufferInfo errorBufferInfo )
# NOTE: struct bufferInfo { int *buffer, int width, int height, char* filename }
matchTemplate:
		
		lw $a3, 0($a0)  # int* buffer
		lw $t1, 0($a1)	# address of templateBuffer
		lw $t2, 0($a2) # address of errorBuffe
		lw $a2, 4($a0) # int width
		lw $a1, 8($a0) # int height
		
		subi $a2, $a2, 7 # to compare in for loops
		subi $a1, $a1, 7 # to compare in for loops
		add $t3, $0, $0 # y= 0
		
LoopY:
		slt $t0, $t3, $a1  
		beq $zero, $t0, end #if y > height-7  then end loop for height of the image
		add $t4, $0, $0 # x = 0 
		
LoopX: 		
		slt $t0, $t4, $a2 
		beq $zero, $t0, endX #if x > width-7  then end inner loop for width of the image
		add $t5, $0, $0 # j = 0 
		add $v0, $0, $0 # SAD = 0 
		
LoopJ: 		
		slti $t0, $t5, 8
		beq $zero, $t0, endJ # if j>8  then end inner loop for the height of the template 
		add $t6, $0, $0 # i = 0 
		
LoopI: 		
		slti $t0, $t6, 8
		beq $zero, $t0, endI # if i>8  then end inner loop for the width of the template 
		
		addi $t7, $0, 4 # offset to 4 to get the pixel's data
		addi $t0, $a2, 7 # get the width of the image
		mul $t8, $t3, $t0 # y*w ( current height* width of the image)
		add $t8, $t4, $t8 # height offset + current width 
		
		mul $t9, $t5, $t0 # j*w ( current height of template* width of the image)
		add $t9, $t9, $t6 # offset (j*w + i) of template height + template width 
		
		add $t8, $t9, $t8 # add offsets of height and width together
		mul $t8, $t7, $t8 # pixel base*template offset
		add $t8, $t8, $a3 # offset of the pixel + buffer 
		lbu $t8, 0($t8) # load I[x+i][y+j]
		
		addi $t7, $0, 8 
		mul $t9 , $t5, $t7 #  height template * 8
		add $t9, $t9, $t6 #height offset + i  width of template
		addi $t7, $0, 4 
		mul $t9, $t9, $t7 # offset of width
		add $t9, $t9, $t1 # offset + address of the buffer 
		lbu $t9, 0($t9) #load T[i][j]
		
		subu $t8, $t8, $t9 # I[x+i][y+j] - T[i][j]
		abs $t8, $t8  # absolute value of substitution
		addu $v0, $t8, $v0 # add to SAD
		
		
		addi $t6, $t6, 1 # i=+1
		j LoopI
		

endI: 		
		addi $t5, $t5, 1 # j=+1
		j LoopJ

endJ: 		
		addi $t7, $a2, 7 # width of image x
		mul $t8, $t3, $t7 # y*width of image
		add $t8, $t4, $t8 #y*w + x
		add $t7, $0, 4 
		mul  $t8, $t7, $t8 # multiply by 4 to get width offset
		add $t8, $t2, $t8 # add the address of error buffer
		sw $v0, 0($t8) # store SAD into the address of error buffer
		addi $t4, $t4, 1 # x=+1
		j LoopX	
		
endX: 		
		addi $t3, $t3, 1 # y=+1
		j LoopY

end: 		jr $ra	

##########################################################
# matchTemplateFast( bufferInfo imageBufferInfo, bufferInfo templateBufferInfo, bufferInfo errorBufferInfo )
# NOTE: struct bufferInfo { int *buffer, int width, int height, char* filename }
matchTemplateFast:	
		
		addi $sp, $sp, -8
		sw $s0, 0($sp)
		sw $s1, 4($sp)
		add $a3, $0, $0 # j=0
		
LoopJF: 		
		slti $t0, $a3, 8 
		beq $zero, $t0, Finish  # if j>8 
		addi $t8, $0, 32
		mul $t8, $t8, $a3 #j*32
		lw $t0, 0($a1) #load address of template
		add $t8, $t0, $t8 #offset of j*32+ address of template
		lbu $t0, 0($t8) # load byte 
		lbu $t1, 4($t8) # load next pixel
		lbu $t2, 8($t8) 
		lbu $t3, 12($t8)
		lbu $t4, 16($t8) 		
		lbu $t5, 20($t8) 
		lbu $t6, 24($t8) 
		lbu $t7, 28($t8) # int t7 = T[7][j]
		add $v0, $0, $0 # y = 0
		
LoopYF:		
		lw $t8, 8($a0) # load height 
		sub $t8, $t8, 7 # height - 7
		slt $t8, $v0, $t8 
		beq $zero, $t8, endYF # if y>7
		add $v1, $0, $0 # x = 0 
		
LoopXF: 	
		lw $t8, 4($a0) # load width
		sub $t8, $t8, 7
		slt $t8, $v1, $t8 
		beq $zero, $t8, endXF # if x>7 
		
		lw $t8, 4($a0) # load width of buffer
		addi $s1, $0, 4
		
		add $t9, $v0, $a3 # add current height + width of template (y+j)
		mul $t9, $t8, $t9 # (y+j)*w
		add $t9, $t9, $v1 #(y+j)*w + x
		mul $t9, $t9, $s1 # ((y+j)*w + x) * 4
		
		mul $t8, $t8, $v0 # w*y
		add $t8, $t8, $v1 # (w*y) + x
		mul $t8, $t8, $s1 # ((w*y) + x)* 4 
		
		lw $s0, 0($a2) # load the address of the error buffer
		add $s0, $s0, $t8 # address of error buffer + ((w*y) + x)* 4, to store SAD
		
		lw $t8, 0($a0) # load the address of the image buffer
		lw $s1, 0($s0) # load SAD 
		
		add $t9, $t9, $t8 #add address of the image buffer + ((y+j)*w + x) * 4 , T[-][j]
		
		#SAD calculation
		
		lbu $t8, 0($t9) # load pixel 1 
		sub $t8, $t8, $t0 # substract t0
		abs $t8, $t8 # absolute value of result
		add $s1, $s1, $t8 # add to SAD
		
		lbu $t8, 4($t9) # load pixel 2
		sub $t8, $t8, $t1 
		abs $t8, $t8 
		add $s1, $s1, $t8 
		
		lbu $t8, 8($t9) # load pixel 3
		sub $t8, $t8, $t2 
		abs $t8, $t8 
		add $s1, $s1, $t8 
		
		lbu $t8, 12($t9) # load pixel 4
		sub $t8, $t8, $t3 
		abs $t8, $t8
		add $s1, $s1, $t8
		
		lbu $t8, 16($t9) # load pixel 5
		sub $t8, $t8, $t4 
		abs $t8, $t8 
		add $s1, $s1, $t8 
		
		lbu $t8, 20($t9) # load pixel 6
		sub $t8, $t8, $t5 
		abs $t8, $t8 
		add $s1, $s1, $t8 
		
		lbu $t8, 24($t9) # load pixel 7
		sub $t8, $t8, $t6 
		abs $t8, $t8 
		add $s1, $s1, $t8 
		
		lbu $t8, 28($t9) # load pixel 8
		sub $t8, $t8, $t7
		abs $t8, $t8 
		add $s1, $s1, $t8 
		
		sw $s1, 0($s0) # store the new SAD to s0
		addi $v1, $v1, 1 # x+=1
		j LoopXF
		
endXF : 	
		addi $v0, $v0, 1 # y+=1
		j LoopYF

endYF:		
		addi $a3, $a3, 1 # j+=1
		j LoopJF 
		
Finish : 	
		lw $s0, 0($sp)
		lw $s1, 4($sp) #restore stack
		add $sp, $sp, 8
		jr $ra	

	
	
	
###############################################################
# loadImage( bufferInfo* imageBufferInfo )
# NOTE: struct bufferInfo { int *buffer, int width, int height, char* filename }
loadImage:	lw $a3, 0($a0)  # int* buffer
		lw $a1, 4($a0)  # int width
		lw $a2, 8($a0)  # int height
		lw $a0, 12($a0) # char* filename
		mul $t0, $a1, $a2 # words to read (width x height) in a2
		sll $t0, $t0, 2	  # multiply by 4 to get bytes to read
		li $a1, 0     # flags (0: read, 1: write)
		li $a2, 0     # mode (unused)
		li $v0, 13    # open file, $a0 is null-terminated string of file name
		syscall
		move $a0, $v0     # file descriptor (negative if error) as argument for read
  		move $a1, $a3     # address of buffer to which to write
		move $a2, $t0	  # number of bytes to read
		li  $v0, 14       # system call for read from file
		syscall           # read from file
        		# $v0 contains number of characters read (0 if end-of-file, negative if error).
        		# We'll assume that we do not need to be checking for errors!
		# Note, the bitmap display doesn't update properly on load, 
		# so let's go touch each memory address to refresh it!
		move $t0, $a3	   # start address
		add $t1, $a3, $a2  # end address
loadloop:	lw $t2, ($t0)
		sw $t2, ($t0)
		addi $t0, $t0, 4
		bne $t0, $t1, loadloop
		jr $ra
		
		
#####################################################
# (offset, score) = findBest( bufferInfo errorBuffer )
# Returns the address offset and score of the best match in the error Buffer
findBest:	lw $t0, 0($a0)     # load error buffer start address	
		lw $t2, 4($a0)	   # load width
		lw $t3, 8($a0)	   # load height
		addi $t3, $t3, -7  # height less 8 template lines minus one
		mul $t1, $t2, $t3
		sll $t1, $t1, 2    # error buffer size in bytes	
		add $t1, $t0, $t1  # error buffer end address
		li $v0, 0		# address of best match	
		li $v1, 0xffffffff 	# score of best match	
		lw $a1, 4($a0)    # load width
        		addi $a1, $a1, -7 # initialize column count to 7 less than width to account for template
fbLoop:		lw $t9, 0($t0)        # score
		sltu $t8, $t9, $v1    # better than best so far?
		beq $t8, $zero, notBest
		move $v0, $t0
		move $v1, $t9
notBest:		addi $a1, $a1, -1
		bne $a1, $0, fbNotEOL # Need to skip 8 pixels at the end of each line
		lw $a1, 4($a0)        # load width
        		addi $a1, $a1, -7     # column count for next line is 7 less than width
        		addi $t0, $t0, 28     # skip pointer to end of line (7 pixels x 4 bytes)
fbNotEOL:	add $t0, $t0, 4
		bne $t0, $t1, fbLoop
		lw $t0, 0($a0)     # load error buffer start address	
		sub $v0, $v0, $t0  # return the offset rather than the address
		jr $ra
		

#####################################################
# highlight( bufferInfo imageBuffer, int offset )
# Applies green mask on all pixels in an 8x8 region
# starting at the provided addr.
highlight:	lw $t0, 0($a0)     # load image buffer start address
		add $a1, $a1, $t0  # add start address to offset
		lw $t0, 4($a0) 	# width
		sll $t0, $t0, 2	
		li $a2, 0xff00 	# highlight green
		li $t9, 8	# loop over rows
highlightLoop:	lw $t3, 0($a1)		# inner loop completely unrolled	
		and $t3, $t3, $a2
		sw $t3, 0($a1)
		lw $t3, 4($a1)
		and $t3, $t3, $a2
		sw $t3, 4($a1)
		lw $t3, 8($a1)
		and $t3, $t3, $a2
		sw $t3, 8($a1)
		lw $t3, 12($a1)
		and $t3, $t3, $a2
		sw $t3, 12($a1)
		lw $t3, 16($a1)
		and $t3, $t3, $a2
		sw $t3, 16($a1)
		lw $t3, 20($a1)
		and $t3, $t3, $a2
		sw $t3, 20($a1)
		lw $t3, 24($a1)
		and $t3, $t3, $a2
		sw $t3, 24($a1)
		lw $t3, 28($a1)
		and $t3, $t3, $a2
		sw $t3, 28($a1)
		add $a1, $a1, $t0	# increment address to next row	
		add $t9, $t9, -1		# decrement row count
		bne $t9, $zero, highlightLoop
		jr $ra

######################################################
# processError( bufferInfo error )
# Remaps scores in the entire error buffer. The best score, zero, 
# will be bright green (0xff), and errors bigger than 0x4000 will
# be black.  This is done by shifting the error by 5 bits, clamping
# anything bigger than 0xff and then subtracting this from 0xff.
processError:	lw $t0, 0($a0)     # load error buffer start address
		lw $t2, 4($a0)	   # load width
		lw $t3, 8($a0)	   # load height
		addi $t3, $t3, -7  # height less 8 template lines minus one
		mul $t1, $t2, $t3
		sll $t1, $t1, 2    # error buffer size in bytes	
		add $t1, $t0, $t1  # error buffer end address
		lw $a1, 4($a0)     # load width as column counter
        		addi $a1, $a1, -7  # initialize column count to 7 less than width to account for template
pebLoop:		lw $v0, 0($t0)        # score
		srl $v0, $v0, 5       # reduce magnitude 
		slti $t2, $v0, 0x100  # clamp?
		bne  $t2, $zero, skipClamp
		li $v0, 0xff          # clamp!
skipClamp:	li $t2, 0xff	      # invert to make a score
		sub $v0, $t2, $v0
		sll $v0, $v0, 8       # shift it up into the green
		sw $v0, 0($t0)
		addi $a1, $a1, -1        # decrement column counter	
		bne $a1, $0, pebNotEOL   # Need to skip 8 pixels at the end of each line
		lw $a1, 4($a0)        # load width to reset column counter
        		addi $a1, $a1, -7     # column count for next line is 7 less than width
        		addi $t0, $t0, 28     # skip pointer to end of line (7 pixels x 4 bytes)
pebNotEOL:	add $t0, $t0, 4
		bne $t0, $t1, pebLoop
		jr $ra
