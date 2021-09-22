# Minimal Lambda Calculus Compiler

Supports only single char symbols, except 'l' which stands for a lambda function

Compile Compiler: clang -nostartfiles -nodefaultlibs -masm=intel -static x86.S -o LC

Compile lambda calculus: cat input | ./LC > output.S

Create final binary: clang -nostartfiles -nodefaultlibs -masm=intel -static output.S runtime.S
