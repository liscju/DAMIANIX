 [BITS 16]
jmp poczatek
db 0
;Poni�sza tablica musi znajdowa� si� pod parzystym adresem (identyfikator
;zadania g��wnego):
jadro                       times 170 db 0;istruc IDENTYFIKATOR_PROCESU
;Zmienne zwi�zane z inicjalizacj� linii A20:
FAST_A20                    DB 0
A20                         db 0

czy_juz_mozna db 0

;Makra aktywuj�ce lini� A20:
%macro CZY_DOSTEPNY_FAST_A20 0
  MOV AX, 2403H
  INT 15H
  JC %%BRAK_A20
  CMP AH, 0
  JNE %%BRAK_A20
  TEST BX, 2
  JZ %%BRAK_A20
    MOV byte [FAST_A20], 1
  JMP %%KONIEC_A20
  %%BRAK_A20:
    MOV byte [FAST_A20], 0
  %%KONIEC_A20:
%endmacro

%macro CZY_A20 0
  PUSH AX
  PUSH BX
  mov ax, es
  push ax
  
  mov dx, 0
  mov es, dx
  MOV AL, [es:0]
  MOV BL, AL
  NOT BL
  mov dx, 0ffffh
  mov es, dx
  XCHG BL, [es:10H]
  mov dx, 0
  mov es, dx
  CMP AL, [es:0]
  mov dx, 0ffffh
  mov es, dx
  MOV [es:10H], BL
  pop ax
  mov es, ax
  POP BX
  POP AX
%endmacro

%macro A20_ON 0
;Czy a20 ju� aktywne:
  mov ax, 2401h
  int 15h
  MOV byte [A20],0
  CZY_A20
  JNE %%dalll
  jmp %%KONIEC_A20
%%dalll:
  CMP byte [FAST_A20], 1
  JNE %%BRAK_FAST_A20
;Fast a20:
  MOV byte [A20], 1
  IN AL, 92H
  OR AL, 2
  AND AL, 0FEH
  OUT 92H, AL
 CZY_A20
  JE %%KONIEC_A20
  %%BRAK_FAST_A20:
;Uaktywnienie a20 poprzez sterownik klawiatury:
;Oczekiwanie na pusty bufor wej�ciowy:
  XOR AX, AX
  %%PETLA1_A20:
    IN AL, 64H
    BTR AX, 1
  JC %%PETLA1_A20
;Wys�anie komendy odczytu portu wyj�ciowego:
  MOV AL, 0D0H    		;Rozkaz odczytu portu wyj�ciowego.
  OUT 64H, AL
  XOR AX, AX
  %%PETLA2_A20:
    IN AL, 64H
    BTR AX, 0     		;Stan bufora wyj�ciowego (0 pusty, 1 dane s� jeszcze w buforze).
  JNC %%PETLA2_A20
;Odczyt stanu portu wyj�ciowego:
  XOR AX, AX
  IN AL, 60H
  PUSH AX
  %%PETLA3_A20:
    IN AL, 64H
    BTR AX, 1     		;Oczekiwanie na pusty bufor wej�ciowy.
  JC %%PETLA3_A20
;Komenda zapisu do portu wyj�ciowego:
  MOV AL, 0D1H  		;Rozkaz zapisu portu wyj�ciowego.
  OUT 64H, AL
  %%PETLA4_A20:
    XOR AX, AX
    IN AL, 64H
    BTR AX, 1    		;Oczekiwanie na pusty bufor wej�ciowy.
  JC %%PETLA4_A20
;Zapis portu wyj�ciowego:
  POP AX
  OR AL, 10B
  OUT 60H, AL
  MOV byte [A20], 2
  CZY_A20
  JE %%KONIEC_A20
; ...
    MOV AX, 2401H
    INT 15H

  %%KONIEC_A20:
%endmacro

WYPISZ_TEKST:
; Procedura wykorzystywana na samym pocz�tku, by wy�wietli� komunikat, �e
; j�dro zosta�o za�adowane.
  push bx

  xor bh, bh
  mov bl, 07h
  mov si, dx				;Zapis offsetu tekstu do SI
  mov ah, 0eh
  petla1_1:
    mov al, [si]
    cmp al, 0
    je end_petla1_1			;Po napotkaniu bajtu r�wnego 0 nast�puje koniec
    int 10h
    inc si
  jmp petla1_1
  end_petla1_1:
  pop bx
RET

ZALADUJ_DESKRYPTOR
; Parametry procedury:
; ES:0 - adres globalnej tablicy deskryptor�w,
; Zmienna OFFSET_GDT - offset w GDT,
; Zmienna deskryptor - warto�� odk�adanego deskryptora.
; Procedura odk�ada zawarto�� zmiennej deskryptora pod adres
; okre�lony rejestrem ES oraz zmienn� OFFSET_GDT.
  xor esi, esi
  xor edi, edi
  mov si, deskryptor
  mov di, [OFFSET_GDT]
  movsd
  movsd
  mov ax, [OFFSET_GDT]
  add ax, 8h
  mov [OFFSET_GDT], ax
ret

ROZMIAR_I_ADRES_DESKRYPTORA
; Parametry procedury:
; EAX - rozmiar segmentu,
; EBX - adres bazowy segmentu.
; Procedura wype�nia pola adresu bazowego oraz limitu w deskryptorze segmentu.
  mov [deskryptor + DESKRYPTOR.LIMIT1], ax
  shr eax, 10h
  mov cl, [deskryptor+DESKRYPTOR.PARAMETR2]
  and cl, 11110000b
  or al, cl
  mov [deskryptor+DESKRYPTOR.PARAMETR2], al

  mov [deskryptor+DESKRYPTOR.BAZA1], bx
  shr ebx, 10h
  mov [deskryptor+DESKRYPTOR.BAZA2], bl
  mov [deskryptor+DESKRYPTOR.BAZA3], bh
ret

TYP_DESKRYPTORA
; Parametry procedury:
; Atrybuty segmentu przekazywane procedurze w rejestrach AL oraz AH.
; Procedura wype�nia pola atrybut�w w deskryptorze segmentu.
   mov [deskryptor+DESKRYPTOR.PARAMETR1], al
   mov al, [deskryptor+DESKRYPTOR.PARAMETR2]
   and al, 00001111b
   and ah, 11110000b
   or al, ah
   mov [deskryptor+DESKRYPTOR.PARAMETR2], al
ret

WYMAZ_GDT
; Parametry procedury:
; ES:0 - adres GDT.
; Procedura wype�ni bajtami r�wnymi 0 obszar GDT.
push cx
push di
  xor di, di
  mov cx, 0ffffh
  .petla_wymazywania_gdt
    mov byte[es:di], 0
    inc di
  loop .petla_wymazywania_gdt
