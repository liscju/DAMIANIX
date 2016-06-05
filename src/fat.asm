INTERPRETATOR_nazwa_pliku times 11 db 0  ; ta zmienna dla pobrzeb interpretatora poleceñ
db 0

WCZYTAJ_FAT
;Procedura wczytuje tablicê FAT12 dyskietki pod adres 20000h.
   mov dx, 1
   mov ax, 8
   mov es, ax
   mov edi, 20000h
   mov ecx, 9
   call ODCZYTAJ_N_SEKTOROW
RET

WCZYTAJ_KATALOG_GLOWNY
;Procedura wczytuje katalog g³ówny dyskietki pod adres 22000h.
   mov dx, 19
   mov ax, 8
   mov es, ax
   mov edi, 22000h
   mov ecx, 14
   call ODCZYTAJ_N_SEKTOROW
RET

WCZYTAJ_DANE_FATU
;Procedura odczytuje tablicê FAT i katalog g³ówny dyskietki.
  PUSHA
  mov ax, es
  pusha
  call WCZYTAJ_FAT
  CALL WCZYTAJ_KATALOG_GLOWNY
  popa
  mov es, ax
  POPA
RET

WYSZUKAJ_DOSTEPNOSC_PLIKU_W_KATALOGU
;Procedura szuka pliku w katalogu g³ównym.
;Parametry procedury:
;ES:EDI - adres katalogu g³ównego,
;DS:ESI - adres zmiennej przechowuj¹cej nazwê pliku,
;EAX - rozmiar katalogu,
;Wyniki:
;EAX - 1 - odnaleziono plik, 0 - nie odnaleziono pliku,
;EDI - adres struktury katalogowej odnalezionego pliku.
  push edx
  push ebx
  push ecx
  xor edx, edx
  mov ebx, 32 ; tyle zajmuje wpis katalogowy
  div ebx
  mov ecx, eax
  .petla_szukania_pliku
    call   POROWNAJ_NAZWY_PLIKOW
    cmp eax, 1
    je .koniec   ; znaleziono
    add edi, 32 ; adres kolejnego wpisu katalogowego
  loop .petla_szukania_pliku
  .koniec
  pop ecx
  pop ebx
  pop edx
RET


POROWNAJ_NAZWY_PLIKOW
;Procedura porównuje nazwy plików.
;Parametry procedury:
;ES:EDI, DS:ESI - adresy ci¹gów znaków do porównania.
;Wyniki:
;AX - 1 - nazwy takie same, 0 - nazwy siê ró¿ni¹.
  push esi
  push ecx
  push edi
  mov ecx, 11
  mov eax, 1
  .petla_porownywania
    cmpsb
    jne .nie_sa_rowne_nazwy
  loop .petla_porownywania
  jmp .koniec
  .nie_sa_rowne_nazwy
  mov eax, 0
  .koniec
  pop edi
  pop ecx
  pop esi
RET

WYSZUKAJ_DOSTEPNOSC_PLIKU_W_KATALOGU_GLOWNYM
;Procedura okreœla, czy w katalogu g³ównym dyskietki znajduje siê plik
;o nazwie zawartej w tablicy INTERPRETATOR_nazwa_pliku.
  push ebx
  push esi
  mov ax, ds
  push eax
  mov ax, es
  push eax
  mov ax, 8
  mov es, ax
  mov ax, 24
  mov ds, ax
  mov esi,   INTERPRETATOR_nazwa_pliku
  mov edi,   22000h
  mov eax, 1c00h
  call   WYSZUKAJ_DOSTEPNOSC_PLIKU_W_KATALOGU
  pop ebx
  mov es, bx
  pop ebx
  mov ds, bx
  pop esi
  pop ebx
RET

