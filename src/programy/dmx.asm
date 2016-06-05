[BITS 32]
jmp poczatek

damianix db   '     *****      ***       ***  ***     ***    ***    ***  ***  ***  **  **      '
         db   '     *** **    ** **     ** **** **    ***   ** **   **** ***  ***   ****       '
         db   '     ***  **  *** ***   **   **   **   ***  *** ***  ********  ***    **        '
         db   '     *** **   *******  ***   **   ***  ***  *******  *** ****  ***   ****       '
         db   '     *****    *** ***  ***        ***  ***  *** ***  ***  ***  ***  **  **      '
         db   '                                                                                '
         db  0
         
poczatek:

mov edi, damianix
mov ax, cs
mov es, ax
call 107:25

petla_skakania
jmp petla_skakania

