[BITS 32]

jmp poczatek

tekst db   'Teraz dziala program 1                                                          ', 0

poczatek:

mov ax, cs
mov es, ax
mov edi, tekst
call 107:25

jmp poczatek