INTERPRETATOR_CZY_JEST_PLIK_W_K_G
;Procedura stanowi polecenie ".?" systemu (czy plik znajduej siê w katalogu g³ównym)
  pusha
  mov ax, ds
  push eax
  mov ax, es
  push eax
  mov ax, 24
  mov ds, ax
  mov es, ax
  mov ecx, 11
  mov esi, [argument1 + ARGUMENT.POCZATEK]    ;argument przekazany przez u¿ytkownika interpretatorowi poleceñ
  mov edi, INTERPRETATOR_nazwa_pliku
  cld
  push esi
  push edi
  push ecx
  mov al, 32
  rep stosb
  pop ecx
  pop edi
  pop esi
  .petla_kopiowania_nazwy
    mov al, [ds:esi]
    cmp al, 0
    je .koniec1
    cmp al, 32
    je .koniec1
    movsb
  loop .petla_kopiowania_nazwy
  .koniec1
  call WYSZUKAJ_DOSTEPNOSC_PLIKU_W_KATALOGU_GLOWNYM
  cmp eax, 1
  je .odnaleziono
  mov dl, 'X'
  call WYPISZ_ZNAK_NA_EKRANIE
  jmp .koniec
  .odnaleziono
  mov dl, 'V'
  call WYPISZ_ZNAK_NA_EKRANIE
  .koniec:
  pop eax
  mov es, ax
  pop eax
  mov ds, ax
  popa
RET

PODAJ_WIELKOSC_PLIKU_K_G
;Procedura podaje rozmiar pliku.
;Wyniki:
;EAX - rozmiar pliku.
  push ebx
  push edx
  push esi
  push edi
  mov ax, ds
  push eax
  mov ax, es
  push eax
  mov ax, 24
  mov ds, ax
  mov es, ax
  mov ecx, 11
  mov esi, [argument1 + ARGUMENT.POCZATEK]
  mov edi, INTERPRETATOR_nazwa_pliku
  cld
  push esi
  push edi
  push ecx
  mov al, 32
  rep stosb
  pop ecx
  pop edi
  pop esi
  .petla_kopiowania_nazwy
    mov al, [ds:esi]
    cmp al, 0
    je .koniec1
    cmp al, 32
    je .koniec1
    movsb
  loop .petla_kopiowania_nazwy
  .koniec1
;poszukiwanie wpisu katalogowego w katalogu g³ównym:
  call WYSZUKAJ_DOSTEPNOSC_PLIKU_W_KATALOGU_GLOWNYM
  cmp eax, 1
  je .odnaleziono
  mov ecx, 0
  mov eax, 0
  jmp .koniec
  .odnaleziono
  mov ax, 8
  mov es, ax
;Odczyt pola rozmiaru pliku ze struktury katalogowej:
  add edi, 1ch
  mov eax, [es:edi]
  mov ecx, 1
  .koniec:
  pop ebx
  mov es, bx
  pop ebx
  mov ds, bx
  pop edi
  pop esi
  pop edx
  pop ebx
ret

INTERPRETATOR_PODAJ_WIELKOSC_PLIKU_K_G
;Procedura stanowi polecenie ".#" systemu (wyœwietla rozmiar pliku podanego przez u¿ytkownika jako atrybut polecenia).
  pusha
  mov ax, es
  push eax
  mov ax, 8
  mov es, ax
  call PODAJ_WIELKOSC_PLIKU_K_G
  cmp ecx, 0
  je .nie_znaleziono_pliku
  call WYPISZ_LICZBE_DZIESIETNIE
  jmp .koniec
  .nie_znaleziono_pliku
  mov dl, 'X'
  call WYPISZ_ZNAK_NA_EKRANIE
  .koniec:
  pop eax
  mov es, ax
popa
ret

INTERPRETATOR_WYPISZ_PLIKI_KATALOGU_GLOWNEGO
;Procedura wypisuje nazwy plików znajduj¹cych siê w katalogu g³ównym dyskietki.
  pusha
  mov ax, ds
  push eax
  mov ax, es
  push eax
  mov ax, 8
  mov es, ax
  mov ax, 24
  mov ds, ax
  mov edi,   22000h
  mov eax, 1c00h
  call   WYPISZ_PLIKI_KATALOGU
  pop ebx
  mov es, bx
  pop ebx
  mov ds, bx
  popa
RET

WYPISZ_PLIKI_KATALOGU
;Procedura wypisuje na ekranie nazwy plików znajduj¹cych siê w katalogu.
;Parametry procedury:
;ES:EDI - adres struktury katalogowej,
;EAX - rozmiar katalogu.
  push edx
  push ebx
  push ecx
  xor edx, edx
  mov ebx, 32 ;tyle zajmuje wpis katalogowy
  div ebx
  mov ecx, eax
  .petla_szukania_pliku
    mov al, [es:edi]
    cmp al, 0
    je .dalej    ;pusta pozycja katalogowa
    cmp al, 229  ;usuniêta pozycja katalogowa
    je .dalej
    pusha
