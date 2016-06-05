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
;;;;;;;;;;;;;;;;;;;;; sta³e dla fdd 1.44 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%define step_rate             0ch     ;okres impulsów silnika krokowego
%define head_unload_time      1h      ;czas roz³adowania g³owic
%define head_load_time        4h      ;czas ³adowania g³owic
bufor db 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa$'
ile_sektorow_na_sciezke   dw	12h
ile_glowic		  dw	2h
ile_sciezek               dw  80
czy_recalibrate_lub_seek  db  0
znacznik_przerwania_fdd   db  0
licznik_bledow            db  0

%macro SPRAWDZENIE_GOTOWOSCI_2 0
;Makro okreœla, czy uk³ad FDC jest gotowy do przes³ania danych
  pusha
  mov dx, 3f4h
  %%nie_gotowy:
  in al, dx         ;Odczyt wartoœci g³ównego rejestru stanu FDC
  sal al, 1
  jnc %%nie_gotowy  ;Gotowoœæ uk³adu
  sal al, 1
  jnc %%nie_gotowy  ;Kierunek danych od FDC do CPU
popa
%endmacro

CZEKAJ_NA_PRZERWANIE_FDD
;Procedura oczekuje na wyst¹pienie przerwania stacji dyskietek.
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
;Komendy pozycjonowania i rekalibracji nie posiadaj¹ fazy koñcowej, w celu
;uzyskania wyników tych komend nale¿y u¿yæ procedury SENSE_INTERUPT_STATUS
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
;Procedura odczytuje g³ówny rejestr stanu FDC (zapisuje go do zmiennej
;wyniki_koncowe).
  PUSHA
  mov dx, 3f4h
  in al, dx
  mov [wyniki_koncowe + WYNIKI_KONCOWE.BAJT1], al
  POPA
RET

%macro SPRAWDZENIE_GOTOWOSCI 0
;Makro sprawdza gotowoœæ uk³adu do odebrania danych od CPU.
  PUSHA
  mov dx, 3f4h
  %%nie_gotowy:
    in al, dx
    and al, 0c0h       ;pozostawienie dwóch najstarszych bitów
    cmp al, 80h        ;sprawdzenie gotowoœci uk³adu - kierunek danych od CPU do FDC
  jne %%nie_gotowy
  POPA
%endmacro

SEEK
;Procedura przekazuje kontrolerowi FDC rozkaz powoduj¹cy ustawienie g³owic
;napêdu FDD na w³aœciwej pozycji.
;Parametry procedury:
;Rejestr EBX:
;BL - nr napêdu,
;BH - nr g³owicy,
;Bity 16-23 - nr œcie¿ki
;Rozkaz SEEK sk³ada siê z 3 bajtów:
; 1 - sygnatura rozkazu (ustawione 4 pierwsze bity)
; 2 - numer dysku (2 pierwsze bity), numer g³owicy (bit 3),
; 3 - numer œcie¿ki
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
  mov al, bh     ; nr œcie¿ki
  SPRAWDZENIE_GOTOWOSCI
  out dx, al
  MOV EBX, ECX
POPA
RET


USTAW_PREDKOSC_FDD
;Procedura usawia prêdkoœæ komunikacji FDC z napêdem fizycznym.
  PUSHA
  XOR AL, AL
  mov al, 0b     ;500kb/s
  MOV DX, 3F7H
  OUT DX, AL
  POPA
RET

USTAWIENIE_PARAMETROW_FDD 
;Procedura ma za zadanie ustawiæ podstawowe parametery kontrolera stacji dyskietek
;(czas ³adowania g³owic, czas roz³adowania g³owic, okres impulsów silnika krokowego).
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
;Procedura przygotowuje uk³ad DMA do wspó³pracy z FDC.
;Parametry procedury:
;AL - gdy równy 0 oznacza, ¿e bêdzie nastêpowa³ zapis do pamiêci, przeciwnie - odczyt z pamiêci.
  PUSHA
;Ustalenie odpowiedniego kierunku przesy³ania danych:
  cmp al, 0
  je .dalej
  mov ah, 00001000b        ; odczyt
  jmp .koniec
  .dalej:
  mov ah, 00000100b        ; zapis
  .koniec:
     ;    si rwk         s-single, inkrementacja, r-odczyt, w-zapis, k-kanal
  or ah, 01000010b