pop di
pop cx
RET

ROZMIAR_I_ADRES_DTR
; Parametry procedury:
; AX - Rozmiar tablicy deskryptor�w (GDTR, LDTR, IDTR),
; EBX - Adres tablicy deskryptor�w.
; Wyniki:
; Zmienna dtr - wype�niony pseudodeskryptor tablicy deskryptor�w.
  mov [dtr+DTR.LIMIT], ax
  mov [dtr+DTR.BAZA], ebx
ret

struc KURSOR
      .x                    resb    1
      .y                    resb    1
      .znak_kursora         resb    1
      .atrybut              resb    1
endstruc

kursor times 4 db 0
KERNEL_ZALADOWANY   DB  'KERNEL ZOSTAL ZALADOWANY', 13, 10, 0
OFFSET_GDT  DW  0
deskryptor                  times 8 db 0
dtr                         times 6 db 0
kolejka_zadan               times 12 db 0
kolejka_zadan_wstrzymanych  times 12 db 0

zadanie0                    times 200 db 0
zadanie1                    times 170 db 0;istruc IDENTYFIKATOR_PROCESU
zadanie2                    times 170 db 0;istruc IDENTYFIKATOR_PROCESU

id_interpretatora           dd    0

zadanie_1                    times 104 db 0
zadanie_2                    times 104 db 0
jadro_                       times 104 db 0

tabela_zapisu                times 4096   db 0ffh

POLOZENIE_DESKRYPTORA_KODU     DW        0
POLOZENIE_DESKRYPTORA_DANYCH   DW        0
POLOZENIE_STOSU    DW        0
POLOZENIE_DESKRYPTORA_ADRESU_LINIOWEGO   DW     0
POLOZENIE_DESKRYPTORA_TABLICY_PRZERWAN   DW     0
POLOZENIE_DESKRYPTORA_KATALOGU_STRON     DW     0
POLOZENIE_DESKRYPTORA_DANYCH_KLAWIATURY  DW     0
POLOZENIE_TABLICY_STRON                  DD     55000h; 100000h
POLOZENIE_KATALOGU_STRON                 DD     5F000h
KONIEC_TABLICY_STRON                     DD     0h
NAPIS  db 'System dziala w trybie chronionym.',0
STRONICOWANIE     DB     'SYSTEM WLACZYL OBSLUGE STRONICOWANIA', 0
PAMIEC            DB     'WIELKOSC PAMIECI WYRAZONA HEXADECYMALNIE WYNOSI: ', 0
STRONY            DB     'CALKOWITA ILOSC STRON WYRAZONA HEXADECYMALNIE WYNOSI:  ', 0

LICZBA_BIN DB     0, 0, 0, 0, 0, 0, 0, 0
LICZBA_HEX  DB    0, 0, 0, 0, 0, 0, 0, 0
stop db 0
calkowita_wielkosc_pamieci_w_B   dd 0
calkowita_wielkosc_pamieci_w_4KB   dd 0
adres_konca_tablicy_stron          dd 0
rozmiar_mapy_bitowej_w_b           dd 0
rozmiar_mapy_bitowej_w_4kb         dd 0


nimo                               db 0
usunac                             dw 0


wskaznik_zadania  dw 0

ROZMIAR_IDENTYFIKATORA_PROCESU     EQU 155
WIELKOSC_KOLEJKI_ZADAN             EQU 1000

;////////////////////////////////  Stronicowanie    ///////////////////////////
element_katalogu_stron  times  4  db    0
element_tablicy_stron   times  4  db    0
;///////////////////////////////// Przerwania, plapki /////////////////////////
furtka_przerwania_plapki  times 8 db  0
;//////////////////////////////



;;;;;;;;;;;;;;;;;;;;;; Pocz�tek kodu systemu operacyjnego ;;;;;;;;;;;;;;;;;;;;;

poczatek:
  mov ax, cs
  mov ds, ax
;Aktywacja linii A20:
  CZY_DOSTEPNY_FAST_A20
  A20_ON
;Wypisanie tekstu informacyjnego o za�adowaniu systemu operacyjnego:
  mov dx, KERNEL_ZALADOWANY
  CALL WYPISZ_TEKST
  
;Tworzenie globalnej tablicy deskrytpor�w:
  mov ax, 7000h
  mov es, ax
  call WYMAZ_GDT                ; Wyzerowanie tablicy GDT.
;Ustalenie adresu stosu:
  mov ax, 6000h
  mov ss, ax
  mov sp, 0ffffh
;Tworzenie deskryptora zerowego (pierwszy wpis GDT):
  xor eax, eax
  xor ebx, ebx
  CALL ROZMIAR_I_ADRES_DESKRYPTORA
  xor ax, ax
  CALL TYP_DESKRYPTORA
  CALL ZALADUJ_DESKRYPTOR
;Tworzenie deskryptora adresu liniowego (za pomoc� segmentu opisanego tym
;deskryptorem b�dzie odbywa� si� dost�p systemu operacyjnego do ca�ej pami�ci
;operacyjnej):
  mov ax, [OFFSET_GDT]
  mov [POLOZENIE_DESKRYPTORA_ADRESU_LINIOWEGO], ax
  mov eax, 0ffffffffh                           ;maksymalny limit
  mov ebx, 0h
  CALL ROZMIAR_I_ADRES_DESKRYPTORA
  mov al, 10010010b      ; P, DPL, S, DANE, Expand, W, A
  mov ah, 11000000b      ;G, D, 0, AVL, limit
  CALL TYP_DESKRYPTORA
  CALL ZALADUJ_DESKRYPTOR
;Tworzenie dekskryptora segmentu kodu:
  mov ax, [OFFSET_GDT]
  mov [POLOZENIE_DESKRYPTORA_KODU], ax
  mov eax, 0000ffffh    ; limit  64KB
  xor ebx, ebx
  mov bx, cs
  shl ebx, 4
  CALL ROZMIAR_I_ADRES_DESKRYPTORA
  mov al, 10011010b      ; P, DPL, S, PROGRAM, C, R, A
  mov ah, 01000000b      ;G, D, 0, AVL, limit
  CALL TYP_DESKRYPTORA
  CALL ZALADUJ_DESKRYPTOR
  mov ax, [OFFSET_GDT]
  mov [POLOZENIE_DESKRYPTORA_DANYCH], ax
;Tworzenie deskryptora segmentu danych:
  mov eax, 0000ffffh
  xor ebx, ebx
  mov bx, ds
  shl ebx, 4
  CALL ROZMIAR_I_ADRES_DESKRYPTORA
  mov al, 10010010b      ; P, DPL, S, DANE, Expand, W, A
  mov ah, 01000000b      ;G, D, 0, AVL, limit
  CALL TYP_DESKRYPTORA
  CALL ZALADUJ_DESKRYPTOR
  mov ax, [OFFSET_GDT]
  mov [POLOZENIE_STOSU], ax
