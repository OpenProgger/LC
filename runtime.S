# Lambda Calculus Runtime
# r12: Heap ptr
# r13: Environment ptr

.globl _start, gen_closure, apply, get_val, set_var
_start:
	sub rsp, 4194304
	mov r12, rsp			# Heap: 4 MB
	xor r13, r13
	lea rdi, [rip + incr]	# Get address for Unchurchify function
	call gen_closure		# Create Unchurchify closure
	mov rdi, 0x2B			# '+'
	mov rsi, rax
	call set_var			# Bind Unchurchify to '+'
	mov rdi, 0x30			# '0'
	xor esi, esi
	call set_var			# Bind 0 constant to '0'
	call app				# Run compiled binary
	add rax, 0x30			# Convert to char
	push ax					# Call OS-Write
	mov eax, 1
	mov edi, eax
	mov rsi, rsp
	mov edx, eax
	syscall
	pop ax					# Call OS-Exit
	mov eax, 60
	xor rdi, rdi
	syscall

gen_closure:				# Create closure with catched environment variables from stack
	mov [r12], rdi			# Save call address
	mov [r12 + 8], r13		# Save current Environment
	mov rax, r12
	add r12, 16
	ret

apply:
	push r13
	mov rax, [rdi]
	mov r13, [rdi + 8]
	mov rdi, rsi
	call rax
	pop r13
	ret

set_var:					# Create new variable mapping for current Environment Frame
	mov [r12], dil
	mov [r12 + 1], rsi
	mov [r12 + 9], r13
	mov r13, r12
	add r12, 17
	ret

get_val:					# Get value of given variable
	mov rcx, r13			# Set iteration pointer
search_loop:
	test rcx, rcx
	jz search_exit
	mov al, [rcx]			# Take variable name
	cmp al, dil
	je search_loop_end		# Continue search if search criteria is not matching
	mov rcx, [rcx + 9]
	jmp search_loop
search_loop_end:
	mov rax, [rcx + 1]		# Return value from mapping
search_exit:
	ret

incr:						# Uncurchify function that increments a value by 1
	mov rax, rdi
	inc rax					# Increment and return
	ret
