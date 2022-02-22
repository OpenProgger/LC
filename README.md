# Minimal Lambda Calculus Compiler

Supports only single char symbols, except 'l' which stands for a lambda function.
'+' is used as unchirchifier function to make some simple calculations.

Compile Compiler:  
```
clang -static compiler.c -o LC
```
If interested, bootstrap.S is a assembly-version of compiler.c

Compile lambda calculus:  
```
cat input | ./LC > output.S
```

Create final binary:  
```
clang -nostartfiles -nodefaultlibs -masm=intel -static output.S runtime.S
```

The sample input file is copied from [Matt's Blog](https://matt.might.net/articles/compiling-up-to-lambda-calculus/) for testing.
Use a debugger to test the result of the 'app' function if it returns 120 (which means the lambda was compiled correctly).
