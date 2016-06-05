;Synchroniczny dostêp do urz¹dzeñ zosta³ przedstawiony w rozdziale 8 na przyk³adzie
;ekranu.

struc URZADZENIE
      .ID_PROCESU_WLASCICIELA   RESD    1
      .CEL                      resb    1  ; ( ZAPIS ODCZYT ... )
      .STAN                     RESW    1
endstruc

FDD_            TIMES     7       DB 0
KLAWIATURA_     TIMES     7       DB 0
EKRAN_          TIMES     7       DB 0


;;;;;;;;;;;;;;;;;;;;;;;;;;    FDD       ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PROS_O_WYLACZNOSC_FDD
;Procedura próbuje uzyskaæ wy³¹czny dostêp do stacji dyskietek.
;Parametry procedury:
;EAX - id procesu.
;Wyniki:
;EAX - 0 urz¹dzenie zajête, inna wartoœæ - uzyskano wy³¹cznoœæ FDD
  push ebx
  mov bx, ds
  push ebx
  push eax
  mov ax, 24
  mov ds, ax
  pop eax
  bts word [FDD_+URZADZENIE.STAN], 0  ;skopiowanie zerowego bitu stanu urz¹dzenia
                                      ;do flagi carry z jednoczesnym ustawieniem bitu
  jc    .bit_ten_juz_byl_ustawiony
;Kod wykona siê, gdy stacja dysków jest wolna - nastêpuje jej rezerwacja
  mov [FDD_+URZADZENIE.ID_PROCESU_WLASCICIELA], eax
  mov eax, 1
  jmp .koniec
  .bit_ten_juz_byl_ustawiony
;Kod wykona siê, gdy stacja dysków jest zajêta przez inny proces
  clc
  mov eax, 0
  .koniec:
  pop ebx
  mov ds, bx
  pop ebx
RET

UZYSKAJ_WYLACZNOSC_FDD
;Procedura w pêtli wywo³uje procedurê PROS_O_WYLACZNOSC_FDD, a¿ do momentu,
;gdy uzyska wy³¹cznoœæ dla procesu.
  pusha
  .petla_uzyskiwania_wlasnosci_fdd
    call ZWROC_ADRES_FIZYCZY_IDENTYFIKATORA_AKTUALNEGO_ZADANIA       ;pobranie identyfikatora procesu
    mov eax, ecx
    call PROS_O_WYLACZNOSC_FDD
    cmp eax, 0
    jne .uzyskano_wlasnosc_fdd
    call PROCEDURA_WYWLASZCZAJACA             ;wyw³aszczenie procesu w przypadku zajêtej stacji dyskietek
  jmp .petla_uzyskiwania_wlasnosci_fdd
  .uzyskano_wlasnosc_fdd
  popa
RET

ZWOLNIJ_WLASNOSC_FDD
;Procedura zwalnia stacjê dyskietek, wywo³uje w tym celu procedurê ZWOLNIJ_FDD.
  pusha
  call ZWROC_ADRES_FIZYCZY_IDENTYFIKATORA_AKTUALNEGO_ZADANIA
  mov eax, ecx
  call ZWOLNIJ_FDD
  popa
RET

ZWOLNIJ_FDD
;Procedura zwalnia stacjê dyskietek.
;Parametry procedury:
;EAX - identyfikator procesu w³aœciciela stacji dyskietek
;Wyniki:
;EAX - 0 oznacza, ¿e proces nie jest w³aœcicielem stacji dyskietek.
  push ebx
  mov bx, ds
  push ebx
  push eax
  mov ax, 24
  mov ds, ax
  pop eax
  cmp eax, [FDD_+URZADZENIE.ID_PROCESU_WLASCICIELA]
  jne .nie_da_sie_zwolnic
  mov  dword [FDD_+URZADZENIE.ID_PROCESU_WLASCICIELA], 0
  btr  word [FDD_+URZADZENIE.STAN], 0
  clc
  jmp .koniec
  .nie_da_sie_zwolnic:
  mov eax, 0
  .koniec:
  pop ebx
  mov ds, bx
  pop ebx
RET

