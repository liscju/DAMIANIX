
;struc KURSOR
;      .x                    resb    1
;      .y                    resb    1
;      .znak_kursora         resb    1
;      .atrybut              resb    1
;endstruc

USTAL_POCZATKOWE_PARAMETRY_EKRANU
;Procedura inicjalizuje struktur� kursor na pocz�tkowe warto�ci.
  pusha
  mov byte [kursor+KURSOR.x], 0
  mov byte [kursor+KURSOR.y], 0
  mov byte [kursor+KURSOR.znak_kursora], '_'
  mov byte [kursor+KURSOR.atrybut], 0fh
  popa
ret

MAZ_EKRAN
;Procedura wymazuje ekran
  pusha
  mov ax, fs
  push ax
  mov ax, [POLOZENIE_DESKRYPTORA_ADRESU_LINIOWEGO]
  mov fs, ax
  mov edi, 0B8000h
  mov ah, [kursor+ KURSOR.atrybut]
  mov al, ' '
  mov ecx, 80*25
  .petla:
    mov word [fs:edi], ax
    inc edi
    inc edi
  loop .petla
  pop ax
  mov fs, ax
  popa
ret

LINIA_W_DOL
;Procedura przewija ekran o jedn� lini� w d�. W tym celu kopiowana jest pami��
;od adresu 0B8000h+160 pod adres 0B8000h (160 bajt�w stanowi jedn� lini�).
  pusha
  mov ax, ds
  push eax
  mov ax, es
  push eax
  mov ax, 24
  mov ds, ax
  mov ax, [POLOZENIE_DESKRYPTORA_ADRESU_LINIOWEGO]
  mov ds, ax
  mov es, ax
  mov edi, 0B8000h
  mov esi, 0B8000h+80*2
  mov ecx, 80*24
  rep movsw
  mov ax, 24
  mov ds, ax
  mov ah, [kursor+ KURSOR.atrybut]
  mov al, ' '
  mov edi, 80*24*2+0b8000h
  mov ecx, 80
  rep stosw
  pop eax
  mov es, ax
  pop eax
  mov ds, ax
  popa
ret

WYSWIETL_ZNAK
;Procedura wy�wietla znak na ekranie w aktualnej pozycji kursora, po czym
;aktualizuje po�o�enie kursora.
;Parametry procedury:
;DL - kod ASCII znaku
  pusha
  mov ax, es
  push eax
  mov ax, ds
  push eax
  mov ax, 24
  mov ds, ax
  mov ax, [POLOZENIE_DESKRYPTORA_ADRESU_LINIOWEGO]
  mov es, ax
  mov edi, 0B8000h
;obliczenie przesuni�cia kursora wzgl�dem pocz�tku ekranu:
  mov eax, 80
  mul byte [kursor + KURSOR.y]
  mov bl, [kursor+KURSOR.x]
  movzx bx, bl
  add ax, bx
;gdy kursor znajduje si� w przedostatniej linii nast�puje przewini�cie ekranu w d�:
  cmp ax, 80*24
  jb .mniejsze
  call LINIA_W_DOL
  sub byte [kursor+KURSOR.y], 1
  sub ax, 80
  .mniejsze
  push eax
  shl ax, 1
  add edi, eax
;wy�wietlenie znaku i atrybutu na ekranie:
  mov [es:edi], dl
  inc edi
  mov al, [kursor+KURSOR.atrybut]
  mov [es:edi], al
;aktualizacja struktury kursor:
  pop eax
  inc ax
  push eax
  mov bl, 80
  div bl
  mov [kursor+KURSOR.y], al
  mov [kursor+KURSOR.x], ah
  pop eax
;ustawienie kursora na nowej pozycji:
  call USTAW_KURSOR_
  pop eax
  mov ds, ax
  pop eax
  mov es, ax
  popa
ret



SKASUJ_ZNAK
;Procedura kasuje ostatnio wpraowadzony znak oraz ustawia kursor na jego pozycji.
  pusha
  mov ax, es
  push eax
  mov ax, [POLOZENIE_DESKRYPTORA_ADRESU_LINIOWEGO]
  mov es, ax
  mov edi, 0B8000h
