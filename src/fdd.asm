struc BUFOR_DYSKIETKI
      .BUFOR1              resb  512
      .BUFOR2              resb  512
endstruc

struc WYNIKI_KONCOWE
      .BAJT1 resb 1
      .BAJT2 resb 1
      .BAJT3 resb 1
      .BAJT4 resb 1
      .BAJT5 resb 1
      .BAJT6 resb 1
      .BAJT7 resb 1
      .BAJT8 resb 1
      .BAJT9 resb 1
endstruc

wyniki_koncowe times 9 db  0

SYSTEM_ODCZYT_SEKTORA_LICZNIK_BLEDOW DB 0
SYSTEM_ZAPIS_SEKTORA_LICZNIK_BLEDOW DB 0

struc STACJE_FDD
  .FDD0         resb 1
  .FDD1         resb 1
endstruc

stacje_fdd times 2 db     0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;; sta�e dla fdd 1.44 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%define step_rate             0ch     ;okres impuls�w silnika krokowego
%define head_unload_time      1h      ;czas roz�adowania g�owic
%define head_load_time        4h      ;czas �adowania g�owic
bufor db 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa$'
ile_sektorow_na_sciezke   dw	12h
ile_glowic		  dw	2h
ile_sciezek               dw  80
czy_recalibrate_lub_seek  db  0
znacznik_przerwania_fdd   db  0
licznik_bledow            db  0

%macro SPRAWDZENIE_GOTOWOSCI_2 0
;Makro okre�la, czy uk�ad FDC jest gotowy do przes�ania danych
  pusha
  mov dx, 3f4h
  %%nie_gotowy:
  in al, dx         ;Odczyt warto�ci g��wnego rejestru stanu FDC
  sal al, 1
  jnc %%nie_gotowy  ;Gotowo�� uk�adu
  sal al, 1
  jnc %%nie_gotowy  ;Kierunek danych od FDC do CPU
popa
%endmacro

CZEKAJ_NA_PRZERWANIE_FDD
;Procedura oczekuje na wyst�pienie przerwania stacji dyskietek.
  PUSHA
  mov ax, ds
  push eax
  mov ax, 24
  mov ds, ax
  .petla:
    mov al, [znacznik_przerwania_fdd]
    cmp al, 1
    je .koniec
    jmp .petla
  .koniec:
  mov byte [znacznik_przerwania_fdd], 0
  pop eax
  mov ds, ax
  POPA
RET

SENSE_INTERUPT_STATUS
;Komendy pozycjonowania i rekalibracji nie posiadaj� fazy ko�cowej, w celu
;uzyskania wynik�w tych komend nale�y u�y� procedury SENSE_INTERUPT_STATUS
  PUSHA
  mov al, 00001000b
  mov dx, 3f5h         ; adres portu danych
  SPRAWDZENIE_GOTOWOSCI
  out dx, al
  mov dx, 3f5h
  SPRAWDZENIE_GOTOWOSCI_2
  in al, dx
  mov [wyniki_koncowe + WYNIKI_KONCOWE.BAJT1], AL
  mov dx, 3f5h
  SPRAWDZENIE_GOTOWOSCI_2
  in al, dx
  mov [wyniki_koncowe + WYNIKI_KONCOWE.BAJT2], AL
  POPA
RET

ODCZYT_REJESTRU_STANU
;Procedura odczytuje g��wny rejestr stanu FDC (zapisuje go do zmiennej
;wyniki_koncowe).
  PUSHA
  mov dx, 3f4h
  in al, dx
  mov [wyniki_koncowe + WYNIKI_KONCOWE.BAJT1], al
  POPA
RET

%macro SPRAWDZENIE_GOTOWOSCI 0
;Makro sprawdza gotowo�� uk�adu do odebrania danych od CPU.
  PUSHA
  mov dx, 3f4h
  %%nie_gotowy:
    in al, dx
    and al, 0c0h       ;pozostawienie dw�ch najstarszych bit�w
    cmp al, 80h        ;sprawdzenie gotowo�ci uk�adu - kierunek danych od CPU do FDC
  jne %%nie_gotowy
  POPA
%endmacro