POTWIERDZ_WLASNOSC_FDD
;Procedura informuje, czy proces jest w³aœcicielem stacji dyskietek.
;Parametry procedury:
;EAX - id procesu.
;Wyniki:
;EAX - 1 gdy proces jest w³aœcicielem, 0 gdy nie
  push ebx
  mov bx, ds
  push ebx
  push eax
  mov ax, 24
  mov ds, ax
  pop eax
  cmp eax, [FDD_+URZADZENIE.ID_PROCESU_WLASCICIELA]
  jne .nie_wlasciciel
  mov eax, 1
  jmp .koniec
  .nie_wlasciciel:
  mov eax, 0
  .koniec:
  pop ebx
  mov ds, bx
  pop ebx
RET


WLACZ_FDD
;Procedura w³¹cza napêd dyskietek, gdy proces jest jej w³aœcicielem.
;Parametry procedury:
;EAX - id procesu.
  push ebx
  mov bx, ds
  push ebx
  push eax
  mov ax, 24
  mov ds, ax
  pop eax
  call POTWIERDZ_WLASNOSC_FDD
  cmp eax, 0
  je .brak_wlasnosci
  call INICJALIZUJ_FDD
  mov eax, 1
  jmp .koniec
  .brak_wlasnosci
  mov eax, 0
  .koniec:
  pop ebx
  mov ds, bx
  pop ebx
RET

UZYSKAJ_WLACZONY_NAPED_FDD
;Procedura uzyskuje id procesu i w³¹cza stacjê FDD gdy proces jest jej w³aœcicielem.
  pusha
  call ZWROC_ADRES_FIZYCZY_IDENTYFIKATORA_AKTUALNEGO_ZADANIA
  mov eax, ecx
  call WLACZ_FDD
  popa
RET

WYLACZ_FDD
;Procedura wy³¹cza napêd dyskietek, gdy proces jest jej w³aœcicielem.
;Parametry procedury:
;EAX - id procesu.
  push ebx
  mov bx, ds
  push ebx
  push eax
  mov ax, 24
  mov ds, ax
  pop eax
  call POTWIERDZ_WLASNOSC_FDD
  cmp eax, 0
  je .brak_wlasnosci
  xor al, al
  call WYLACZENIE_NAPEDU
  mov eax, 1
  jmp .koniec
  .brak_wlasnosci
  mov eax, 0
  .koniec:
  pop ebx
  mov ds, bx
  pop ebx
RET


UZYSKAJ_WYLACZONY_NAPED_FDD
;Procedura uzyskuje id procesu i wy³¹cza stacjê FDD gdy proces jest jej w³aœcicielem.
  pusha
  call ZWROC_ADRES_FIZYCZY_IDENTYFIKATORA_AKTUALNEGO_ZADANIA
  mov eax, ecx
  call WYLACZ_FDD
  popa
RET


ODCZYT_SEKTORA_DYSKIETKI
;Procedura odczytuje sektor dyskietki.
;Parametry procedury:
;DX - numer sektor,
;ES:EDI - adres obszaru pamiêci, do którego zostanie wczytany sektor.
;Wyniki:
;EAX - 0 b³¹d, 1 sukces.
  push ecx
  push edx
  push edi
  push esi
  push ebx
  mov bx, ds
  push ebx
  push eax
  mov ax, 24
  mov ds, ax
  pop eax
  CALL SYSTEM_ODCZYT_SEKTORA
  pusha
  popa
  cmp eax, 0
  je .koniec
  mov ax, 8
  mov ds, ax
  mov esi, 10000h
  mov ecx, 200h
  cld
  rep movsb
  mov eax, 1
  .koniec:
  pop ebx
  mov ds, bx
  pop ebx
  pop esi
  pop edi
  pop edx
  pop ecx
RET


