[BITS 32]

jmp poczatek

tekst db   'Teraz dziala program 2                                                          ', 0

poczatek:

mov ax, cs
mov es, ax
mov edi, tekst
call 115:25
call 123:25

jmp poczatek