;Tworzenie deskryptora segmentu stosu:
  mov eax, 00000000h
  xor ebx, ebx
  mov bx, ss
  shl ebx, 4
  CALL ROZMIAR_I_ADRES_DESKRYPTORA
  mov al, 10010110b       ; P, DPL, S, DANE, Expand, W, A
  mov ah, 01000000b      ;G, D, 0, AVL, limit
  CALL TYP_DESKRYPTORA
  CALL ZALADUJ_DESKRYPTOR
  mov ax, [OFFSET_GDT]
  mov [POLOZENIE_DESKRYPTORA_KATALOGU_STRON], ax
;Tworzenie deskryptora segmentu katalogu stron
  mov eax, 00001000h
  xor ebx, ebx
  mov bx, 5F00h
  shl ebx, 4
  CALL ROZMIAR_I_ADRES_DESKRYPTORA
  mov al, 10010010b      ; P, DPL, S, DANE, Expand, W, A
  mov ah, 01000000b      ;G, D, 0, AVL, limit
  CALL TYP_DESKRYPTORA
  CALL ZALADUJ_DESKRYPTOR
  mov ax, [OFFSET_GDT]
  mov [POLOZENIE_DESKRYPTORA_TABLICY_PRZERWAN], ax
;Tworzenie deskryptora segmentu tablicy przerwa�:
  mov eax, 0000800h
  xor ebx, ebx
  mov bx, 5700h
  shl ebx, 4
  CALL ROZMIAR_I_ADRES_DESKRYPTORA
  mov al, 10010010b      ; P, DPL, S, DANE, Expand, W, A
  mov ah, 01000000b      ;G, D, 0, AVL, limit
  CALL TYP_DESKRYPTORA
  CALL ZALADUJ_DESKRYPTOR
  mov ax, [OFFSET_GDT]
  mov [POLOZENIE_DESKRYPTORA_DANYCH_KLAWIATURY], ax
;Tworzenie deskryptora segmentu danych klawiatury:
  mov eax, 00000046h
  xor ebx, ebx
  mov bx, 56BAh
  shl ebx, 4
  CALL ROZMIAR_I_ADRES_DESKRYPTORA
  mov al, 10010010b      ; P, DPL, S, DANE, Expand, W, A
  mov ah, 01000000b      ;G, D, 0, AVL, limit
  CALL TYP_DESKRYPTORA
  CALL ZALADUJ_DESKRYPTOR
;Tworzenie pseudodeskryptora:
  xor ebx, ebx
  mov bx, es
  shl ebx, 4             ;baza
  mov ax, 0ffffh         ;limit gdtr
  CALL ROZMIAR_I_ADRES_DTR
  cli
  lgdt [dtr]
;Inicjalizacja trybu chronionego:
  mov eax, cr0
  or al, 1
  mov cr0, eax
  jmp $+2
  DB 66h
  db 0eah
  dd zaladuj_selektor
  dw 16

[BITS 32]
;Zapis do zmiennych selektor�w utworzonych segment�w
  zaladuj_selektor:
  mov word [POLOZENIE_STOSU], 32
  mov word [POLOZENIE_DESKRYPTORA_DANYCH], 24
  mov word [POLOZENIE_DESKRYPTORA_ADRESU_LINIOWEGO], 8
  mov word [POLOZENIE_DESKRYPTORA_KODU], 16
  mov word [POLOZENIE_DESKRYPTORA_KATALOGU_STRON], 40
  mov word [POLOZENIE_DESKRYPTORA_TABLICY_PRZERWAN], 48
  mov word [POLOZENIE_DESKRYPTORA_DANYCH_KLAWIATURY], 56
;Zapis selektora segmentu danych do rejestru DS;
  mov ax, 24
  mov ds, ax
;Zapis selektora segmentu stosu do rejestru SS:
  mov ax, 32
  mov ss, ax
  mov esp, 0FFFFh
;Zapis selektora segmentu adresu liniowego do rejestru ES:
  mov ax, 8
  mov es, ax
;Wy�wietlenie informacji o aktywnym trybie chronionym
  mov bh, 3
  mov bl, 0
  CALL USTAL_POZYCJE_KURSORA
  mov ah, 3h
  mov esi, NAPIS
  CALL WYPISZ_TEKST_32
;Okre�lenie rozmiaru pami�ci operacyjnej:
  CALL USTAL_WIELKOSC_PAMIECI
  mov [calkowita_wielkosc_pamieci_w_B], eax
  mov esi, LICZBA_HEX
;Wypisanie rozmiaru pami�ci operacyjnej na ekranie:
  CALL ZAMIEN_LICZBE_HEX
  mov bh, 4
  mov esi, PAMIEC
  CALL OBLICZ_DLUGOSC_NAPISU
  mov bl, al
  CALL USTAL_POZYCJE_KURSORA
  mov esi, LICZBA_HEX
  mov ah, 4h
  CALL WYPISZ_TEKST_32
  mov bh, 4
  xor bl, bl
  CALL USTAL_POZYCJE_KURSORA
  mov esi, PAMIEC
  mov ah, 3h
  CALL WYPISZ_TEKST_32
;Obliczenie ilo�ci stron pami�ci:
  mov edx, [calkowita_wielkosc_pamieci_w_B]
  xor edx, edx
  mov ebx, 1000h                           ;dzielenie przez 4KB
  div ebx
  mov [calkowita_wielkosc_pamieci_w_4KB], eax
  mov esi, LICZBA_HEX
  CALL ZAMIEN_LICZBE_HEX
;Wypisanie na ekranie liczby stron:
  mov bh, 5
  mov esi, STRONY
  CALL OBLICZ_DLUGOSC_NAPISU
  mov bl, al
  CALL USTAL_POZYCJE_KURSORA
  mov esi, LICZBA_HEX
  mov ah, 4h
  CALL WYPISZ_TEKST_32
  mov esi, STRONY
  mov bh, 5
  xor bl, bl
  CALL USTAL_POZYCJE_KURSORA
  mov ah, 3h
  CALL WYPISZ_TEKST_32
;Inicjalizacja stronicowania pami�ci operacyjnej:
  CALL PRZYGOTOWANIE_STRONICOWANIA_2
  CALL WLACZ_STRONICOWANIE
  CALL TWORZ_MAPE_BITOWA_PAMIECI
  mov bh, 6
  mov bl, 0
  CALL USTAL_POZYCJE_KURSORA
  mov ax, 8
  mov es, ax
  mov ah, 3h
  mov esi, STRONICOWANIE
  CALL WYPISZ_TEKST_32