SEEK
;Procedura przekazuje kontrolerowi FDC rozkaz powoduj�cy ustawienie g�owic
;nap�du FDD na w�a�ciwej pozycji.
;Parametry procedury:
;Rejestr EBX:
;BL - nr nap�du,
;BH - nr g�owicy,
;Bity 16-23 - nr �cie�ki
;Rozkaz SEEK sk�ada si� z 3 bajt�w:
; 1 - sygnatura rozkazu (ustawione 4 pierwsze bity)
; 2 - numer dysku (2 pierwsze bity), numer g�owicy (bit 3),
; 3 - numer �cie�ki
  PUSHA
  MOV ECX, EBX
  mov al, 01111b
  mov dx, 3f5h         ; adres portu danych
  SPRAWDZENIE_GOTOWOSCI
  out dx, al
  mov al, bh     ; BIT 2 NR GLOWICY BITY 0-1 NR NAPEDU
  shl al, 2
  or al, bl
  SPRAWDZENIE_GOTOWOSCI
  out dx, al
  shr ebx, 8
  mov al, bh     ; nr �cie�ki
  SPRAWDZENIE_GOTOWOSCI
  out dx, al
  MOV EBX, ECX
POPA
RET


USTAW_PREDKOSC_FDD
;Procedura usawia pr�dko�� komunikacji FDC z nap�dem fizycznym.
  PUSHA
  XOR AL, AL
  mov al, 0b     ;500kb/s
  MOV DX, 3F7H
  OUT DX, AL
  POPA
RET

USTAWIENIE_PARAMETROW_FDD 
;Procedura ma za zadanie ustawi� podstawowe parametery kontrolera stacji dyskietek
;(czas �adowania g�owic, czas roz�adowania g�owic, okres impuls�w silnika krokowego).
  PUSHA
  mov dx, 3f5h         ;adres portu danych
  mov al, 11b          ;komenda control commands
  SPRAWDZENIE_GOTOWOSCI
  out dx, al
  mov al, step_rate
  shl al, 4
  or al, head_unload_time
  MOV AL, 0Dfh
  SPRAWDZENIE_GOTOWOSCI
  out dx, al
  mov al, head_load_time
  mov al, 2              ;tryb DMA
  SPRAWDZENIE_GOTOWOSCI
  out dx, al
POPA
RET


PROGRAMOWANIE_DMA:
;Procedura przygotowuje uk�ad DMA do wsp�pracy z FDC.
;Parametry procedury:
;AL - gdy r�wny 0 oznacza, �e b�dzie nast�powa� zapis do pami�ci, przeciwnie - odczyt z pami�ci.
  PUSHA
;Ustalenie odpowiedniego kierunku przesy�ania danych:
  cmp al, 0
  je .dalej
  mov ah, 00001000b        ; odczyt
  jmp .koniec
  .dalej:
  mov ah, 00000100b        ; zapis
  .koniec:
     ;    si rwk         s-single, inkrementacja, r-odczyt, w-zapis, k-kanal
  or ah, 01000010b
;DMA posiada rejestr maski kana��w, umo�liwiaj�cy zablokowanie lub odblokowanie ka�dego z nich.
;Rejstr dost�pny jest przez port 0Ah, na kt�ry nale�y wys�a� bajt o nast�puj�cym formacie:
;bity 0-1 - numer kana�u,
;bit 2 - gdy ustawiony nast�puje zablokowanie kana�u, gdy wyzerowany - odblokowanie.
  mov al, 110b       ; 1- zablokowanie kana�u drugiego
  out 0ah, al
;Tryb pracy DMA ustawiany jest przez port 0BH. Format bajtu:
;bity 0-1 - numer kana�u,
;bity 2-3 - kierunek transmisji,
;bit 4 - praca uk�adu w trybie samoprogramowania,
;bit 5 - inkrementacja lub dekrementacja licznika transmisji,
;bity 6-7 - tryb pracy kontrolera.
  shr ax, 8
  out 0bh, al   ; ustawienie trybu pracy
  mov al, 1
  out 81h, al  ; strona pierwsza - od 64 kb
  out 0ch, al
  shr al, 1
  out 04h, al  ; zerowy offset
  out 04h, al
  out 0ch, al
  not al
  out 5h, al  ; rejestr licznika
  mov al, 1
  out 5h, al  ; starszy bajt
  inc al
  out 0ah, al  ; odblokowanie kanalu drugiego
  POPA
ret

