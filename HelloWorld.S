.section .data
helloworld: .asciz "Hello BS23B015! Welcome to CS3500\n"

.section .text
.global main

#main cause it's not on bare metal! 
main:
  addi a0, x0, 1        # create a file descriptor with I think 1 (stdout), What is this stdout exactly for? Probably to specify how the output should be like
  la   a1, helloworld   # Set the address of string as an ASCI value, is the stdout 1 for displaing the number-> asci conv? Pretty sure!
  addi a2, x0, 50       # length of string, yeah: More the better!
  addi a7, x0, 16       # we invoke a syscall number for write, this is a linux call and I think we call upon linux for executing this? No look for XV6 syscall
  ecall                 # Ecall to invoke system call
  #ret
  addi a0, x0, 0        # But doesn't the print statement auto-exit? Because it would inf loop, and go back to main! the exit code is 0 refer syscal...
  addi a7, x0, 2      # syscall number for exit
  #invoke system call, why 2 syscalls?
  ecall               

#An alternate approach using the printf function: Interesting method by using the stack to store the return value!  
#main: 
#  add sp,sp,-32 it's adding 32 to the stack
#  sd ra,0(sp), storing it in the stack
#  la a0 , helloworld
#  call printf , call printf as defined in the os
#  ld ra,0(sp) 
#  add sp,sp,32 back to where we should be
#  # ret       return!    