;Inicjalizacja obs�ugi przerwa�
  CALL WYPELNIENIE_IDT_
  CALL PRZYGOTOWANIE_TABLICY_PRZERWAN
  mov ax, [POLOZENIE_DESKRYPTORA_TABLICY_PRZERWAN]
;Zegar systemowy b�dzie wyznacza� cz�stotliwo�� wywo�a� schedulera, nast�puje
;ustalenie cz�stotliwo�ci generowanych przez niego przerwa�:
  mov ebx, 50
  call USTAW_CZESTOTLIWOSC_ZEGARA
;Ustawienie pocz�tkowych warto�ci zmiennych ekranu:
  call USTAL_POCZATKOWE_PARAMETRY_EKRANU
  call MAZ_EKRAN
  xor eax, eax
  call USTAW_KURSOR_
  pusha
  mov ax, 8
  mov es, ax
;Okre�lenie adresu pierwszej wolnej pozycji w tablicy GDT:
  MOV EDI, 70008H
  MOV ECX, EDI
  ADD ECX, 0ffffh
  CALL ZNAJDZ_PIERWSZA_WOLNA_POZYCJE_W_TABLICY_DESKYPTOROW
;Inicjalizacja wielozadaniowo�ci:
  call INICJALIZUJ_WIELOZADANIOWOSC
  popa
;Tworzenie furtek wywo�a� dla us�ug systemowych:
  call TWORZ_USLUGI_JADRA
;Inicjalizacja klawiatury:
  call INICJALIZUJ_KLAWIATURE
;Odblokowanie przerwania stacji dyskietek, klawiatury i zegara systemowego:
  mov bl,10111100b
  CALL PRZEPROGRAMOWANIE_KONTROLERA_PRZERWAN
  sti
;Wczytanie tablicy FAT oraz katalogu g��wnego dyskietki:
  CALL WCZYTAJ_DANE_FATU

;Uruchomienie interpretatora polece�:
    call INTERPRETATOR_POLECEN

.tutaj:
jmp .tutaj

;//////////////////////////   PROCEDURY    /////////////////////////////////////
;///////////////////////////////////////////////////////////////////////////////
[BITS 32]


TWORZ_USLUGI_JADRA
;Procedura tworzy bramy wywo�a� do wszystkich udost�pnionych procedur j�dra
pusha
  mov ax, es
  push eax
  mov ax, 8
  mov es, ax
      
;;;;;;;;;;;;;;; WYSWIETLANIE ZNAKU   ;;;;;;;;;;;;;; 72 OFFSET DESKRYPTORA
  mov bx, [POLOZENIE_DESKRYPTORA_KODU]
  mov eax, POZIOM_4_WYSWIETL_ZNAK
  mov cl, 0
  mov edi, 70000h ; asres poczatku GDT
  add edi, 48h    ; pierwsza wolna pozycja w tej chwili znajduje sie na
  call  ODLUZ_BRAME_WYWOLAN_DO_TABLICY_DESKRYPTOROW
;;;;;;;;;;;;;;; WYSWIETLANIE LICZBY DZIESIETNIE  ;;;;;;;;;;;;;; 80 OFFSET DESKRYPTORA
  mov eax, POZIOM_4_WYSWIETL_LICZBE_DZIESIETNIE
  add edi, 8
  call   ODLUZ_BRAME_WYWOLAN_DO_TABLICY_DESKRYPTOROW
;;;;;;;;;;;;;;; SPRAWDZENIE LICZBY  ;;;;;;;;;;;;;; 88 OFFSET DESKRYPTORA
  mov eax, POZIOM_4_SPRAWDZENIE_LICZBY
  add edi, 8
  call   ODLUZ_BRAME_WYWOLAN_DO_TABLICY_DESKRYPTOROW
;;;;;;;;;;;;;;; PROCEDURA WYWLASZCZAJACA   ;;;;;;;;;;;;;; 96 OFFSET DESKRYPTORA
  mov eax, POZIOM_4_WYWLASZCZENIE
  add edi, 8
  call   ODLUZ_BRAME_WYWOLAN_DO_TABLICY_DESKRYPTOROW
;;;;;;;;;;;;;;; WYPISZ TEKST   ;;;;;;;;;;;;;; 104 OFFSET DESKRYPTORA
  mov eax, POZIOM_4_WYPISZ_TEKST
  add edi, 8
  call   ODLUZ_BRAME_WYWOLAN_DO_TABLICY_DESKRYPTOROW
;;;;;;;;;;;;;;; WYPISZ TEKST z blokowaniem  ;;;;;;;;;;;;;; 112 OFFSET DESKRYPTORA
  mov eax, POZIOM_4_WYPISZ_TEKST_NA_EKRANIE
  add edi, 8
  call   ODLUZ_BRAME_WYWOLAN_DO_TABLICY_DESKRYPTOROW
;;;;;;;;;;;;;;; WYWLASZCZANIE  ;;;;;;;;;;;;;; 120 OFFSET DESKRYPTORA
  mov eax, POZIOM_4_WYWLASZCZANIE_ZADANIA
  add edi, 8
  call   ODLUZ_BRAME_WYWOLAN_DO_TABLICY_DESKRYPTOROW
  pop eax
  mov es, ax
popa
RET

ODLUZ_DESKRYPTOR_DO_TABLICY_DESKRYPTOROW
;Parametry procedury:
;ES:EDI - adres, pod kt�ry zostanie zapisany deskryptor
;EBX - adres bazowy segmentu
;EAX - limit segmentu
;CX - TYP  w formacie - G   D/B   0   AVL   0   0   0   0   P   DPL2   DPL1   S   TYP4   TYP3   TYP3   TYP1
pusha
  xor edx, edx
  mov dx, bx
  shl edx, 16    ; bity 16- 31 rejestru EDX wskazuj� na bity 0-15 adresu bazowego
  mov dx, ax     ; pierwsze 16 bit�w limiutu jest na pozycjach 0-15 rejestru EDX
  push edx
  xor edx, edx
  shr ebx, 16    ; rejestr BX zawiera starsze s�owo adresu bazowego
  shr eax, 16    ; 4 pierwsze bity rejestru AL zawieraj� bity 16-19 limitu
  and al, 1111b
  mov dh, bh     ; w DH jest adres bazowy (bity 24-31)
  or al, ch
  mov dl, al
  shl edx, 16
  mov dl, bl     ; m�odsza druga po�owa adresu bazowego
  mov dh, cl     ; typ
  pop eax
  mov [es:edi], eax
  mov [es:edi+4], edx