;DMA posiada rejestr maski kana³ów, umo¿liwiaj¹cy zablokowanie lub odblokowanie ka¿dego z nich.
;Rejstr dostêpny jest przez port 0Ah, na który nale¿y wys³aæ bajt o nastêpuj¹cym formacie:
;bity 0-1 - numer kana³u,
;bit 2 - gdy ustawiony nastêpuje zablokowanie kana³u, gdy wyzerowany - odblokowanie.
  mov al, 110b       ; 1- zablokowanie kana³u drugiego
  out 0ah, al
;Tryb pracy DMA ustawiany jest przez port 0BH. Format bajtu:
;bity 0-1 - numer kana³u,
;bity 2-3 - kierunek transmisji,
;bit 4 - praca uk³adu w trybie samoprogramowania,
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
;Zadaniem procedury jest uruchomienie silnika odpowiedniego napêdu stacji dyskietek,
;oraz okreœlenie trybu pracy (czy transmisjia bêdzie siê odbywa³a z udzia³em DMA
;czy te¿ nie).
;Parametry procedury:
;CL - numer napêdu
  mov dx, 3f2h
  xor ax, ax
  mov al, 11100b
  or al, cl           ; numer napedu
  out dx, al
ret

WYLACZENIE_NAPEDU
;Procedura wy³¹cza napêd stacji dyskietek.
;Parametry proceudry:
;AL - numer napêdu.
  and al, 1100b     ; z dma
  mov dx, 3f2h
  out dx, al
ret


REKALIBRUJ
;Procedura przekazuje uk³adowi FDC rozkaz rekalibracji wybranego napêdu.
;Format rozkazu rekalibracji:
;bajt 1 - sygnatura rozkazu (111b),
;bajt 2 - na dwóch ostatnich bitach numer napêdu.
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
;Procedura przekazuje uk³adowi FDC rozkaz odczytu sektora.
;Format rozkazu:
;bajt 1 - bity 0-4 o wartoœci 00110, bit 5 - sposób reakcji na odczyt sektora oznaczonego
;jako skasowany (1 - brak reakcji, 0 - wyst¹pienie b³êdu), bit 6 format MFM lub FM,
;bit 7 - czytanie obustronne;
;bajt 2 - bity 0-1 - numer napêdu, bit 2 - numer g³owicy,
;bajt 3 - numer œcie¿ki,
;bajt 4 - bit 0 - numer g³owicy,
;bajt 5 - numer sektora,
;bajt 6 - wielkoœæ sektora (dla sektora o wielkoœci 512B - 010B),
;bajt 7 - numer ostatniego sektora,
;bajt 8 - rozmiar szczeliny synchronizacyjnej (odleg³oœæ miêdzy sektorami),
;bajt 9 - 0ffh
;Parametry procedury:
;BL - nr napêdu
;BH - nr g³owicy
;bity 15-23 rejestru EBX - œcie¿ka
;bity 24-31 rejestru EBX - sektor
  mov al, 01100110b
  mov dx, 3f5h         ;adres portu danych
  SPRAWDZENIE_GOTOWOSCI
  out dx, al
  mov al, bh     ;bit 2 nr g³owicy bity 0-1 nr napêdu
  shl al, 2
  or al, bl
  SPRAWDZENIE_GOTOWOSCI
  out dx, al
  shr ebx, 8
  mov al, bh     ; nr œcie¿ki
  SPRAWDZENIE_GOTOWOSCI
  out dx, al

  mov al, bl   ; nr g³owicy
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
;Procedura wysy³a do kontrolera FDC komendê zapisu sektora
;Parametry procedury:
;BL - nr napêdu
;BH - nr g³owicy
;bity 15-23 rejestru EBX - œcie¿ka
;bity 24-31 rejestru EBX - sektor
  mov al, 01000101b
  mov dx, 3f5h         ; adres portu danych
  SPRAWDZENIE_GOTOWOSCI
  out dx, al

  mov al, bh     ;bit 2 - nr g³owicy, bity 0-1 - nr napêdu
  shl al, 2
  or al, bl
  SPRAWDZENIE_GOTOWOSCI
  out dx, al

  shr ebx, 8
  mov al, bh     ;nr œcie¿ki
  SPRAWDZENIE_GOTOWOSCI
  out dx, al

  mov al, bl   ;nr g³owicy
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
;Procedura odczytuje wyniki koñcowe wykonanych rozkazów.
;Parametry procedury:
;ECX - liczba zwracanych bajtów.
;Wyniki:
;Zmienna wyniki_koncowe bêdzie przechowywa³a dane zwrócone przez FDC.
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
;CH - numer œcie¿ki,
;DH - numer g³owicy.
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
;Procedura ma za zadanie przystosowaæ foramt wyników zwracanych przez procedurê
;CHS do formatu wymaganego przez procedury odczytu i zapisu sektora.
  mov bh, cl
  mov bl, ch
  shl ebx, 10h
  mov bx, dx
