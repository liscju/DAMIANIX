;Synchroniczny dost�p do urz�dze� zosta� przedstawiony w rozdziale 8 na przyk�adzie
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
;Procedura pr�buje uzyska� wy��czny dost�p do stacji dyskietek.
;Parametry procedury:
;EAX - id procesu.
;Wyniki:
;EAX - 0 urz�dzenie zaj�te, inna warto�� - uzyskano wy��czno�� FDD
  push ebx
  mov bx, ds
  push ebx
  push eax
  mov ax, 24
  mov ds, ax
  pop eax
  bts word [FDD_+URZADZENIE.STAN], 0  ;skopiowanie zerowego bitu stanu urz�dzenia
                                      ;do flagi carry z jednoczesnym ustawieniem bitu
  jc    .bit_ten_juz_byl_ustawiony
;Kod wykona si�, gdy stacja dysk�w jest wolna - nast�puje jej rezerwacja
  mov [FDD_+URZADZENIE.ID_PROCESU_WLASCICIELA], eax
  mov eax, 1
  jmp .koniec
  .bit_ten_juz_byl_ustawiony
;Kod wykona si�, gdy stacja dysk�w jest zaj�ta przez inny proces
  clc
  mov eax, 0
  .koniec:
  pop ebx
  mov ds, bx
  pop ebx
RET

UZYSKAJ_WYLACZNOSC_FDD
;Procedura w p�tli wywo�uje procedur� PROS_O_WYLACZNOSC_FDD, a� do momentu,
;gdy uzyska wy��czno�� dla procesu.
  pusha
  .petla_uzyskiwania_wlasnosci_fdd
    call ZWROC_ADRES_FIZYCZY_IDENTYFIKATORA_AKTUALNEGO_ZADANIA       ;pobranie identyfikatora procesu
    mov eax, ecx
    call PROS_O_WYLACZNOSC_FDD
    cmp eax, 0
    jne .uzyskano_wlasnosc_fdd
    call PROCEDURA_WYWLASZCZAJACA             ;wyw�aszczenie procesu w przypadku zaj�tej stacji dyskietek
  jmp .petla_uzyskiwania_wlasnosci_fdd
  .uzyskano_wlasnosc_fdd
  popa
RET

ZWOLNIJ_WLASNOSC_FDD
;Procedura zwalnia stacj� dyskietek, wywo�uje w tym celu procedur� ZWOLNIJ_FDD.
  pusha
  call ZWROC_ADRES_FIZYCZY_IDENTYFIKATORA_AKTUALNEGO_ZADANIA
  mov eax, ecx
  call ZWOLNIJ_FDD
  popa
RET

ZWOLNIJ_FDD
;Procedura zwalnia stacj� dyskietek.
;Parametry procedury:
;EAX - identyfikator procesu w�a�ciciela stacji dyskietek
;Wyniki:
;EAX - 0 oznacza, �e proces nie jest w�a�cicielem stacji dyskietek.
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
;Procedura informuje, czy proces jest w�a�cicielem stacji dyskietek.
;Parametry procedury:
;EAX - id procesu.
;Wyniki:
;EAX - 1 gdy proces jest w�a�cicielem, 0 gdy nie
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
;Procedura w��cza nap�d dyskietek, gdy proces jest jej w�a�cicielem.
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
;Procedura uzyskuje id procesu i w��cza stacj� FDD gdy proces jest jej w�a�cicielem.
  pusha
  call ZWROC_ADRES_FIZYCZY_IDENTYFIKATORA_AKTUALNEGO_ZADANIA
  mov eax, ecx
  call WLACZ_FDD
  popa
RET