popa
RET

ODLUZ_BRAME_WYWOLAN_DO_TABLICY_DESKRYPTOROW
;Parametry procedury:
;BX - selektor segmentu
;EAX - offset
;5 m�odszych bit�w CL - ilo�� parametr�w do skopiowania ze stosu
;ES:DI - adres pod kt�rym ma zostac dodany deskryptor furtki
pusha
  shl ebx, 16
  mov bx, ax
  mov [es:edi], ebx
  and eax, 0ffff0000h
  and cl, 00011111b
  or al, cl
  ;       PDD0TTTT                   = P= present   D= dpl   0 - zarezerwowane T- typ
  mov ah, 11101100b
  mov [es:edi+4], eax
popa
RET


ZNAJDZ_PIERWSZA_WOLNA_POZYCJE_W_TABLICY_DESKYPTOROW
;Parametry procedury:
;ES:EDI - adres tablicy deskryptor�w
;ECX - adres ko�ca tablicy
;Wyniki:
;EDI - adres pierwszej wolnej pozycji  (0 gdy nie b�dzie wolnej pozycji)
push eax
push ebx
  .petla_znajdowania_wolnego_miejsca_na_dekryptor:
    mov eax, [es:edi]
    mov ebx, [es:edi+4]
    cmp eax, 0
    jne .deskryptor_zajety
    cmp ebx, 0
    jne .deskryptor_zajety
    jmp .koniec_petli
    .deskryptor_zajety:
    add edi, 8    ; obliczenie adresu nast�pnej pozycji
    cmp edi, ecx
    jae .koniec_petli
    jmp .petla_znajdowania_wolnego_miejsca_na_dekryptor
  .koniec_petli:
  cmp edi, ecx
  jb .dalej
  xor edi, edi
  .dalej
pop ebx
pop eax
RET

USUN_DESKRYPTOR_Z_TABLICY_DESKRYPTOROW
;Parametry procedury:
;ES:EDI -  adres pozycji do usuni�cia
  mov dword [es:edi], 0
  mov dword [es:edi+4], 0
RET

PRZYGOTOWANIE_STRONICOWANIA_2
  xor esi, esi
  mov ax, 8
  mov es, ax                                     ;Zapis do ES selektora adresu liniowego
  mov edi,  [POLOZENIE_TABLICY_STRON]            ;Adres pierwszej tablicy stron
;Obliczenie koniecznego rozmiaru binarnej mapy pami�ci:
  mov eax, [calkowita_wielkosc_pamieci_w_4KB]
  xor edx, edx
  mov ebx, 8
  div ebx
  cmp edx, 0
  je .DALEJ
    inc eax
  .DALEJ:
  mov [rozmiar_mapy_bitowej_w_b], eax
;Obliczenie ilo�ci stron niezb�dnych dla binarnej mapy pami�ci:
  xor edx, edx
  mov ebx, 4096
  div ebx
  cmp edx, 0
  je .DALEJ2
    inc eax
  .DALEJ2:
   mov [rozmiar_mapy_bitowej_w_4kb], eax
;Dodanie liczby stron w 1MB pami�ci:
  add eax, 256
  push eax
  push eax
;Wyznaczenie adresu ko�ca binarnej mapy pami�ci:
  inc eax
  shl eax, 2
  add eax, edi
  mov [adres_konca_tablicy_stron], eax
;Tworzenie tablicy stron:
  mov al, 00000011b   ; 0, D, A, PCD, PWT, U/S, R/W, P
  mov ah, 0000b       ; AV, G
  xor edx, edx
  call WYPELNIJ_TABLICE_STRON_NULAMI
  POP ECX
  .tworzenie_tablic_stron:
     push eax
        CALL PRZYGOTUJ_ELEMENT_TABLICY_STRON
     stosd
     add edx, 1000h
     pop eax
  loop .tworzenie_tablic_stron
;Tworzenie katalogu stron:
  POP ECX
  mov ecx, 1
  mov ax, [POLOZENIE_DESKRYPTORA_KATALOGU_STRON]
  mov es, ax
  xor edi, edi
  call WYPELNIJ_KATALOG_STRON_NULAMI
  mov al, 00000011b   ; PS, 0, A, PCD, PWT, U/S, R/W, P
  mov ah, 0000b       ; AV, G
  mov edx, [POLOZENIE_TABLICY_STRON]
  .tworzenie_katalogu_stron:
    push eax
    CALL PRZYGOTUJ_ELEMENT_KATALOGU_STRON
    stosd
    add edx, 1000h
    pop eax
  loop .tworzenie_katalogu_stron
RET

TWORZ_MAPE_BITOWA_PAMIECI
;Procedura tworzy binarn� map� pami�ci
PUSHA
  mov ax, 8
  mov es, ax
  mov edi, 100000H
;Rezerwacja w binarnej mapie pami�ci zaj�tych stron (rozmiar binarnej mapy
;pami�ci oraz pierwszego megabajta):
  mov eax, [rozmiar_mapy_bitowej_w_4kb]
  add eax, 256
  xor edx, edx
  mov ebx, 8
  div ebx
  push edx
  mov ecx, eax
  mov al, 11111111B
;P�tla rezerwuje ca�y bajt binarnej mapy pami�ci:
  .PETLA:
     stosb
  loop .PETLA
  pop edx
  mov ecx, edx
;Je�eli liczba zaj�tych stron nie jest podzielna przez 8:
  jecxz .dalej
  xor al, al
  mov bl, 10000000b
  .petla2:
    or al, bl
    shr bl, 1
  loop .petla2
  stosb
  .dalej:
;Pozosta�a cz�� binarnej mapy pami�ci wype�niana jest zerami:
  mov eax, [calkowita_wielkosc_pamieci_w_4KB]
  mov ebx, [rozmiar_mapy_bitowej_w_4kb]
  add ebx, 256
  sub eax, ebx
  mov ebx, 8
  xor edx, edx
  div ebx
  mov ecx, eax
  xor al, al
  .petla3:
    stosb
  loop .petla3
POPA
RET

WYPELNIJ_TABLICE_STRON_NULAMI
;Parametry procedury:
;ES:EDI - adres pocz�tku tablicy stron
;Procedura zeruje tablic� stron
push ecx
push eax
push edi
  mov ecx, 1024
  xor eax, eax
  rep  stosd
pop edi
pop eax
pop ecx
RET

WYPELNIJ_KATALOG_STRON_NULAMI
;Parametry procedury:
;ES:EDI - adres pocz�tku katalogu stron
;Procedura zeruje katalog stron
push ecx
push eax
push edi
  mov ecx, 1024
  xor eax, eax
  rep  stosd
pop edi
pop eax
pop ecx
RET