ZAPIS_SEKTORA_DYSKIETKI
;Procedura zapisuje wskazany sektor dyskietki.
;Parametry procedury:
;DX - numer sektora,
;DS:SI - adres obszaru pamiêci, z którego zostanie wczytany sektor.
  push ecx
  push edx
  push edi
  push esi
  push ebx
  mov bx, es
  push ebx
  mov bx, ds
  push ebx
  mov ax, 8
  mov es, ax
  mov edi, 10000h
  mov ecx, 200h
  cld
  rep movsb
  push eax
  mov ax, 24
  mov ds, ax
  pop eax
  CALL SYSTEM_ZAPIS_SEKTORA
  cmp eax, 0
  je .koniec
  mov eax, 1
  .koniec:
  pop ebx
  mov ds,bx
  pop ebx
  mov es, bx
  pop ebx
  pop esi
  pop edi
  pop edx
  pop ecx
RET

ODCZYT_N_KOLEJNYCH_SEKTOROW
;Procedura odczytuje grupê sektorów pod wskazany adres.
;Parametry procedury:
;DX - numer pierwszego sektora,
;ES:EDI - adres obszaru pamiêci, pod który nast¹pi wczytanie sektorów,
;CX - liczba sektorów do odczytu.
;Wyniki:
;EAX - 1 powodzenie, 0 b³¹d
  push ecx
  push edx
  push edi
  push esi
  push ebx
  mov bx, ds
  push ebx
  .PETLA_ODCZYTU_SEKTOROW
    call  ODCZYT_SEKTORA_DYSKIETKI
    cmp eax, 0
    je .blad
    add edi, 200h ;dodanie rozmiaru sektora
    inc dx        ; kolejny sektor
  LOOP .PETLA_ODCZYTU_SEKTOROW
  mov eax, 1
  jmp .koniec
  .blad:
  xor eax, eax
  .koniec:
  pop ebx
  mov ds, bx
  pop ebx
  pop esi
  pop edi
  pop edx
  pop ecx
RET


ZAPIS_N_KOLEJNYCH_SEKTOROW
;Procedura zapisuje grupê sektorów spod wskazanego adresu.
;Parametry procedury:
;DX - numer pierwszego sektora,
;DS:ESI - adres obszaru pamiêci, spod którego nast¹pi zapis sektorów,
;CX - liczba sektorów do zapisu.
;Wyniki:
;EAX - 1 powodzenie, 0 b³¹d
  push ecx
  push edx
  push edi
  push esi
  push ebx
  mov bx, es
  push ebx
  mov bx, ds
  push ebx
  .PETLA_ZAPISU_SEKTOROW
    call  ZAPIS_SEKTORA_DYSKIETKI
    cmp eax, 0
    je .blad
    add esi, 200h ; dodanie rozmiaru sektora
    inc dx        ;numer kolejnego sektora
  LOOP .PETLA_ZAPISU_SEKTOROW
  mov eax, 1
  jmp .koniec
  .blad:
  xor eax, eax
  .koniec:
  pop ebx
  mov ds,bx
  pop ebx
  mov es, bx
  pop ebx
  pop esi
  pop edi
  pop edx
  pop ecx
RET


ODCZYTAJ_N_SEKTOROW
;Procedura odczytuje synchronicznie grupê sektorów.
;Parametry procedury:
;DX - numer pierwszego sektora,
;ES:EDI - adres obszaru pamiêci, pod który nast¹pi wczytanie sektorów,
;CX - liczba sektorów do odczytu.
;Wyniki:
;EAX - 1 powodzenie, 0 b³¹d
  push ebx
  push edi
  push esi
  push ecx
  push edx
  mov ebx, 1000
  call UZYSKAJ_WYLACZNOSC_FDD
  .powrot_po_bledzie
  call UZYSKAJ_WLACZONY_NAPED_FDD
  call ODCZYT_N_KOLEJNYCH_SEKTOROW
  cmp eax, 0
  jne .dalej
  dec ebx
  cmp ebx, 0
  jne  .powrot_po_bledzie
  .dalej
  call UZYSKAJ_WYLACZONY_NAPED_FDD
  call ZWOLNIJ_WLASNOSC_FDD
  pop edx
  pop ecx
  pop esi
  pop edi
  pop ebx
RET