RESET_FDC
  xor al, al
  mov dx, 3f2h
  out dx, al
RET


IRQ_I_FDC
;Zadaniem procedury jest uruchomienie silnika odpowiedniego nap�du stacji dyskietek,
;oraz okre�lenie trybu pracy (czy transmisjia b�dzie si� odbywa�a z udzia�em DMA
;czy te� nie).
;Parametry procedury:
;CL - numer nap�du
  mov dx, 3f2h
  xor ax, ax
  mov al, 11100b
  or al, cl           ; numer napedu
  out dx, al
ret

WYLACZENIE_NAPEDU
;Procedura wy��cza nap�d stacji dyskietek.
;Parametry proceudry:
;AL - numer nap�du.
  and al, 1100b     ; z dma
  mov dx, 3f2h
  out dx, al
ret


REKALIBRUJ
;Procedura przekazuje uk�adowi FDC rozkaz rekalibracji wybranego nap�du.
;Format rozkazu rekalibracji:
;bajt 1 - sygnatura rozkazu (111b),
;bajt 2 - na dw�ch ostatnich bitach numer nap�du.
  PUSHA
  mov dx, 3F5H
  mov al, 111b
  SPRAWDZENIE_GOTOWOSCI
  out dx, al
  xor al,al
  SPRAWDZENIE_GOTOWOSCI
  out dx, al
  POPA
RET

FAZA_PRZESYLANIA_KOMENDY_READ_DATA
;Procedura przekazuje uk�adowi FDC rozkaz odczytu sektora.
;Format rozkazu:
;bajt 1 - bity 0-4 o warto�ci 00110, bit 5 - spos�b reakcji na odczyt sektora oznaczonego
;jako skasowany (1 - brak reakcji, 0 - wyst�pienie b��du), bit 6 format MFM lub FM,
;bit 7 - czytanie obustronne;
;bajt 2 - bity 0-1 - numer nap�du, bit 2 - numer g�owicy,
;bajt 3 - numer �cie�ki,
;bajt 4 - bit 0 - numer g�owicy,
;bajt 5 - numer sektora,
;bajt 6 - wielko�� sektora (dla sektora o wielko�ci 512B - 010B),
;bajt 7 - numer ostatniego sektora,
;bajt 8 - rozmiar szczeliny synchronizacyjnej (odleg�o�� mi�dzy sektorami),
;bajt 9 - 0ffh
;Parametry procedury:
;BL - nr nap�du
;BH - nr g�owicy
;bity 15-23 rejestru EBX - �cie�ka
;bity 24-31 rejestru EBX - sektor
  mov al, 01100110b
  mov dx, 3f5h         ;adres portu danych
  SPRAWDZENIE_GOTOWOSCI
  out dx, al
  mov al, bh     ;bit 2 nr g�owicy bity 0-1 nr nap�du
  shl al, 2
  or al, bl
  SPRAWDZENIE_GOTOWOSCI
  out dx, al
  shr ebx, 8
  mov al, bh     ; nr �cie�ki
  SPRAWDZENIE_GOTOWOSCI
  out dx, al

  mov al, bl   ; nr g�owicy
  SPRAWDZENIE_GOTOWOSCI
  out dx, al

  shr ebx, 8
  mov al, bh  ;nr sektora
  SPRAWDZENIE_GOTOWOSCI
  out dx, al

  mov al, 010b ;rozmiar sektora - 512 B
  SPRAWDZENIE_GOTOWOSCI
  out dx, al

  mov al, bh ; nr ostatniego sektora (ten sam co numer pierwszego)
  SPRAWDZENIE_GOTOWOSCI
  out dx, al

  mov al, 27 ;rozmiar szczeliny synchronizacyjnej
  SPRAWDZENIE_GOTOWOSCI
  out dx, al

  mov al, 0ffh     ;sygnatura IBM PC
  SPRAWDZENIE_GOTOWOSCI
  out dx, al
ret