WLACZ_STRONICOWANIE:
;Zapis adresu katalogu stron do rejestru CR3:
  mov eax, 5F000h
  mov cr3, eax
;W��czenie stronicowania pami�ci operacyjnej:
  mov eax, cr0
  or eax, 80000000h
  mov cr0, eax
  jmp $+2
ret

PRZYGOTUJ_ELEMENT_TABLICY_STRON
;Parametry procedury:
;AX - atrybuty PTE
;EDX - adres ramki
;Wyniki:
;Zmienna elemet_tablicy_stron - wpis PTE
;Procedura tworzy wpis PTE na podstawie warto�ci rejestr�w AX i EDX
  and eax, 00000FFFh
  or eax, edx
  mov [element_tablicy_stron], eax
ret

PRZYGOTUJ_ELEMENT_KATALOGU_STRON
;Parametry procedury:
;AX - atrybuty PDE
;EDX - adres tablicy stron
;Wyniki:
;Zmienna element_katalogu_stron - wpis PDE
;Procedura tworzy wpis PDE na podstawie warto�ci rejestr�w AX i EDX
  and eax, 00000FFFh
  or eax, edx
  mov [element_katalogu_stron], eax
ret

PRZYGOTUJ_ELEMENT_PRZERWANIE_PLAPKE   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; PULAPKE
;Parametry procedury:
;BX - selektor segmentu procedury
;EAX - offset procedury
;CX - atrybuty deskryptora
;Procedura tworzy w zmiennej furtka_przerwania_plapki deskryptor dla procedury
;na podstawie przekazanych paramtr�w.
  mov [furtka_przerwania_plapki+FURTKA_PRZERWANIA_PLAPKI.OFFSET1], ax
  shr eax, 10h
  mov [furtka_przerwania_plapki+FURTKA_PRZERWANIA_PLAPKI.OFFSET2], ax
  mov [furtka_przerwania_plapki+FURTKA_PRZERWANIA_PLAPKI.SELEKTOR], bx
  mov [furtka_przerwania_plapki+FURTKA_PRZERWANIA_PLAPKI.PARAMETRY], cx
ret

ZALADUJ_PRZERWANIE_PLAPKE         ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; PULAPKE
;Parametry procedury:
;ES:EDI - adres, pod kt�ry ma zosta� od�o�ony deskryptor zawarty w zmiennej
;furtka_przerwania_plapki
;Procedura zapisuje zawarto�� zmiennej furtka_przerwania_plapki pod adres
;okre�lony parametrami procedury.
  mov esi, furtka_przerwania_plapki
  movsd
  movsd
ret

ZMIEN_OFFSET_PRZERWANIE_PLAPKE
;Parametry procedury:
;EAX - nowy offset procedury
;Procedura modyfikuje deskryptor zawarty w zmiennej furtka_przerwania_plapki
;aby wskazywa� na procedur� obs�ugi o innym offsecie.
  mov [furtka_przerwania_plapki+FURTKA_PRZERWANIA_PLAPKI.OFFSET1], ax
  shr eax, 10h
  mov [furtka_przerwania_plapki+FURTKA_PRZERWANIA_PLAPKI.OFFSET2], ax
ret


%macro wypelnienie_idt 2
;Makro wype�nia tablic� IDT deskryptorami do procedur, kt�rych nazwa
;r�ni si� ko�cowym indeksem.
;Parametry makra:
;Pierwszy parametr makra wskazuje na rdze� nazwy procedur.
;Drugi parametr makra okre�la ile wpis�w zostanie dodane.
  %assign licznik %2        ;okre�lenie ilo�ci dodawanych wpis�w
  %assign i 0
  %rep licznik
    mov eax, %1 %+ i        ;pobranie offsetu kolejnej procedury
    call ZMIEN_OFFSET_PRZERWANIE_PLAPKE
    call ZALADUJ_PRZERWANIE_PLAPKE
    %assign i i+1                 ;inkrementacja licznika p�tli
  %endrep
%endmacro

%macro wypelniej_idt_jednym 3
;Makro wype�nia tablic� IDT deskryptorami procedury do jednej procedury
;Parametry makra:
;Pierwszy parametr makra wskazuje na rdze� nazwy procedury.
;Drugi parametr makra wskazuje na indeks procedury.
;Trzeci parametr makra okre�la ilo�� deskryptor�w, kt�re nale�y doda�.
    %rep %3
      mov eax, %1 %+ %2
      call ZMIEN_OFFSET_PRZERWANIE_PLAPKE
      call ZALADUJ_PRZERWANIE_PLAPKE
    %endrep
%endmacro

;DO��CZENIE KODU MODU��W SYSTEMU OPERACYJNEGO:
%include 'wyjatki.asm'
%include 'przerwania.asm'
%include 'fdd.asm'
%include 'zegary.asm'
%include 'ekran.asm'
%include 'interpretator.asm'
%include 'pamiec.asm'
%include 'pule.asm'
%include 'kolejki.asm'
%include 'wielozadaniowosc.asm'
%include 'obsluga_urzadzen.asm'
%include 'uslugi_jadra.asm'
%include 'fat.asm'

WYPELNIENIE_IDT_
;Procedura wype�nia tablic� deskryptor�w przerwa�.
  mov ax, [POLOZENIE_DESKRYPTORA_TABLICY_PRZERWAN]
  mov es, ax
  xor edi, edi      ;Rejestry ES:EDI zawieraj� adres pocz�tku IDT
  mov bx, [POLOZENIE_DESKRYPTORA_KODU]
  mov eax, wyjatek0 ;Offset wyj�tku dzielenia przez 0
  mov cx, 1000111000000000b ;atrybuty deskryptora
  call PRZYGOTUJ_ELEMENT_PRZERWANIE_PLAPKE  ;procedura tworzy deskryptor do procedury obs�ugi przerwania dzielenia przez 0
;Wype�nienie tabilcy IDT deskryptorami do procedur obs�ugi wyj�t�w oraz przerwa�:
  wypelnienie_idt wyjatek, 21          ;21 pierwszych pozycji
  wypelniej_idt_jednym wyjatek, 20, 11 ;11 kolejnych pozycji
  wypelnienie_idt przerwanie, 7        ;pozycje okre�laj�ce przerwania sprz�towe.
ret

ROZMIAR_I_ADRES_DTR_32
;Parametry procedury:
;AX - Rozmiar tablicy deskryptor�w,
;EBX - Adres tablicy deskryptor�w.
;Wyniki:
;Zmienna dtr b�dzie zawiera�a pseudodeskryptor dla tablicy deskryptor�w
;okre�lonej parametrami procedury.
  mov [dtr+DTR.LIMIT], ax
  mov [dtr+DTR.BAZA], ebx