ret


FORMATUJ_SCIEZKE
;Procedura ma za zadanie wys³aæ do kontrolera FDC rozkaz formatowania œcie¿ki.
;Rozkaz formatowania sk³ada siê z 6 bajtów:
;bajt 1 - bity 0-5 - sygnatura rozkazu (001101b), bit 6 - tryb MFM,
;bajt 2 - bity 0-1 - numer napêdu, bit 2 - numer g³owicy,
;bajt 3 - roziar sektora,
;bajt 4 - liczba sektorów do sformatowania,
;bajt 5 - rozmiar szczeliny synchronizacyjnej,
;bajt 6 - zawartoœæ, któr¹ wype³niane bêd¹ sektory.
;Parametry procedury:
;BL - nr napêdu
;BH - nr g³owicy
;bity 15-23 rejestru EBX - nr œcie¿ki
  PUSHA
  mov ah, bh    ;nr g³owicy
  shl ah, 2
  or ah, bl     ;nr napêdu
  shr ebx, 16
  mov al, bl    ;nr œcie¿ki
;Poniewa¿ kontroler bêdzie formatowa³ dysk w trybie DMA, nale¿y przygotowaæ
;obszar danych, które uk³ad DMA bêdzie przekazywa³ do kontrolera FDC:
  mov ecx, 18    ;ile_sektorow_na_sciezke
  mov dl, 1
  .petla_zapisu_danych_formatowania:
    push eax
    stosb        ;nr œcie¿ki
    shr ah, 2
    mov al, ah
    stosb       ;nr g³owicy
    mov al, dl
    inc dl      ;nastêpny cykl formatowania zostanie rozpoczêty od kolejnego sektora
    stosb
    mov al, 010b  ;rozmiar sektora (512 B)
    stosb
    pop eax
  loop .petla_zapisu_danych_formatowania
  push eax
;Programowanie DMA na odczyt danych z pamiêci:
  mov al, 1
  call PROGRAMOWANIE_DMA
  pop eax
  mov dx, 3f5h         ; adres portu danych

;Przekazanie kontrolerowi FDC 6 bajtów komendy formatowania:
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
;Oczekiwanie na wyst¹pienie przerwania stacji dysków:
  MOV BYTE [znacznik_przerwania_fdd], 0
  CALL CZEKAJ_NA_PRZERWANIE_FDD
;Faza koñcowa komendy formatowania:
  mov ecx, 7
  call FAZA_KONCOWA_KOMENDY
POPA
RET