ZAPISZ_N_SEKTOROW
;Procedura zapisuje synchronicznie grupê sektorów.
;Parametry procedury:
;DX - numer pierwszego sektora,
;DS:ESI - adres obszaru pamiêci, spod którego nast¹pi zapis sektorów,
;CX - liczba sektorów do zapisu.
;Wyniki:
;EAX - 1 powodzenie, 0 b³¹d
  mov ebx, 3
  call UZYSKAJ_WYLACZNOSC_FDD
  .powrot_po_bledzie
  call UZYSKAJ_WLACZONY_NAPED_FDD
  call ZAPIS_N_KOLEJNYCH_SEKTOROW
  cmp eax, 0
  jne .dalej
  dec ebx
  cmp ebx, 0
  jne  .powrot_po_bledzie
  .dalej
  call UZYSKAJ_WYLACZONY_NAPED_FDD
  call ZWOLNIJ_WLASNOSC_FDD
RET


;;;;;;;;;;;;;;;;;;;;;;;;;;;;   EKRAN ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PROS_O_WYLACZNOSC_EKRANU
;Procedura próbuje uzyskaæ wy³¹cznoœæ ekranu.
;Parametry procedury:
;EAX - id procesu,
;Wyniki:
;EAX - 0 urz¹dzenie ju¿ zajête, 1 urz¹dzenie wolne
  push ebx
  mov bx, ds
  push ebx
  push eax
  mov ax, 24
  mov ds, ax
  pop eax
  bts word [EKRAN_+URZADZENIE.STAN], 0
  jc    .bit_ten_juz_byl_ustawiony
  mov [EKRAN_+URZADZENIE.ID_PROCESU_WLASCICIELA], eax
  mov eax, 1
  jmp .koniec
  .bit_ten_juz_byl_ustawiony
  mov eax, 0
  .koniec:
  pop ebx
  mov ds, bx
  pop ebx
RET

UZYSKAJ_WYLACZNOSC_EKRANU
;Procedura uzyskuje wy³¹cznoœæ ekranu. Gdy ekran jest zajêty w pêtli
;nastêpuj¹ kolejne próby z wyw³aszczeniem zadania.
  pusha
  .petla_uzyskiwania_wlasnosci_ekranu
  call ZWROC_ADRES_FIZYCZY_IDENTYFIKATORA_AKTUALNEGO_ZADANIA
  mov eax, ecx
  call PROS_O_WYLACZNOSC_EKRANU
  cmp eax, 0
  jne .uzyskano_wlasnosc_ekranu
  call PROCEDURA_WYWLASZCZAJACA
  jmp .petla_uzyskiwania_wlasnosci_ekranu
  .uzyskano_wlasnosc_ekranu
  popa
RET

ZWOLNIJ_WLASNOSC_EKRANU
;Procedura zwalnia ekran, gdy proces j¹ wywo³uj¹cy jest jego w³aœcicielem.
;procedura wywo³uje w tym celu procedurê ZWOLNIJ_EKRAN.
  pusha
  call ZWROC_ADRES_FIZYCZY_IDENTYFIKATORA_AKTUALNEGO_ZADANIA
  mov eax, ecx
  call ZWOLNIJ_EKRAN
  popa
RET

ZWOLNIJ_EKRAN
;Procedura zwalnia ekran.
;Parametry procedury:
;EAX - id procesu.
  push ebx
  mov bx, ds
  push ebx
  push eax
  mov ax, 24
  mov ds, ax
  pop eax
  cmp eax, [EKRAN_+URZADZENIE.ID_PROCESU_WLASCICIELA]
  jne .nie_da_sie_zwolnic
  mov  dword [EKRAN_+URZADZENIE.ID_PROCESU_WLASCICIELA], 0
  btr  word [EKRAN_+URZADZENIE.STAN], 0
  clc
  jmp .koniec
  .nie_da_sie_zwolnic:
  mov eax, 0
  .koniec:
  pop ebx
  mov ds, bx
  pop ebx
RET