ret



PRZYGOTOWANIE_TABLICY_PRZERWAN
;Procedura tworzy pseudodeskryptor opisuj�cy tablic� IDT, po czym umieszcza
;jego zawarto�� w rejestrze IDTR.
  mov eax, 5700h
  shl eax, 4
  mov ebx, eax
  mov ax, 2048
  CALL ROZMIAR_I_ADRES_DTR_32
  LIDT [dtr]
ret

PRZEPROGRAMOWANIE_KONTROLERA_PRZERWAN
;Parametry procedury:
;BL - maska przerwa�.
cli
  MOV DX,20H  ;Inicjacja pracy uk�adu
  MOV AL,11h  ;icw1=11h
  OUT DX,AL
  INC DX
  MOV AL,20H  ;icw2=20h (offset wektora przerwa�)
  OUT DX,AL
  MOV AL,4    ;icw3=04h (uk�ad master)
  OUT DX,AL
  MOV AL,1b   ;icw4=01h (tryb 8086/88)
  OUT DX,AL
  MOV AL, BL  ;ocw1=0fdh (maska przerwa� - master)
  OUT DX,AL
  MOV DX,0A1H
  MOV AL,0FFH
  OUT DX,AL
ret

USTAL_WIELKOSC_PAMIECI:
;Procedura okre�la wielko�� pami�ci operacyjnej
;Wyniki:
;EAX - rozmiar pami�ci operacyjnej.
  mov ax, 8
  mov fs, ax        ;Zapis do rejestru FS selektora segmentu adresu liniowego
  mov esi, 0FFFFFh
;W pierwszej kolejno�ci procedura pr�bkuje pami�� co 4KB (aby zwi�kszy� szybko��):
  .petla:
    add esi, 1000h
    mov ax, 500h
    mov [fs:esi], ax
    mov ax, 300h
    mov ax, [fs:esi]
    cmp ax, 500h
    jne koniec_petli_ustalania_pamieci
  jmp .petla
  koniec_petli_ustalania_pamieci:
  sub esi, 1000h
;Pr�bkowanie pami�ci co 1B:
  .petla2:
    add esi, 1h
    mov ax, 500h
    mov [fs:esi], ax
    mov ax, 300h
    mov ax, [fs:esi]
    cmp ax, 500h
    jne koniec_petli_ustalania_pamieci2
  jmp .petla2
  koniec_petli_ustalania_pamieci2:
  add esi, 1h
  mov eax, esi
ret



ZAMIEN_LICZBE_HEX:
;Procedura zamienia liczb� na ci�g znak�w okre�laj�cy jej reprezentacj� szesnastkow�.
;Parametry procedury:
;EAX - liczba,
;DS:ESI - adres do zapisu znak�w ASCII.
  mov edx, eax
  xor ecx, ecx
  mov cx, 8
  .petla:
    push edx
    push ecx
    dec cx
    mov al, 4
    mul cl
    mov cl, al
    shr edx, cl
    and dl, 00001111b
    mov edi, esi
    add edi, 8h
    pop ecx
    sub edi, ecx
    cmp dl, 9h
    ja .litera
    add dl, 30h
    jmp .koniec
    .litera:
    add dl, 37h
    .koniec:
    mov [ds:edi], dl
    pop edx
  loop .petla
ret


ZMIEN_LICZBE_BIN:
;Procedura zamienia liczb� na ci�g znak�w okre�laj�cy jej reprezentacj� binarn�.
;Parametry procedury:
;AX - liczba,
;DS:ESI - adres do zapisu znak�w ASCII.
  mov ecx, 16
  .petla:
    sal ax, 1
    jc .jeden
    mov  byte [esi], 30h
    jmp .koniec
    .jeden:
    mov  byte [esi], 31h
    .koniec:
    inc esi
  loop .petla
ret

WYPISANIE_PAMIECI_BINARNIE
;Parametry procedury:
;ECX - ilo�� s��w do wypisania,
;GS:EDI - pocz�tkowy adres, od kt�rego nast�pi wypisanie bit�w.
  PUSHA
  mov bl, 0
  mov bh, 10
  .petla:
    mov ax, [gs:edi]
    mov esi, LICZBA_BIN
    push edi
    push ecx
    call ZMIEN_LICZBE_BIN
    pop ecx
    push ebx
    call USTAL_POZYCJE_KURSORA
    pop ebx
    mov ax, 8
    mov es, ax
    mov ah, 3h
    mov esi, LICZBA_BIN
    call WYPISZ_TEKST_32
    pop edi
    inc edi
    inc edi
    inc bh
  loop .petla
  POPA
ret

;DEFINICJE STRUKTUR (szerszy opis ka�dej struktury w tre�ci ksi��ki):

;///////////////////////////////////////////////////////////////////////////////
;//////////////    SELEKTOR    /////////////////////////////////////////////////

struc SELEKTOR_SEGMENTU
      .SELEKTOR   resw   1
; bity 0-1             RPL- poziom uprzywilejowania segmentu
; bit 2                0 GDT       1 LDT
; bity 3-15            indeks w tablicy deskryptorow

endstruc

;///////////////////////////////////////////////////////////////////////////////
;//////////////    DESKRYKKPTOR    /////////////////////////////////////////////

struc DESKRYPTOR

      .LIMIT1       resw   1    ; limit 0..15
      .BAZA1        resb   2    ; adres bazowy od 0..15 bity
      .BAZA2        resb   1    ; adres bazowy 16..23 bity
      .PARAMETR1    resb   1
; 0                 A        bit dost�pu
; 1..3             TYPE      typ deskryptora
;                  dla S=0   bit 0 - ACCESSED; 1- WRITE; 2- gdy 1 expand down
;                  dla S=1   0- ACCESSED; 1- READ; 2- gdy 1 conforming
; 4                S         0- systemowy, 1-kod/dane
; 5..6             DPL       poziom uprzywilejowania
; 7                P         czy obecny
      .PARAMETR2    resb   1
; 0..3             LIMIT2    16..18
; 4                AVL       Do dowolnego wykorzystania
; 5                0         musi wynosi� 0
; 6                D/B       dla kodu - ustawiony - 32 bitowy segment, inaczej 16 bitowy
;                            dla stosu- ustawiony 32 bity offsetu, inaczej 16
; 7               G          gdy ustawiony limit * 4KB, inaczej limit * 1B
      .BAZA3        resb   1    ;adres bazowy od 24..31 bita
endstruc

;///////////////////////////////////////////////////////////////////////////////
;//////////////    TABLICE DESKRYPTOROW    /////////////////////////////////////

struc   DTR                ; GDTR lub IDTR

        .LIMIT     resw    1    ; limit
        .BAZA      resd    1    ; adres bazowy