;Obliczenie przesuni�cia kursora wzgl�dem pocz�tku ekranu:
  mov eax, 80
  mul byte [kursor + KURSOR.y]
  mov bl, [kursor+KURSOR.x]
  movzx bx, bl
  add ax, bx
  cmp ax, 0
  jne .dalej
    jmp .koniec
  .dalej
  dec eax      ;pozycja znaku przed kursorem wzgl�dem pocz�tku ekranu
  push eax
  shl ax, 1
  add edi, eax
;Wykasowanie znaku:
  mov dl, ' '
  mov [es:edi], dl
  inc edi
  mov al, [kursor+KURSOR.atrybut]
  mov [es:edi], al
  pop eax
  push eax
;aktualizacja struktury kursor na nowe wsp�rz�dne:
  mov bl, 80
  div bl
  mov [kursor+KURSOR.y], al
  mov [kursor+KURSOR.x], ah
  pop eax
;ustawienie kursora na ekranie:
  call USTAW_KURSOR_
  .koniec:
  pop eax
  mov es, ax
popa
ret



NORMALIZACJA_PRZED_USTAWIENIEM_KURSORA
;Procedura liczy przesuni�cie kursora wzgl�dem pocz�tku ekranu.
   mov eax, 80
   mul byte [kursor + KURSOR.y]
   mov bl, [kursor+KURSOR.x]
   movzx bx, bl
   add ax, bx
RET

USTAW_KURSOR_
;Procedura ustala po�o�enie kursora na ekranie.
;Parametry procedury:
;AX - przesuni�cie kursora wzgl�dem pocz�tku ekranu.
  PUSHA
;Zapis odpowiednich warto�ci do port�w karty graficznej:
  mov dx, 03d4h  ;ustalenie portu rejestru adresowego
  push eax
  mov al, 14     ;wyb�r rejestru 14
  out dx, al
  pop eax
  xchg ah, al
  inc dx
  out dx, al     ;starszy bajt okre�laj�cy po�o�enie kursora
  xchg al, ah
  push eax
  dec dx
  mov al, 15    ;wyb�r rejestru 15
  out dx, al
  inc dx
  pop eax
  out dx, al    ;m�odszy bajt okre�laj�cy po�o�enie kursora
  
POPA
RET

USTAL_POZYCJE_KURSORA
;Procedura aktualizuje pola struktury kursor oraz oblicza offset wzgl�dem
;pocz�tku pami�ci tyrubu tekstowego, pod kt�rym znajduje si� kursor.
;Parametry procedury:
;BL - kolumna kursora,
;BH - wiersz kursora
;Wyniki:
;EDI - obliczony offset kursora wzgl�dem pocz�tku pami�ci trybu tekstowego.
  mov [kursor +KURSOR.x], bl
  mov [kursor +KURSOR.y], bh
  mov al, 80
  mul bh
  xor bh, bh
  add ax, bx
  shl ax, 1
  xor edi, edi
  mov di, ax
ret

OBLICZ_DLUGOSC_NAPISU
;Procedura szuka pierwszego bajtu r�wnego 0 i zwraca jego pozycj�.
;Parametry procedury:
;DS:ESI - adres ci�gu znak�w,
;Wyniki:
;AX - pozycja bajtu o warto�ci 0.
  xor ax, ax
  .petla:
    mov bl, [ds:esi]
    cmp bl, 0
    je .koniec
    inc ax
    inc esi
   jmp .petla
   .koniec:
ret

WYPISZ_TEKST_32:
;Procedura wypisuje tekst, zako�czony bajtem o warto�ci 0, na ekranie monitora.
;Parametry procedury:
;DS:ESI - adres ci�gu znak�w,
;AH - atrybut znak�w.
  add edi, 0B8000h
  .petla:
     mov al, [ds:esi]
     cmp al, 0
     je .koniec
     inc esi
     mov word [es:edi], ax
     inc edi
     inc edi
   jmp .petla
   .koniec:
ret

WYPISZ_LICZBE_DZIESIETNIE
;Procedura wypisuje na ekranie monitora liczb�.
;Parametry procedury:
;EAX - liczba do wypisania.
  PUSHA
  xor edx, edx
  mov ecx, 10
  mov ebp, esp
  .petla:
    div ecx
    push edx
    xor edx, edx
    cmp eax, 0
  jne .petla
  .wypisywanie_liczby
    pop edx
    add edx, 30h
    call WYSWIETL_ZNAK
    cmp ebp, esp
  jne .wypisywanie_liczby
  POPA
RET