POTWIERDZ_WLASNOSC_EKRANU
;Procedura informuje, czy proces jest w³aœcicielem ekranu.
;Parametry procedury:
;EAX - id procesu.
;Wyniki:
;EAX - 1 gdy proces jest w³aœcicielem, 0 gdy nie
  push ebx
  mov bx, ds
  push ebx
  push eax
  mov ax, 24
  mov ds, ax
  pop eax
  cmp eax, [EKRAN_+URZADZENIE.ID_PROCESU_WLASCICIELA]
  jne .nie_wlasciciel
  mov eax, 1
  jmp .koniec
  .nie_wlasciciel:
  mov eax, 0
  .koniec:
  pop ebx
  mov ds, bx
  pop ebx
RET

WYPISZ_ZNAK_NA_EKRANIE
;Procedura wypisuje synchronicznie znak na ekranie.
;Parametry procedury:
;DL - kod ASCII znaku
  call UZYSKAJ_WYLACZNOSC_EKRANU
  call WYSWIETL_ZNAK
  call ZWOLNIJ_WLASNOSC_EKRANU
RET

WYPISZ_CIAG_ZNAKOW
;Procedura wypisuje na ekranie ci¹g znaków.
;Parametry procedury:
;ES:EDI - adres ci¹gu znaków zakoñczonych zerem.
  .petla_wypisywania_znakow
    mov dl, [es:edi]
    cmp dl, 0
    je .koniec
    call WYSWIETL_ZNAK
    inc edi
  jmp .petla_wypisywania_znakow
  .koniec
RET

WYPISZ_CIAG_N_ZNAKOW
;Procedura wypisuje grupê znaków na ekranie.
;Parametry procedury:
;ES:EDI - adres ci¹gu znaków,
;EAX - iloœæ znaków.
  mov ecx, eax
  .petla_wypisywania_znakow
    mov dl, [es:edi]
    cmp dl, 0
    je .koniec
    call WYSWIETL_ZNAK
    inc edi
  loop .petla_wypisywania_znakow
  .koniec
RET

WYPISZ_CIAG_ZNAKOW_KONIEC_SPACJA
;Procedura wypisuje na ekranie ci¹g znaków a¿ do napotkania spacji.
;Parametry procedury:
;ES:EDI - adres ci¹gu znaków zakoñczonych zerem.
  .petla_wypisywania_znakow
    mov dl, [es:edi]
    cmp dl, 0
    je .koniec
    cmp dl, 32
    je .koniec
    call WYSWIETL_ZNAK
    inc edi
  jmp .petla_wypisywania_znakow
  .koniec
RET

WYPISZ_CIAG_ZNAKOW_NA_EKRANIE
;Procedura synchronicznie wypisuje ci¹g znaków zakoñczonych zerem na ekranie.
;Parametry procedury:
;ES:EDI - adres ci¹gu znaków.
  pusha
  call UZYSKAJ_WYLACZNOSC_EKRANU

  call WYPISZ_CIAG_ZNAKOW

  call ZWOLNIJ_WLASNOSC_EKRANU
  popa
RET




WYPISZ_CIAG_N_ZNAKOW_NA_EKRANIE
;Procedura wypisuje synchronicznie grupê znaków na ekranie.
;Parametry procedury:
;ES:EDI - adres ci¹gu znaków,
;EAX - liczba znaków.
  call UZYSKAJ_WYLACZNOSC_EKRANU

  call WYPISZ_CIAG_N_ZNAKOW

  call ZWOLNIJ_WLASNOSC_EKRANU
RET

WYPISZ_CIAG_N_ZNAKOW_NA_EKRANIE_KONIEC_SPACJA
;Procedura wypisuje synchronicznie na ekranie ci¹g znaków a¿ do napotkania spacji.
;Parametry procedury:
;ES:EDI - adres ci¹gu znaków zakoñczonych zerem.
  call UZYSKAJ_WYLACZNOSC_EKRANU

  call  WYPISZ_CIAG_ZNAKOW_KONIEC_SPACJA

  call ZWOLNIJ_WLASNOSC_EKRANU

RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;   KLAWIATURA ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dana                             times   500      db         0
pointer_danej                    dw         0
dlugosc_danej                    dw         0
dana2                            times  500       db         0