endstruc


;///////////////////////////////////////////////////////////////////////////////
;//////////////    KATALOG STRON    ////////////////////////////////////////////

struc   ELEMENT_KATALOGU_STRON

        .PARAMETRY   resb   1
;0                  P      obecno�� w pami�ci
;1                  R/W    0- tylko do odczytu, 1- odczyt i zapis
;2                  U/S    0- supervisor , 1- user
;3                  PWT    0- write-back , 1- write-through
;4                  PCD    0- mo�e byc caching, 1- caching zabroniony
;5                  A      ACCESS
;6                  0      0
;7                  PS
        .BAZA1       resb   1
;0                  G      wskazuje globaln� stron�
;1..3               AVL    mo�liwo�� dowolnego wykorzystania
;4..7               ADRES  pierwsze 4 bity adresu
        .BAZA2       resw   1 ;16 bit�w adresu
endstruc

;///////////////////////////////////////////////////////////////////////////////
;//////////////    TABLICA STRON    ////////////////////////////////////////////

struc   ELEMENT_TABLICY_STRON

        .PARAMETRY   resb   1
;0                  P      obecno�� w pami�ci
;1                  R/W    0- tylko do odczytu, 1- odczyt i zapis
;2                  U/S    0- supervisor , 1- user
;3                  PWT    0- write-back , 1- write-through
;4                  PCD    0- moze byc caching, 1- caching zabroniony
;5                  A      ACCESS
;6                  D      Ustawiany przy zapisie
;7                  0      0
        .BAZA1       resb   1
;0                  G      wskazuje globalna stron�
;1..3               AVL    mo�liwo�� dowolnego wykorzystania
;4..7               ADRES  pierwsze 4 bity adresu
        .BAZA2       resw   1
;                          16 bit�w adresu
endstruc


;///////////////////////////////////////////////////////////////////////////////
;//////////////        BRAMKA       ////////////////////////////////////////////

struc   BRAMKA
        .OFFSET1     resw   1
; pierwsze 16 bit�w offsetu w segmencie

        .SELEKTOR    resw   1
; selektor segmentu

        .PARAMETRY   resw   1
;0..4                param  liczba parametr�w
;5..7                0      0
;8..11               TYP    Typ
;12                  0      0
;13..14              DPL    poziom uprzywilejowania
;15                  P      obecno�� w pamieci

        .OFFSET2     resw   1 ; bity 16..31 offsetu

endstruc

;///////////////////////////////////////////////////////////////////////////////
;//////////////    PRZERWANIE LUB PU�APKA    ///////////////////////////////////

struc   FURTKA_PRZERWANIA_PLAPKI
        .OFFSET1     resw   1
; pierwsze 16 bit�w offsetu w segmencie

        .SELEKTOR    resw   1
; selektor segmentu

        .PARAMETRY   resw   1
;0..4                zarezerwowane
;5..7                0      0
;8                   W      furtka przerwania =0, plapki =1
;9..10               1      1
;11                  D      tryb 16 bitowy = 0, 32 bitowy=1
;12                  0      0
;13..14              DPL    poziom uprzywilejowania
;15                  P      obecno�� w pamieci

        .OFFSET2     resw   1
; bity 16..31 offsetu

endstruc

struc KLAWIATURA
      .BUFOR              resw  32
      .WSKAZNIK_ZAPISU    resb  1
      .WSKAZNIK_ODCZYTU   resb  1
      .BAJT_STANU_1       resb  1
;0    WCISNIETY PRAWY SHIFT
;1    WCISNIETY LEWY  SHIFT
;2    WCISNIETY CTRL
;3    WCISNIETY ALT
;4    WCISNIETY SCROLL LOCK
;5    WCISNIETY NUM LOCK
;6    WCISNIETY CAPS LOCK
;7    WCISNIETY INSERT
      .BAJT_STANU_2       resb  1
      .BAJT_STANU_3       resb  1
      .BAJT_STANU_4       resb  1
endstruc


;;;;;;;;;;;;;;;TSS;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
struc TSS
      .LINK_DO_POPRZEDNIEGO_ZADANIA              resw  1
      .NULL_1                                    resw  1
      .ESP0                                      resd  1
      .SS0                                       resw  1
      .NULL_2                                    resw  1
      .ESP1                                      resd  1
      .SS1                                       resw  1
      .NULL_3                                    resw  1
      .ESP2                                      resd  1
      .SS2                                       resw  1
      .NULL_4                                    resw  1
      .CR3                                       resd  1
      .EIP                                       resd  1
      .EFLAGS                                    resd  1
      .EAX                                       resd  1
      .ECX                                       resd  1
      .EDX                                       resd  1
      .EBX                                       resd  1
      .ESP                                       resd  1
      .EBP                                       resd  1
      .ESI                                       resd  1
      .EDI                                       resd  1
      .ES                                        resw  1
      .NULL_5                                    resw  1
      .CS                                        resw  1
      .NULL_6                                    resw  1
      .SS                                        resw  1
      .NULL_7                                    resw  1
      .DS                                        resw  1
      .NULL_8                                    resw  1
      .FS                                        resw  1
      .NULL_9                                    resw  1
      .GS                                        resw  1
      .NULL_10                                   resw  1
      .LDT_SELEKTOR                              resw  1
      .NULL_11                                   resw  1
      .T                                         resw  1  ; na pierwszej pozycji tego pola znajduje sie bit T
      .MAPA_WE_WY                                resw  1
endstruc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;; IDENTYFIKATOR PROCESU ;;;;;;;;;;;;;;;;

struc IDENTYFIKATOR_PROCESU
      .WIELKOSC:            RESW                 1
      .SELEKTOR_TSS:        RESW                 1
      .ADRES_TSS:           RESD                 1
      .STAN:                RESB                 1
      .CR3                  RESD                 1
      .SS                   RESD                 1
      .PD                   REST                 1
      .SCIEZKA:             RESB                 138
      .NAZWA:               RESB                 11
endstruc



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;; struktura poczatku programu';;;;;;;;

struc STRUKTURA_POCZATKU_PROGRAMU
      .TSS                       resb                104
      .IDENTYFIKATOR_PROCESU     resb                170
      .LDT                       resb                160
      .POCZATEK_KODU             RESB                1
endstruc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

struc KOLEJKA_ZADAN
      .POCZATEK    RESD                     1
      .KONIEC      RESD                     1
      .ADRES_PULI  RESD                     1
endstruc

struc KOLEJKA_ZADAN_WSTRZYMANYCH
      .POCZATEK                 RESD        1
      .KONIEC                   RESD        1
      .ADRES_PULI               RESD        1
endstruc