;Wypisanie nazwy pliku:
    mov eax, 11
    call WYPISZ_CIAG_N_ZNAKOW_NA_EKRANIE_KONIEC_SPACJA
    mov dl, ' '
    call WYPISZ_ZNAK_NA_EKRANIE
    popa
  .dalej:
  add edi, 32 ; w przeciwnym razie nastawiam na nastepny wpis katalogowy
  loop .petla_szukania_pliku
  .koniec
  pop ecx
  pop ebx
  pop edx
RET

PODAJ_PIERWSZY_SEKTOR_PLIKU_K_G
;Procedura odczytuje z wpisu katalogowego numer sektora, od którego
;rozpoczyna siê plik.
;Wyniki:
;AX - numer pierwszego sektora pliku.
  push ebx
  push edx
  push esi
  push edi
  mov ax, ds
  push eax
  mov ax, es
  push eax
  mov ax, 24
  mov ds, ax
  mov es, ax
  mov ecx, 11
  mov esi, [argument1 + ARGUMENT.POCZATEK]
  mov edi, INTERPRETATOR_nazwa_pliku
  cld
  push esi
  push edi
  push ecx
  mov al, 32
  rep stosb
  pop ecx
  pop edi
  pop esi
  .petla_kopiowania_nazwy
    mov al, [ds:esi]
    cmp al, 0
    je .koniec1
    cmp al, 32
    je .koniec1
    movsb
  loop .petla_kopiowania_nazwy
  .koniec1
  call WYSZUKAJ_DOSTEPNOSC_PLIKU_W_KATALOGU_GLOWNYM
  cmp eax, 1
  je .odnaleziono
  mov ecx, 0
  mov eax, 0
  jmp .koniec
  .odnaleziono
  mov ax, 8
  mov es, ax
;Odczytanie numeru pierwzsego sektora pliku ze struktury katalogowej:
  add edi, 1ah
  xor eax, eax
  mov ax, [es:edi]
  mov cx, 1
  .koniec:
  pop ebx
  mov es, bx
  pop ebx
  mov ds, bx
  pop edi
  pop esi
  pop edx
  pop ebx
ret

INTERPRETATOR_PODAJ_PIERWSZY_SEKTOR_PLIKU_K_G
;Procedura stanowi polecenie ".1" systemu (podaje pierwszy sektor pliku).
  pusha
  mov ax, es
  push eax
  mov ax, 8
  mov es, ax
  call PODAJ_PIERWSZY_SEKTOR_PLIKU_K_G
  cmp ecx, 0
  je .nie_znaleziono_pliku
  call WYPISZ_LICZBE_DZIESIETNIE
  jmp .koniec
  .nie_znaleziono_pliku
  mov dl, 'X'
  call WYPISZ_ZNAK_NA_EKRANIE
  .koniec:
  pop eax
  mov es, ax
  popa
ret

INTERPRETATOR_WYSWIETL_PLIK_K_G
;Procedura wyœwielta zawartoœæ pliku na ekranie monitora (polecenie ".:" systemu).
  pusha
  mov ax, es
  push eax
  mov ax, 8
  mov es, ax
;Okreœlenie sektora, od którego rozpoczynaj¹ siê dane pliku:
  call PODAJ_PIERWSZY_SEKTOR_PLIKU_K_G
  cmp ecx, 0
  je .nie_znaleziono_pliku
  push eax
;Okreœlenie rozmiaru pliku:
  call PODAJ_WIELKOSC_PLIKU_K_G
  mov ebx, eax
  cmp ebx, 0
  jne .mozna_dalej
  pop eax
  xor eax, eax
  jmp .koniec
  .mozna_dalej
  pop eax
  xor ecx, ecx
  inc ebx
  push ebx
;Wczytanie zawartoœci pliku do pamiêci operacyjnej:
  call  UZYSKAJ_WCZYTANY_PLIK_DO_PAMIECI
  pop ebx
;Za wczytany ci¹g znaków wpisywane jest 0
  mov byte [es:edi+ebx], 0
  call WYPISZ_CIAG_ZNAKOW_NA_EKRANIE
  mov ebx, edi
  mov ecx, edx
  mov edi, 5f000h
  cli
;Usuniêcie stron, które zosta³y dodane w celu wczytania pliku do pamiêci:
  call USUN_N_STRON_POCZAWSZY_OD_EBX
  sti
  jmp .koniec
  .nie_znaleziono_pliku
  mov dl, 'X'
  call WYPISZ_ZNAK_NA_EKRANIE
  .koniec:
  pop eax
  mov es, ax
  popa
