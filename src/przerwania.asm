Iczy db 0
ilosc db 10
LICZNIK_PRZERWAN DD 0

przerwanie0
;Procedura stanowi scheduler systemu operacyjnego
  pusha
  pushf
  mov ax, ds
  push eax
  mov ax, es
  push eax
;Zapis do DS selektora segmentu danych systemu:
  mov ax, 24
  mov ds, ax
;Zapis do ES selektora segmentu adresu liniowego:
  mov ax, 8
  mov es, ax
  cmp byte [nimo], 0  ;Sprawdzenie, czy wielozadaniowoœæ zosta³a zainicjalizowana
  je .dalej
;Sprawdzenie, czy nie nast¹pi rekursywne wywo³anie zadania:
  CALL ZWROC_ADRES_FIZYCZY_IDENTYFIKATORA_AKTUALNEGO_ZADANIA
  CALL PRZELACZ_ZADANIA   ;rotowanie kolejki zadañ
  cmp ecx, edi            ;porównanie ID zadania obecnie uruchomionego z ID
                          ;zadania uzyskanego na pierwszej pozycji kolejki zadañ.
  jne .zadania_sa_rozne
  ;W przypadku, gdy mia³oby nastêpiæ rekrusywne wywo³anie zadania:
  mov al, 60h
  out 20h, al
  jmp nie_mozna_przelaczyc_zadan_
  .zadania_sa_rozne
;Utworzenie dostêpu do identyfikatora procesu na podstawie jego adresu fizycznego:
  CALL OGOLNA_NORMALIZACJA_ADRESU
  PUSH EDI
;Przygotowanie odpowiedniej wartoœci selektora TSS w instrukcji prze³¹czenia zadania:
  mov di, [es:edi+IDENTYFIKATOR_PROCESU.SELEKTOR_TSS]
  mov [_SELEKTOR_], DI
  POP EDI
;Zmiana przestrzeni adresowej na przestrzeñ nale¿¹c¹ do zadania, na które
;nastêpi prze³¹czenie:
  mov edx, cr3
  mov ecx, [es:edi+IDENTYFIKATOR_PROCESU.CR3]
  mov cr3, ecx
 .dalej
  mov al, 60h
  out 20h, al
  cmp byte [nimo], 0
  je PRZERWANIE_ZEGARA_dalej2
;Instrukcja prze³¹czenia zadania:
  PREFIX          db 67h
  POLECENIE       db 0eah
  OFFSET          dd 12345
  _SELEKTOR_      dw 40h
;Przywrócenie przestrzeni adresowej:
  mov cr3, edx
  PRZERWANIE_ZEGARA_dalej2
  nie_mozna_przelaczyc_zadan_
  pop eax
  mov es, ax
  pop eax
  mov ds, ax
  popf
  popa
iret



%macro SPRAWDZ_BUFOR_KLAWIATURY 0
;Makro oczekuje na gotowoœæ kontrolera klawiatury.
  %%brak_gotowosci_klawiatury:
  in al, 64h
  mov ah, 00100001b
  and al, ah
  cmp al, 1
  jne %%brak_gotowosci_klawiatury
%endmacro

;TABLICE ZNAKÓW (pod pozycj¹ indeksowan¹ kodem matrycowym znajduje siê kod ASCII)
;                    0       1                     2                   3           4                       5                     6                   7                         8
;                    234567890123   4    5     678901234567   8    9   0123456789  0    1   2   3    4567890123   4 5 6  7   8 9 0 1 2 3 4 5 6 7 8 9 0  1 2 3 4 5 6 7 8  9     0 1 2  3
KLAWISZE1 db 0, 1bh,"1234567890-=", 08h, 09h, "qwertyuiop[]", 0dh, 0, "asdfghjkl;",39, "`", 0, "\", "zxcvbnm,./", 0,0,0," ", 0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,    0,0,0, 0

;                    0       1                     2                   3           4                       5                     6                   7           8
;                    234567890123   4    5     678901234567   8    9   0123456789  0    1   2   3    4567890123   4 5 6  7   8 9 0 1 2 3 4 5 6 7 8 9 0  123456789012   3

KLAWISZE2 db 0, 1bh,"!@#$%^&*()_+", 08h, 09h, "QWERTYUIOP{}", 0dh, 0, "ASDFGHJKL:",34, "~", 0, "|", "ZXCVBNM<>?", 0,0,0," ", 0,0,0,0,0,0,0,0,0,0,0,0,0,"789-456+1230", 0