PROCEDURA_WCZYTUJACA_CIAG_ZNAKOW
;Procedura wczytuje ci¹g znaków z klawiatury do zmiennej tablicowej
;(w tym celu powy¿ej przygotowane zmienne).Znaki s¹
;wczytywane do pierwszego naciœniêcia klawisza ENTER. W celu okreœlenia
;aktualnej pozycji w zmiennej tablicowej u¿ywa zmiennych pointer_danej
;oraz dlugosc_danej.
;Parametry procedury:
;ES:EDI - adres obszaru pamiêci, do którego nast¹pi wczytanie znaków.
  pusha
  mov ax, ds
  push eax
  mov ax, es
  push eax
  push edi
  mov ax, 24
  mov ds, ax
  mov ax, 8
  mov es, ax
  WCZYTAJ_CIAG_ZNAKOW:
    call ODCZYTAJ_Z_BUFORA
    cmp ax, 0
    jne .dalej2
    jmp WCZYTAJ_CIAG_ZNAKOW
    .dalej2:
    cmp ah, 0
    jne .znak_ascii
    jmp .znak_nacisniecia
    .znak_ascii
    xor edi, edi
    mov di, [pointer_danej]
    cmp ah, 13  ;czy naciœniêto ENTER
    jne .nie_enter
    call NACISNIETY_ENTER_
    jmp .koniec
    .nie_enter:
    cmp ah, 08h
    jne .nie_back_space     ;po naciœniêciu BACK SPACE kasowany jest ostatni znak w tablicy.
    call NACISNIETY_BACK_SPACE_
    jmp WCZYTAJ_CIAG_ZNAKOW
    .nie_back_space:
    call NACISNIETY_ZNAK_ASCII_
    jmp WCZYTAJ_CIAG_ZNAKOW
    .znak_nacisniecia:
  jmp WCZYTAJ_CIAG_ZNAKOW
  .koniec:
  pop edi
  pop eax
  mov es, ax
  mov   cx, [dlugosc_danej]
  mov esi, dana
  rep movsb
  inc edi
  mov byte [es:edi], 0
  mov ecx, 500
  xor edi, edi
;Czyszczenie zmiennej tablicowej:
  .petla_czyszczaca_dana
    mov byte [dana+edi], 0
    inc edi
    loop .petla_czyszczaca_dana
    mov word [pointer_danej], 0
    mov word [dlugosc_danej], 0
    pop eax
    mov ds, ax
  popa
RET

NACISNIETY_ENTER_:
;Procedura aktualizuje pozycjê kursora po naciœniêciu ENTERA.
  mov al, [kursor+KURSOR.atrybut]
  cmp al, 0fh
  je .nie_bialy
  mov byte [kursor+KURSOR.atrybut], 0fh
  jmp .koniec_kolorowania_kursora
  .nie_bialy
  mov byte [kursor+KURSOR.atrybut], 0eh
  .koniec_kolorowania_kursora:
  mov al, [kursor+KURSOR.y]
  cmp al, 24
  jne .dalej
  call LINIA_W_DOL
  dec byte [kursor+KURSOR.y]
  .dalej
  inc byte [kursor+KURSOR.y]
  mov byte [kursor+KURSOR.x], 0
  CALL NORMALIZACJA_PRZED_USTAWIENIEM_KURSORA
  CALL USTAW_KURSOR_
RET

NACISNIETY_BACK_SPACE_
;Procedura aktualizuje po³o¿enie kursora i zawartoœæ tablicy dana
;po naciœniêciu BACK SPACE
  cmp di, 0
  je .koniec
  dec edi
  dec word [pointer_danej]
  dec word [dlugosc_danej]
  call SKASUJ_ZNAK
  mov bx, [dlugosc_danej]
  cmp bx, [pointer_danej]
  xor edi, edi
  mov di, [dlugosc_danej]
  mov byte [dana+edi], 0
  .koniec
RET

NACISNIETY_ZNAK_ASCII_
;Procedura wyœwietla wciœniêty znak i umieszcza go w tablicy dana.
  cmp di, 499
  jae .koniec
  mov bx, [dlugosc_danej]
  cmp bx, [pointer_danej]
  mov dl, ah
  CALL WYSWIETL_ZNAK
  mov [dana+edi], ah
  inc word [pointer_danej]
  inc word [dlugosc_danej]
  .koniec
RET