ret

PRZYGOTUJ_PLIK_DO_URUCHOMIENIA
;Procedura uruchamia program zawarty w pliku znajduj¹cym siê w katalogu g³ównym dyskietki
;(polecenie ".^" systemu).
  pusha
  mov ax, es
  push eax
  mov ax, 8
  mov es, ax
;Okreœlenie pierwszego sektora pliku:
  call PODAJ_PIERWSZY_SEKTOR_PLIKU_K_G
  cmp ecx, 0
  je .nie_znaleziono_pliku
  push eax
;Okreœlenie rozmiaru pliku:
  call PODAJ_WIELKOSC_PLIKU_K_G
  mov ebx, eax
  cmp ebx, 0
  jne .mozna_dalej
  pop eax
  xor eax, eax
  jmp .koniec
  .mozna_dalej
  pop eax
  xor ecx, ecx
;Dodanie do rozmiaru pliku struktury pocz¹tkowej zadania (struktura bêdzie znajdowa³a siê przed wczytanym kodem).
  add ebx, STRUKTURA_POCZATKU_PROGRAMU.POCZATEK_KODU
  push ebx
  mov ecx,  STRUKTURA_POCZATKU_PROGRAMU.POCZATEK_KODU
;Wczytanie pliku programu do pamiêci operacyjnej:
  call  UZYSKAJ_WCZYTANY_PLIK_DO_PAMIECI
;Identyfikator procesu stanowi adres fizyczny struktury pocz¹tkowej zadania:
  mov [es:edi + STRUKTURA_POCZATKU_PROGRAMU.IDENTYFIKATOR_PROCESU + IDENTYFIKATOR_PROCESU.WIELKOSC], dx
  call TWORZ_SEGMENTY_ZADANIA      ;Tworzenie lokalnej tablicy deskryptorów zadania, stosu, TSS
;Przygotowanie danych do stronicowania dla zadania:
  call INICJUJ_STRONICOWANIE_ZADANIA
  push edi
  call KOPIUJ_KATALOG_STRON_DLA_ZADANIA ;
  pop edi
  call PRZYGOTUJ_ZADANIE_DO_ODPALENIA
  pop ebx
  jmp .koniec
  .nie_znaleziono_pliku
  mov dl, 'X'
  call WYPISZ_ZNAK_NA_EKRANIE
  .koniec:
  pop eax
  mov es, ax
  popa
ret


PRZYGOTUJ_PLIK_DO_URUCHOMIENIA_W_ZAWIESZENIU
;Procedura tworzy uœpione zadanie, którego kod znajduje siê w pliku w katalogu g³ównym dyskietki
;(polecenie ".^_" systemu).
  pusha
  mov ax, es
  push eax
  mov ax, 8
  mov es, ax
  call PODAJ_PIERWSZY_SEKTOR_PLIKU_K_G
  cmp ecx, 0
  jne .next
  jmp .nie_znaleziono_pliku
  .next
  push eax
  call PODAJ_WIELKOSC_PLIKU_K_G
  mov ebx, eax
  cmp ebx, 0
  jne .mozna_dalej
  pop eax
  xor eax, eax
  jmp .koniec
  .mozna_dalej
  pop eax
  xor ecx, ecx
  add ebx, STRUKTURA_POCZATKU_PROGRAMU.POCZATEK_KODU
  push ebx
  mov ecx,  STRUKTURA_POCZATKU_PROGRAMU.POCZATEK_KODU
  call  UZYSKAJ_WCZYTANY_PLIK_DO_PAMIECI
  mov [es:edi + STRUKTURA_POCZATKU_PROGRAMU.IDENTYFIKATOR_PROCESU + IDENTYFIKATOR_PROCESU.WIELKOSC], dx
  call TWORZ_SEGMENTY_ZADANIA
  call INICJUJ_STRONICOWANIE_ZADANIA
  push edi
  call KOPIUJ_KATALOG_STRON_DLA_ZADANIA
  pop edi
  call PRZYGOTUJ_ZADANIE_DO_ODPALENIA_W_ZAWIESZENIU
  pop ebx
  jmp .koniec
  .nie_znaleziono_pliku
  mov dl, 'X'
  call WYPISZ_ZNAK_NA_EKRANIE
  .koniec:
  pop eax
  mov es, ax
  popa