INNY_PRZYCISK:
;Procedura ustala zmienn¹ stanu klawiatury na odpowiedni¹ wartoœæ,
;w zale¿noœci od przekazanego kodu klawisza.
  push ebx
  mov bx, es
  push ebx
  mov ebx, [POLOZENIE_DESKRYPTORA_DANYCH_KLAWIATURY]
  mov es, bx
  xor ebx, ebx

  cmp al, 29    ;wciœniêty ctrl
  jne .dalej1
    or byte [es:KLAWIATURA.BAJT_STANU_1], 100b
  jmp .koniec

  .dalej1:
  cmp al, 29+128 ;zwolniony ctrl
  jne .dalej2
    and byte [es:KLAWIATURA.BAJT_STANU_1], 11111011b
  jmp .koniec

  .dalej2:
  cmp al, 42  ;shift
  jne .dalej3
    or byte [es:KLAWIATURA.BAJT_STANU_1], 10b
  jmp .koniec
  
  .dalej3:
  cmp al, 42+128 ; shift
  jne .dalej4
    and byte [es:KLAWIATURA.BAJT_STANU_1],11111101b
  jmp .koniec

  .dalej4:
  cmp al, 54    ;shift
  jne .dalej5
    or byte [es:KLAWIATURA.BAJT_STANU_1], 1b
  jmp .koniec

  .dalej5:
  cmp al, 54+128 ;shift
  jne .dalej6
    and byte [es:KLAWIATURA.BAJT_STANU_1],11111110b
  jmp .koniec

  .dalej6
  cmp al, 56  ;alt
  jne .dalej7
    or byte [es:KLAWIATURA.BAJT_STANU_1], 1000b
  jmp .koniec

  .dalej7:
  cmp al, 56+128 ;alt
  jne .dalej8
    and byte [es:KLAWIATURA.BAJT_STANU_1],11110111b
  jmp .koniec

  .dalej8:
  cmp al, 70  ;scroll lock
  jne .dalej9
    or byte [es:KLAWIATURA.BAJT_STANU_1], 10000b
  jmp .koniec

  .dalej9:
  cmp al, 70+128 ;scroll lock
  jne .dalej10
    and byte [es:KLAWIATURA.BAJT_STANU_1],11101111b
  jmp .koniec
  
  .dalej10:
  cmp al, 69  ;num lock
  jne .dalej11
    or byte [es:KLAWIATURA.BAJT_STANU_1], 100000b
  jmp .koniec

  .dalej11:
  cmp al, 69+128 ;num lock
  jne .dalej12
    and byte [es:KLAWIATURA.BAJT_STANU_1],11011111b
  jmp .koniec
  
  .dalej12:
  cmp al, 58  ;caps lock
  jne .dalej13
    btc word [es:KLAWIATURA.BAJT_STANU_1], 6 ; neguje 7 bit
    clc
  jmp .koniec


  .dalej13:
  cmp al, 82  ;insert
  jne .dalej15
    or byte [es:KLAWIATURA.BAJT_STANU_1], 10000000b
  jmp .koniec

  .dalej15:
  cmp al, 82+128 ;insert
  jne .dalej16
    and byte [es:KLAWIATURA.BAJT_STANU_1],01111111b
  jmp .koniec
  
  .dalej16:
  cmp al, 128
  ja .koniec
  call WPROWADZ_DO_BUFORA
  .koniec:
  mov bl, [es:KLAWIATURA.BAJT_STANU_1]
  test bl, 10000000b
  jz .dalej
;W przypadku wykrycia wciœniêtego klawisza INSERT, nastêpuje wywo³anie
;procedy WCISNIETY_INSERT (uœpienie wszystkich zadañ):
  call WCISNIETY_INSERT
  .dalej
  test bl, 01000000b
  jz .dalejj
  test bl, 00001000b
  jz .dalejj
  test bl, 00000100b
  jz .dalejj
  call PROCEDURA_RESETU
  .dalejj
  pop ebx
  mov es, bx
pop ebx
ret

WCISNIETY_INSERT
;Procedura wywo³ywana w przypadku naciœniêcia klawisza INSERT
  pusha
  call USPANIE_WSZYSTKICH_ZADAN
  popa
RET

