# Lambda Calculus Compiler(x86 port)
# r12: Heap Ptr
# r13: Label Counter

.globl _start
.text
_start:
	sub rsp, 4194304
	mov r12, rsp					# Heap: 4 MB
	xor r13, r13					# Reset label counter
	lea rdi, [rip + prefix]			# Output Header
	call print_instr
	call get_token					# Fetch first token
	cmp rax, 0x28					# '('
	jne take_token					# Fetch list if available
	call get_list
take_token:
	mov rdi, rax					# Take token otherwise
	call compile					# Compile AST
	lea rdi, [rip + ret_instr]		# Programm reached end
	call print_instr
	mov eax, 60						# Exit compiler
	xor edi, edi
	syscall

get_token:							# Fetch valid char
	call read						# Read byte
	cmp al, 0x20					# ' '
	je get_token
	cmp al, 0xA						# '\n'
	je get_token					# Skip if whitespace
	ret

get_list:							# Create list from elements
	call get_token					# Get first element
	cmp rax, 0x29					# ')'
	jne list_cont					# Empty list?
	xor eax, eax
	ret
list_cont:
	cmp rax, 0x28					# '('
	jne take_sym					# Fetch nested list if available
	call get_list
take_sym:
	push rax						# Take element otherwise
	call get_list					# Get second element
	pop rdi
	mov rsi, rax
	mov rax, r12					# Save address to new list
	add r12, 16
	mov [rax], rdi					# Set first element
	mov [rax + 8], rsi				# Set second element
	ret

compile:							# Compile AST to assembly
	mov eax, 0xFF
	or rax, rdi
	cmp rax, 0xFF
	jne compile_lambda				# Check if address, otherwise Symbol
	push rdi
	lea rdi, [rip + mov_rdi]		# Query value from variable
	call print_instr
	pop rdi
	call print_num
	mov rdi, 0xA
	call write
	lea rdi, [rip + call_get_val]
	call print_instr
	ret
compile_lambda:
	mov rax, [rdi]
	cmp rax, 0x6C
	jne compile_call				# Check for lambda
	push rdi
	lea rdi, [rip + call_L]			# Skip function body
	call print_instr
	mov rdi, r13					# Take Label Number
	inc r13
	push rdi
	call print_num
	mov rdi, 0xA
	call write
	lea rdi, [rip + mov_rsi_rdi]	# New value
	call print_instr
	lea rdi, [rip + mov_rdi]		# Take parameter name
	call print_instr
	mov rdi, [rsp + 8]
	mov rdi, [rdi + 8]
	mov rdi, [rdi]
	mov rdi, [rdi]
	call print_num
	mov rdi, 0xA
	call write
	lea rdi, [rip + call_set_var]	# Create new Mapping
	call print_instr
	pop rsi
	pop rdi
	push rsi
	mov rdi, [rdi + 8]
	mov rdi, [rdi + 8]
	mov rdi, [rdi]
	call compile					# Compile function body
	lea rdi, [rip + ret_instr]		# Close function
	call print_instr
	mov rdi, 0x4C					# Create Label for skipping
	call write
	pop rdi
	call print_num
	mov rdi, 0x3A
	call write
	mov rdi, 0xA
	call write
	lea rdi, [rip + pop_rdi]		# Get return address
	call print_instr
	lea rdi, [rip + call_gen_closure]# Create new closure with given free variables and address
	call print_instr
	ret
compile_call:
	push rdi
	mov rdi, [rdi]
	call compile					# Compile parameter
	lea rdi, [rip + push_rax]		# Save result
	call print_instr
	pop rdi
	mov rdi, [rdi + 8]
	mov rdi, [rdi]
	call compile					# Compile body
	lea rdi, [rip + fun_call]		# Call result
	call print_instr
	ret

print_instr:						# Print instruction from string
	xor eax, eax
	mov al, [rdi]					# Take char from buffer
	test al, al
	jz print_instr_end				# Terminate on 0
	push rdi						# Preserve buffer address
	mov edi, eax
	call write						# Print char
	pop rdi							# Restore buffer address
	inc rdi							# Move to next char
	jmp print_instr
print_instr_end:
	ret

print_num:							# Print decimal number to output
	xor cl, cl						# Clear flag
	mov rax, rdi
	mov bx, 100
	xor edx, edx
	div bx							# number / 100
	test ax, ax
	jz skip_100						# Skip print if number has less than 3 digits
	push rdx
	mov rdi, 0x31					# Print digit
	call write
	pop rdx
	inc cl							# Set flag if print occured
skip_100:
	mov rax, rdx
	mov bx, 10
	xor rdx, rdx
	div bx							# number / 10
	test cl, cl
	jnz write_10					# Don't skip print if it already occured
	test ax, ax						# Skip if number is 1 digit long
	jz skip_10
write_10:
	add rax, 0x30					# Print digit
	mov rdi, rax
	push rdx
	call write
	pop rdx
skip_10:
	add rdx, 0x30					# Print last digit
	mov rdi, rdx
	call write
	ret

read:								# OS-Read
	xor eax, eax
	xor edi, edi
	push ax
	mov rsi, rsp
	mov edx, 1
	syscall
	pop ax
	ret

write:								# OS-Write
	push rdi
	mov eax, 1
	mov edi, eax
	mov rsi, rsp
	mov edx, eax
	syscall
	pop rdi
	ret

.rodata
prefix:
.ascii ".globl app\n"
.asciz "app:\n"
ret_instr:
.asciz "ret\n"
mov_rdi:
.asciz "mov rdi, "
call_get_val:
.asciz "call get_val\n"
call_L:
.asciz "call L"
mov_rsi_rdi:
.asciz "mov rsi, rdi\n"
call_set_var:
.asciz "call set_var\n"
pop_rdi:
.asciz "pop rdi\n"
call_gen_closure:
.asciz "call gen_closure\n"
push_rax:
.asciz "push rax\n"
fun_call:
.ascii "pop rdi\n"
.ascii "mov rsi, rax\n"
.asciz "call apply\n"