ret





UZYSKAJ_WCZYTANY_PLIK_DO_PAMIECI
;Procedura wczytuje plik do pamiêci operacyjnej.
;Parametry procedury:
;AX - pierwszy sektor pliku,
;EBX - rozmiar pliku,
;ECX - dodatkowy blok pamiêci rezerwowany na pocz¹tku (na przyk³ad na identyfikator procesu).
  push ecx
  push esi
  mov dx, es
  push edx
  push eax
  push ebx
  mov eax, ebx
  add eax, ecx ;obliczenie pe³nego rozmiaru pamiêci, jaki nale¿y stworzyæ
  mov ebx, 4096
  xor edx, edx
  div ebx      ;Obliczenie liczby stron koniecznych do dodania
  cmp edx, 0
  je .nie_ma_reszty
  inc eax
  .nie_ma_reszty
  mov edx, eax
  mov ax, 8
  mov es, ax
  mov edi, 5f000h
  push edx
  push eax
  push esi
  push ecx
  mov eax, edx
;Dodanie stron pamiêci w celu wczytania do nich pliku
  call DODAJ_N_STRON_DO_PRZESTRZENI_ADRESOWEJ_USER
  pop ecx
  pop esi
  pop eax
  pop edx
  cmp edi, 0
  jne .mozna_dalej
  pop eax
  xor eax, eax
  jmp .koniec
  .mozna_dalej
  mov edi, ebx
  pop ebx
  pop eax
  add edi, ecx
  call WCZYTAJ_PLIK_DO_PAMIECI
  cmp eax, 0
  jne .mozna_dalej2
  xor eax, eax
  jmp .koniec
  .mozna_dalej2
  mov eax, 1
  sub edi, ecx
  .koniec
  pop ecx
  mov es, cx
  pop esi
  pop ecx
RET

WCZYTAJ_PLIK_DO_PAMIECI
;Procedura odczytuje plik do pamiêci operacyjnej.
;Parametry procedury:
;ES:EDI - adres, pod który nale¿y odczytaæ plik,
;AX - numer pierwszego sektora pliku,
;EBX - rozmiar pliku.
  push edx
  mov dx, gs
  push edx
  mov dx, 8
  mov gs, dx
  mov esi, 20000h ;adres tablicy FAT
  pusha
  call WCZYTAJ_PLIK
  cmp eax, 0
  jne .odczyt_sie_powiodl
  popa
  mov eax, 0
  jmp .koniec
  .odczyt_sie_powiodl
  popa
  .koniec:
  pop edx
  mov gs, dx
  pop edx
RET


WCZYTAJ_PLIK:
;Procedura odczytuje plik do pamiêci
;Parametry procedury:
;GS:ESI - adres FAT12
;ES:EDI - adres, pod który zostanie wczytany plik,
;AX - pierwszy sektor pliku.
  push eax
  add ax, PIERWSZY_SEKTOR_Z_DANYMI
  mov dx, ax ; numer sektora
  mov ecx, 1
  CALL ODCZYTAJ_N_SEKTOROW
  cmp eax, 0
  jne .odczyt_sie_udal
  pop eax
  xor eax, eax
  jmp .koniec_procedury
  .odczyt_sie_udal
  pop edx
  cmp ebx, 512
  jbe .koniec_procedury
  add edi, 200h  ;adres do odczytu kolejnego sektora
  CALL NASTEPNY_CLUSTER
  CALL NORMALIZACJA_CLUSTRA
  cmp ax, 0ff7h    ;je¿eli zosta³ wczytany ostatni klaster pliku, to nale¿y zakoñczyæ procedurê.
  jbe WCZYTAJ_PLIK
  mov eax, 1
  .koniec_procedury:
RET

;Procedury opisane w rozdziale 9:

NASTEPNY_CLUSTER:
  push esi
  xor eax, eax
  mov ax, dx
  shr ax, 1h
  add ax, dx
  add esi, eax
  mov ax, word [gs:esi]
  pop esi
RET

NORMALIZACJA_CLUSTRA
  test dx, 1h
  jz parzysty
  shr ax, 4h
  jmp koniec_n_c
  parzysty:
   and ax, 0fffh
  koniec_n_c:
RET

PIERWSZY_SEKTOR_Z_DANYMI  equ  31