PROCEDURA_RESETU
  PUSHA
  MOV DL, '0'
  CALL WYSWIETL_ZNAK
  POPA
RET


PRZEPELNIENIE_BUFORA_KLAWIATURY
;Pusta procedura
RET

WPROWADZ_DO_BUFORA
;Procedura wprowadza do bufora klawiatury kod matrycowy oraz kod ASCII znaku.
;Parametry procedury:
;AX - kod matrycowy oraz kod ASCII znaku
  push eax
  push ebx
  mov bx, es
  push ebx
  mov bx, [POLOZENIE_DESKRYPTORA_DANYCH_KLAWIATURY]
  mov es, bx
  mov bl, [es:KLAWIATURA.WSKAZNIK_ZAPISU]
  mov bh, [es:KLAWIATURA.WSKAZNIK_ODCZYTU]
;Ustalenie nowej wartoœci wskaŸnika zapisu w buforze klawiatury:
  inc bl
  cmp bl, 32
  jne .dalej1
  xor bl, bl
  .dalej1:
  cmp bl, bh
  jne .dalej
  cmp bl, 0
  jne .dalej2
  mov bl, 32
  .dalej2:
  dec bl
  CALL PRZEPELNIENIE_BUFORA_KLAWIATURY
  jmp .koniec
  .dalej:
  and ebx, 0ffh
  mov [es:KLAWIATURA.BUFOR+ 2*ebx], ax     ;zapis do bufora klawiatury kodów klawisza
  mov [es:KLAWIATURA.WSKAZNIK_ZAPISU], bl  ;zapis zaktualizowanej wartoœci wskaŸnika zapisu
  .koniec:
  pop ebx
  mov es, bx
  pop ebx
  pop eax
ret

ODCZYTAJ_Z_BUFORA
;Procedura zwraca kod matrycowy i kod ASCII znaku z pierwszej nie odczytanej
;jeszcze pozycji bufora klawiatury.
;Wyniki:
;AX - kod matrycowy i kod ASCII znaku.
  CLI       ;Wy³¹czenie przerwañ (nie mo¿e nast¹piæ dodanie kolejnego znaku
            ;w trakcie wykonywania kodu procedury).
  push ebx
  mov bx, es
  push ebx
  mov bx, ds
  push ebx
  mov bx, 24
  mov ds, bx
  mov bx, [POLOZENIE_DESKRYPTORA_DANYCH_KLAWIATURY]
  mov es, bx
  mov bl, [es:KLAWIATURA.WSKAZNIK_ODCZYTU]
  mov bh, [es:KLAWIATURA.WSKAZNIK_ZAPISU]
  inc bh
  cmp bh, 32
  jne .dalej0
  xor bh, bh
  .dalej0
;Ustalenie nowej wartoœci wskaŸnika odczytu z bufora klawiatury:
  inc bl
  cmp bl, 32
  jne .dalej1
  xor bl, bl
  .dalej1:
  cmp bl, bh
  jne .dalej
  xor ax, ax
  jmp .koniec
  .dalej:
  and ebx, 0ffh
  mov ax, [es:KLAWIATURA.BUFOR+ 2*ebx]      ;Pobranie elementu bufora klawiatury do AX
  mov [es:KLAWIATURA.WSKAZNIK_ODCZYTU], bl  ;zapis zaktualizowanej wartoœci wskaŸnika odczytu.
  .koniec:
  pop ebx
  mov ds, bx
  pop ebx
  mov es, bx
  pop ebx
  STI
ret

%macro CZEKAJ_NA_WOLNY_BUFOR_WEJSCIOWY 0
  %%petla:
    in al, 64h
    test al, 10b
    jnz %%petla
%endmacro

%macro CZEKAJ_NA_WOLNY_BUFOR_WYJSCIOWY 0
  %%petla:
    in al, 64h
    test al, 1b
    jz %%petla
%endmacro

POBIERZ_REJESTR_STANU_KLAWIATYRY
;Procedura zwraca bajt stanu klawiatury.
;Parametry procedury:
;AH - numer bajtu stanu.
;Wyniki:
;AH - wartoœæ bajtu stanu.
  push esi
  push ebx
  mov bx, es
  push bx
  xor esi, esi
  movzx si, ah
  mov bx, [POLOZENIE_DESKRYPTORA_DANYCH_KLAWIATURY]
  mov es, bx
  mov ah, [es:KLAWIATURA.BAJT_STANU_1+esi]
  pop bx
  mov es, bx
  pop ebx
  pop esi