FAZA_PRZESYLANIA_KOMENDY_WRITE_DATA
;Procedura wysy�a do kontrolera FDC komend� zapisu sektora
;Parametry procedury:
;BL - nr nap�du
;BH - nr g�owicy
;bity 15-23 rejestru EBX - �cie�ka
;bity 24-31 rejestru EBX - sektor
  mov al, 01000101b
  mov dx, 3f5h         ; adres portu danych
  SPRAWDZENIE_GOTOWOSCI
  out dx, al

  mov al, bh     ;bit 2 - nr g�owicy, bity 0-1 - nr nap�du
  shl al, 2
  or al, bl
  SPRAWDZENIE_GOTOWOSCI
  out dx, al

  shr ebx, 8
  mov al, bh     ;nr �cie�ki
  SPRAWDZENIE_GOTOWOSCI
  out dx, al

  mov al, bl   ;nr g�owicy
  SPRAWDZENIE_GOTOWOSCI
  out dx, al

  shr ebx, 8
  mov al, bh  ;nr sektora
  SPRAWDZENIE_GOTOWOSCI
  out dx, al

  mov al, 010b ;rozmiar sektora - 512 B
  SPRAWDZENIE_GOTOWOSCI
  out dx, al

  mov al, bh ;nr ostatniego sektora - ten sam co pierwszy
  SPRAWDZENIE_GOTOWOSCI
  out dx, al

  mov al, 27 ;rozmiar szczeliny synchronizacyjnej
  SPRAWDZENIE_GOTOWOSCI
  out dx, al

  mov al, 0ffh     ;sygnatura IBM PC
  SPRAWDZENIE_GOTOWOSCI
  out dx, al
ret


FAZA_KONCOWA_KOMENDY
;Procedura odczytuje wyniki ko�cowe wykonanych rozkaz�w.
;Parametry procedury:
;ECX - liczba zwracanych bajt�w.
;Wyniki:
;Zmienna wyniki_koncowe b�dzie przechowywa�a dane zwr�cone przez FDC.
  pusha
  xor edi, edi
  .petla:
    mov dx, 3f5h
    SPRAWDZENIE_GOTOWOSCI_2
    in al, dx
    mov [wyniki_koncowe+ edi], al
    inc edi
  loop .petla
popa
ret

CHS:
;Procedura zamienia numer sektora na jego adres w formacie CHS.
;Parametry procedury:
;DX - numer sektora.
;Wyniki:
;CL - numer sektora,
;CH - numer �cie�ki,
;DH - numer g�owicy.
  PUSH ebx
  mov ax, dx
  mov bx, dx
  xor dx, dx
  mov cx, [ile_sektorow_na_sciezke]
  div cx
  inc dx
  push dx
  xor dx, dx
  mov cx, [ile_glowic]
  div cx
  pop cx
  mov ch, al
  mov dh, dl
  xor dl, dl
  POP ebx
RET

NORMALIZACJA_PO_CHS 
;Procedura ma za zadanie przystosowa� foramt wynik�w zwracanych przez procedur�
;CHS do formatu wymaganego przez procedury odczytu i zapisu sektora.
  mov bh, cl
  mov bl, ch
  shl ebx, 10h
  mov bx, dx
ret


FORMATUJ_SCIEZKE
;Procedura ma za zadanie wys�a� do kontrolera FDC rozkaz formatowania �cie�ki.
;Rozkaz formatowania sk�ada si� z 6 bajt�w:
;bajt 1 - bity 0-5 - sygnatura rozkazu (001101b), bit 6 - tryb MFM,
;bajt 2 - bity 0-1 - numer nap�du, bit 2 - numer g�owicy,
;bajt 3 - roziar sektora,
;bajt 4 - liczba sektor�w do sformatowania,
;bajt 5 - rozmiar szczeliny synchronizacyjnej,
;bajt 6 - zawarto��, kt�r� wype�niane b�d� sektory.
;Parametry procedury:
;BL - nr nap�du
;BH - nr g�owicy
;bity 15-23 rejestru EBX - nr �cie�ki
  PUSHA
  mov ah, bh    ;nr g�owicy
  shl ah, 2
  or ah, bl     ;nr nap�du
  shr ebx, 16
  mov al, bl    ;nr �cie�ki
;Poniewa� kontroler b�dzie formatowa� dysk w trybie DMA, nale�y przygotowa�
;obszar danych, kt�re uk�ad DMA b�dzie przekazywa� do kontrolera FDC:
  mov ecx, 18    ;ile_sektorow_na_sciezke
  mov dl, 1
  .petla_zapisu_danych_formatowania:
    push eax
    stosb        ;nr �cie�ki
    shr ah, 2
    mov al, ah
    stosb       ;nr g�owicy
    mov al, dl
    inc dl      ;nast�pny cykl formatowania zostanie rozpocz�ty od kolejnego sektora
    stosb
    mov al, 010b  ;rozmiar sektora (512 B)
    stosb
    pop eax
  loop .petla_zapisu_danych_formatowania
  push eax