WYLACZ_FDD
;Procedura wy��cza nap�d dyskietek, gdy proces jest jej w�a�cicielem.
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
;Procedura uzyskuje id procesu i wy��cza stacj� FDD gdy proces jest jej w�a�cicielem.
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
;ES:EDI - adres obszaru pami�ci, do kt�rego zostanie wczytany sektor.
;Wyniki:
;EAX - 0 b��d, 1 sukces.
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
;DS:SI - adres obszaru pami�ci, z kt�rego zostanie wczytany sektor.
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
;Procedura odczytuje grup� sektor�w pod wskazany adres.
;Parametry procedury:
;DX - numer pierwszego sektora,
;ES:EDI - adres obszaru pami�ci, pod kt�ry nast�pi wczytanie sektor�w,
;CX - liczba sektor�w do odczytu.
;Wyniki:
;EAX - 1 powodzenie, 0 b��d
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
;Procedura zapisuje grup� sektor�w spod wskazanego adresu.
;Parametry procedury:
;DX - numer pierwszego sektora,
;DS:ESI - adres obszaru pami�ci, spod kt�rego nast�pi zapis sektor�w,
;CX - liczba sektor�w do zapisu.
;Wyniki:
;EAX - 1 powodzenie, 0 b��d
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
;Procedura odczytuje synchronicznie grup� sektor�w.
;Parametry procedury:
;DX - numer pierwszego sektora,
;ES:EDI - adres obszaru pami�ci, pod kt�ry nast�pi wczytanie sektor�w,
;CX - liczba sektor�w do odczytu.
;Wyniki:
;EAX - 1 powodzenie, 0 b��d
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
;Procedura zapisuje synchronicznie grup� sektor�w.
;Parametry procedury:
;DX - numer pierwszego sektora,
;DS:ESI - adres obszaru pami�ci, spod kt�rego nast�pi zapis sektor�w,
;CX - liczba sektor�w do zapisu.
;Wyniki:
;EAX - 1 powodzenie, 0 b��d
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
;Procedura pr�buje uzyska� wy��czno�� ekranu.
;Parametry procedury:
;EAX - id procesu,
;Wyniki:
;EAX - 0 urz�dzenie ju� zaj�te, 1 urz�dzenie wolne
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
;Procedura uzyskuje wy��czno�� ekranu. Gdy ekran jest zaj�ty w p�tli
;nast�puj� kolejne pr�by z wyw�aszczeniem zadania.
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
;Procedura zwalnia ekran, gdy proces j� wywo�uj�cy jest jego w�a�cicielem.
;procedura wywo�uje w tym celu procedur� ZWOLNIJ_EKRAN.
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
;Procedura informuje, czy proces jest w�a�cicielem ekranu.
;Parametry procedury:
;EAX - id procesu.
;Wyniki:
;EAX - 1 gdy proces jest w�a�cicielem, 0 gdy nie
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
;Procedura wypisuje na ekranie ci�g znak�w.
;Parametry procedury:
;ES:EDI - adres ci�gu znak�w zako�czonych zerem.
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
;Procedura wypisuje grup� znak�w na ekranie.
;Parametry procedury:
;ES:EDI - adres ci�gu znak�w,
;EAX - ilo�� znak�w.
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
;Procedura wypisuje na ekranie ci�g znak�w a� do napotkania spacji.
;Parametry procedury:
;ES:EDI - adres ci�gu znak�w zako�czonych zerem.
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
;Procedura synchronicznie wypisuje ci�g znak�w zako�czonych zerem na ekranie.
;Parametry procedury:
;ES:EDI - adres ci�gu znak�w.
  pusha
  call UZYSKAJ_WYLACZNOSC_EKRANU

  call WYPISZ_CIAG_ZNAKOW

  call ZWOLNIJ_WLASNOSC_EKRANU
  popa
RET




WYPISZ_CIAG_N_ZNAKOW_NA_EKRANIE
;Procedura wypisuje synchronicznie grup� znak�w na ekranie.
;Parametry procedury:
;ES:EDI - adres ci�gu znak�w,
;EAX - liczba znak�w.
  call UZYSKAJ_WYLACZNOSC_EKRANU

  call WYPISZ_CIAG_N_ZNAKOW

  call ZWOLNIJ_WLASNOSC_EKRANU
RET

WYPISZ_CIAG_N_ZNAKOW_NA_EKRANIE_KONIEC_SPACJA
;Procedura wypisuje synchronicznie na ekranie ci�g znak�w a� do napotkania spacji.
;Parametry procedury:
;ES:EDI - adres ci�gu znak�w zako�czonych zerem.
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
;Procedura wczytuje ci�g znak�w z klawiatury do zmiennej tablicowej
;(w tym celu powy�ej przygotowane zmienne).Znaki s�
;wczytywane do pierwszego naci�ni�cia klawisza ENTER. W celu okre�lenia
;aktualnej pozycji w zmiennej tablicowej u�ywa zmiennych pointer_danej
;oraz dlugosc_danej.
;Parametry procedury:
;ES:EDI - adres obszaru pami�ci, do kt�rego nast�pi wczytanie znak�w.
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
    cmp ah, 13  ;czy naci�ni�to ENTER
    jne .nie_enter
    call NACISNIETY_ENTER_
    jmp .koniec
    .nie_enter:
    cmp ah, 08h
    jne .nie_back_space     ;po naci�ni�ciu BACK SPACE kasowany jest ostatni znak w tablicy.
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
;Procedura aktualizuje pozycj� kursora po naci�ni�ciu ENTERA.
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
;Procedura aktualizuje po�o�enie kursora i zawarto�� tablicy dana
;po naci�ni�ciu BACK SPACE
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
;Procedura wy�wietla wci�ni�ty znak i umieszcza go w tablicy dana.
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