ret

przerwanie1:
;Procedura obs³ugi przerwania klawiatury.
  pusha
  pushf
  push eax
  push esi
  mov ax, ds
  push eax
  mov ax, es
  push eax
  mov ax, 24
  mov ds, ax
;Oczekiwanie na gotowoœæ kontrolera klawiatury:
  SPRAWDZ_BUFOR_KLAWIATURY
;Pobranie kodu matrycowego klawisza:
  in al, 60h
  cmp al, 2
  jb .inne
  cmp al, 82
  ja .inne
  xor esi, esi
  movzx si, al
  mov ah, 0    ; pierwszy rejestr stanu klawiatury
  call POBIERZ_REJESTR_STANU_KLAWIATYRY
;Okreœlenie tablicy, z której bêdzie odczytywany kod ASCII przyciœniêtego
;klawisza (dla wciœniêtych klawiszy: lewy shift, prawy shift, caps lock, bêdzie
;to tablica du¿ych liter):
  test ah, 1000011b
  jnz .wcisniety_shift
  mov ah, [KLAWISZE1+ esi]
  jmp .dalej
  .wcisniety_shift:
  mov ah, [KLAWISZE2+ esi]
  .dalej:
  cmp ah, 0
  jne .do_bufora
  .inne:
  mov bl, 0
  CALL INNY_PRZYCISK
  jmp .koniec
  .do_bufora:
;Wprowadzenie kodu matrycowego oraz kodu ASCII przyciœniêtego klawisza do
;bufora klawiatury:
  call WPROWADZ_DO_BUFORA
  .koniec:
;Zakoñczenie obs³ugi przerwania klawiatury:
  in al, 61h
  or al, 10000000b
  out 61h, al
  and al, 7fh
  out 61h, al
  pop eax
  mov es, ax
  pop eax
  mov ds, ax
  mov al, 61h
  out 20h, al
  pop esi
  pop eax
  popf
  popa
iret

przerwanie2
  .tututu:
  mov al, 62h
  out 20h, al
iret

przerwanie3
  .tututu:
  mov al, 63h
  out 20h, al
iret

przerwanie4
  .tututu:
  mov al, 64h
  out 20h, al
iret


przerwanie5
  .tututu:
  mov al, 65h
  out 20h, al
iret

przerwanie6
;Procedura obs³ugi przerwania stacji dyskietek.
;Po ka¿dym wyst¹pienie przerwania FDD nastêpuje zapisanie do zmiennej
;znacznik_przerwania_fdd wartoœci 1.
  pusha
  mov ax, ds
  push eax
  mov ax, 24
  mov ds, ax
  mov byte [znacznik_przerwania_fdd], 1
  mov al, 66h
  out 20h, al
  pop eax
  mov ds, ax
  popa
iret

przerwanie7
  .tututu:
  mov al, 67h
  out 20h, al
iret



INICJALIZUJ_KLAWIATURE
  CZEKAJ_NA_WOLNY_BUFOR_WEJSCIOWY
  MOV AL,0FAh	     	;Ustalenie typu klawiszy (typematic/make/break)
  OUT 60h,AL
  CZEKAJ_NA_WOLNY_BUFOR_WYJSCIOWY
  IN AL, 60h
  CZEKAJ_NA_WOLNY_BUFOR_WEJSCIOWY
  MOV AL,0F0h	     	;Ustalenie zbioru kodów matrycowych
  OUT 60h ,AL
  CZEKAJ_NA_WOLNY_BUFOR_WYJSCIOWY
  IN AL, 60h
  CZEKAJ_NA_WOLNY_BUFOR_WEJSCIOWY
  MOV AL,02h	     	;zbiór kodów matrycowych nr 2
  OUT 60h ,AL
  CZEKAJ_NA_WOLNY_BUFOR_WYJSCIOWY
  IN AL, 60h
  CZEKAJ_NA_WOLNY_BUFOR_WEJSCIOWY
  MOV AL,060h	     	;Polecenie komendy uk³adu 8042 (komenda zostanie przekazana przez port 60h)
  OUT 64h,AL
  CZEKAJ_NA_WOLNY_BUFOR_WEJSCIOWY
  MOV AL,45h	     	;Ustalenie trybu pracy klawiatury
  OUT 60h,AL
RET