FORMATUJ_CALY_DYSK
;Procedura formatuje ca³¹ dyskietkê.
  PUSHA
  mov ecx, 80*2           ; liczba sektorów
  mov dl, 0               ; numer pierwszej œcie¿ki
  .PETLA_FORMATOWANIA:
    mov ax, [POLOZENIE_DESKRYPTORA_ADRESU_LINIOWEGO]
    mov es, ax
    mov edi, 10000h
    
    MOV BYTE [znacznik_przerwania_fdd], 0
    call SEEK
    CALL CZEKAJ_NA_PRZERWANIE_FDD
    call FORMATUJ_SCIEZKE
    add ebx, 00010000h       ;kolejna œcie¿ka
    cmp ebx, 00500000h       ;okreœlenie numeru g³owicy
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
  mov byte [znacznik_przerwania_fdd], 0      ;wyzerowanie zmienne przechowuj¹cej informacjê o wyst¹pieniu przerwania 6
  CALL RESET_FDC                             ;reset FDC
  xor cl, cl
  CALL IRQ_I_FDC                             ;uruchomienie silnika stacji A, ustawienie trybu DMA
  CALL USTAW_PREDKOSC_FDD                    ;ustalenie prêdkoœci transmisji FDC
  CALL CZEKAJ_NA_PRZERWANIE_FDD              ;oczekiwanie na osi¹gniêcie w³aœciwej prêdkoœci
  CALL SENSE_INTERUPT_STATUS
  CALL USTAWIENIE_PARAMETROW_FDD             ;ustalenie czasów opóŸnieñ g³owicy, okresu impulsów silnika krokowego
  ;mov byte [znacznik_przerwania_fdd], 0
  ;CALL REKALIBRUJ
  ;CALL CZEKAJ_NA_PRZERWANIE_FDD
  popa
RET


SYSTEM_ODCZYT_SEKTORA
;Procedura odczytuje sektor dyskietki do pierwszych 512 bajtów pierwszej strony
;DMA (pierwsza strona DMA rozpoczyna siê od 64KB).
;Parametry:
;DX - numer sektora
  push ebx
  push ecx
  push edx
  push edi
  push esi
;Wyzerowanie licznika b³êdów:
  mov byte [SYSTEM_ODCZYT_SEKTORA_LICZNIK_BLEDOW], 0
  .POWROT_SYSTEM_ODCZYT_SEKTORA
  push edx
  MOV BYTE [znacznik_przerwania_fdd], 0
  call CHS
  call NORMALIZACJA_PO_CHS
  push ebx
  mov byte [znacznik_przerwania_fdd], 0
  CALL SEEK                           ;ustawienie g³owicy nad w³aœciw¹ œcie¿k¹
  CALL CZEKAJ_NA_PRZERWANIE_FDD
  call SENSE_INTERUPT_STATUS
  mov al, 0
  CALL PROGRAMOWANIE_DMA              ;programowanie DMA (zapis do pamiêci)
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
;Gdy próba odczytu nie uda siê, nastêpuje inkrementacja licznika b³êdów,
;oraz sprawdzenie, czy nie przekroczy³ on dopuszczalnej liczby b³êdów odczytu:
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
;Procedura zapisuje sektor dyskietki z pierwszych 512 bajtów pierwszej strony
;DMA (pierwsza strona DMA rozpoczyna siê od 64KB).
;Parametry:
;DX - numer sektora
  push ebx
  push ecx
  push edx
  push edi
  push esi
  mov byte [SYSTEM_ZAPIS_SEKTORA_LICZNIK_BLEDOW], 0   ;wyczyszczenie licznika b³êdów zapisu
  .POWROT_SYSTEM_ZAPIS_SEKTORA
  push edx
  MOV BYTE [znacznik_przerwania_fdd], 0
  call CHS
  call NORMALIZACJA_PO_CHS
  push ebx
  CALL SEEK                                       ;ustawienie g³owicy nad w³aœciw¹ œcie¿k¹
  CALL CZEKAJ_NA_PRZERWANIE_FDD
  mov al, 1
  CALL PROGRAMOWANIE_DMA                          ;programowanie DMA na odczyt z pamiêci
  pop ebx
  CALL FAZA_PRZESYLANIA_KOMENDY_WRITE_DATA
  mov ecx, 7
  MOV BYTE [znacznik_przerwania_fdd], 0
  call FAZA_KONCOWA_KOMENDY
  mov ax, [wyniki_koncowe+WYNIKI_KONCOWE.BAJT1]
  test ax, 11000000b
  jz .wykonanie_ok
  pop edx
;Gdy próba zapisu nie uda siê, nastêpuje inkrementacja licznika b³êdów,
;oraz sprawdzenie, czy nie przekroczy³ on dopuszczalnej liczby b³êdów zapisu:
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