;Programowanie DMA na odczyt danych z pami�ci:
  mov al, 1
  call PROGRAMOWANIE_DMA
  pop eax
  mov dx, 3f5h         ; adres portu danych

;Przekazanie kontrolerowi FDC 6 bajt�w komendy formatowania:
  mov al, 01001101b
  SPRAWDZENIE_GOTOWOSCI
  out dx, al

  mov al, ah
  SPRAWDZENIE_GOTOWOSCI
  out dx, al

  mov al, 010b
  SPRAWDZENIE_GOTOWOSCI
  out dx, al
  
  mov al, 18
  SPRAWDZENIE_GOTOWOSCI
  out dx, al

  mov al, 54h             
  SPRAWDZENIE_GOTOWOSCI
  out dx, al
  
  mov al, 7
  SPRAWDZENIE_GOTOWOSCI
  out dx, al
;Oczekiwanie na wyst�pienie przerwania stacji dysk�w:
  MOV BYTE [znacznik_przerwania_fdd], 0
  CALL CZEKAJ_NA_PRZERWANIE_FDD
;Faza ko�cowa komendy formatowania:
  mov ecx, 7
  call FAZA_KONCOWA_KOMENDY
POPA
RET

FORMATUJ_CALY_DYSK
;Procedura formatuje ca�� dyskietk�.
  PUSHA
  mov ecx, 80*2           ; liczba sektor�w
  mov dl, 0               ; numer pierwszej �cie�ki
  .PETLA_FORMATOWANIA:
    mov ax, [POLOZENIE_DESKRYPTORA_ADRESU_LINIOWEGO]
    mov es, ax
    mov edi, 10000h
    
    MOV BYTE [znacznik_przerwania_fdd], 0
    call SEEK
    CALL CZEKAJ_NA_PRZERWANIE_FDD
    call FORMATUJ_SCIEZKE
    add ebx, 00010000h       ;kolejna �cie�ka
    cmp ebx, 00500000h       ;okre�lenie numeru g�owicy
    jne .dalej
      and ebx, 0ffffh
      mov bh, 1
    .dalej:
  loop .PETLA_FORMATOWANIA
  POPA
RET


INICJALIZUJ_FDD
;Procedura inicjalizuje kontroler FDC.
  pusha
  mov byte [znacznik_przerwania_fdd], 0      ;wyzerowanie zmienne przechowuj�cej informacj� o wyst�pieniu przerwania 6
  CALL RESET_FDC                             ;reset FDC
  xor cl, cl
  CALL IRQ_I_FDC                             ;uruchomienie silnika stacji A, ustawienie trybu DMA
  CALL USTAW_PREDKOSC_FDD                    ;ustalenie pr�dko�ci transmisji FDC
  CALL CZEKAJ_NA_PRZERWANIE_FDD              ;oczekiwanie na osi�gni�cie w�a�ciwej pr�dko�ci
  CALL SENSE_INTERUPT_STATUS
  CALL USTAWIENIE_PARAMETROW_FDD             ;ustalenie czas�w op�nie� g�owicy, okresu impuls�w silnika krokowego
  ;mov byte [znacznik_przerwania_fdd], 0
  ;CALL REKALIBRUJ
  ;CALL CZEKAJ_NA_PRZERWANIE_FDD
  popa
RET


SYSTEM_ODCZYT_SEKTORA
;Procedura odczytuje sektor dyskietki do pierwszych 512 bajt�w pierwszej strony
;DMA (pierwsza strona DMA rozpoczyna si� od 64KB).
;Parametry:
;DX - numer sektora
  push ebx
  push ecx
  push edx
  push edi
  push esi
;Wyzerowanie licznika b��d�w:
  mov byte [SYSTEM_ODCZYT_SEKTORA_LICZNIK_BLEDOW], 0
  .POWROT_SYSTEM_ODCZYT_SEKTORA
  push edx
  MOV BYTE [znacznik_przerwania_fdd], 0
  call CHS
  call NORMALIZACJA_PO_CHS
  push ebx
  mov byte [znacznik_przerwania_fdd], 0
  CALL SEEK                           ;ustawienie g�owicy nad w�a�ciw� �cie�k�
  CALL CZEKAJ_NA_PRZERWANIE_FDD
  call SENSE_INTERUPT_STATUS
  mov al, 0
  CALL PROGRAMOWANIE_DMA              ;programowanie DMA (zapis do pami�ci)
  pop ebx
  MOV BYTE [znacznik_przerwania_fdd], 0
  call FAZA_PRZESYLANIA_KOMENDY_READ_DATA
  xor ecx, ecx
  mov cx, 7
  call FAZA_KONCOWA_KOMENDY
  mov ax, [wyniki_koncowe+WYNIKI_KONCOWE.BAJT1]
  test ax, 11000000b
  jz .wykonanie_ok
  pop edx
;Gdy pr�ba odczytu nie uda si�, nast�puje inkrementacja licznika b��d�w,
;oraz sprawdzenie, czy nie przekroczy� on dopuszczalnej liczby b��d�w odczytu:
  INC BYTE [ SYSTEM_ODCZYT_SEKTORA_LICZNIK_BLEDOW ]
  mov ax,  [ SYSTEM_ODCZYT_SEKTORA_LICZNIK_BLEDOW ]
  cmp ax, 5
  ja .zle_wykonanie
  call CZEKAJ_NA_PRZERWANIE_FDD
  jmp   .POWROT_SYSTEM_ODCZYT_SEKTORA
  .wykonanie_ok:
  pop edx
    mov eax, 1
  jmp .koniec
  .zle_wykonanie:
  xor eax, eax
  .koniec
  pop esi
  pop edi
  pop edx
  pop ecx
  pop ebx
RET

SYSTEM_ZAPIS_SEKTORA
;Procedura zapisuje sektor dyskietki z pierwszych 512 bajt�w pierwszej strony
;DMA (pierwsza strona DMA rozpoczyna si� od 64KB).
;Parametry:
;DX - numer sektora
  push ebx
  push ecx
  push edx
  push edi
  push esi
  mov byte [SYSTEM_ZAPIS_SEKTORA_LICZNIK_BLEDOW], 0   ;wyczyszczenie licznika b��d�w zapisu
  .POWROT_SYSTEM_ZAPIS_SEKTORA
  push edx
  MOV BYTE [znacznik_przerwania_fdd], 0
  call CHS
  call NORMALIZACJA_PO_CHS
  push ebx
  CALL SEEK                                       ;ustawienie g�owicy nad w�a�ciw� �cie�k�
  CALL CZEKAJ_NA_PRZERWANIE_FDD
  mov al, 1
  CALL PROGRAMOWANIE_DMA                          ;programowanie DMA na odczyt z pami�ci
  pop ebx
  CALL FAZA_PRZESYLANIA_KOMENDY_WRITE_DATA
  mov ecx, 7
  MOV BYTE [znacznik_przerwania_fdd], 0
  call FAZA_KONCOWA_KOMENDY
  mov ax, [wyniki_koncowe+WYNIKI_KONCOWE.BAJT1]
  test ax, 11000000b
  jz .wykonanie_ok
  pop edx
;Gdy pr�ba zapisu nie uda si�, nast�puje inkrementacja licznika b��d�w,
;oraz sprawdzenie, czy nie przekroczy� on dopuszczalnej liczby b��d�w zapisu:
  INC BYTE [ SYSTEM_ZAPIS_SEKTORA_LICZNIK_BLEDOW ]
  mov ax,  [ SYSTEM_ZAPIS_SEKTORA_LICZNIK_BLEDOW ]
  cmp ax, 5
  ja .zle_wykonanie
  MOV BYTE [znacznik_przerwania_fdd], 0
  CALL REKALIBRUJ
  call CZEKAJ_NA_PRZERWANIE_FDD
  jmp   .POWROT_SYSTEM_ZAPIS_SEKTORA
  .wykonanie_ok:
  pop edx
    mov eax, 1
  jmp .koniec
  .zle_wykonanie:
  xor eax, eax
  .koniec
  pop esi
  pop edi
  pop edx
  pop ecx
  pop ebx
RET

SYSTEM_FORMATUJ_DYSK
  call FORMATUJ_CALY_DYSK
RET
