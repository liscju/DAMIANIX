INICJALIZUJ_PULE_DYNAMICZNA_DLA_ZADAN
;Procedura tworzy pule dynamiczn�, z kt�rej b�d� pobierane elementy do kolejki zada�.
  push eax
  push edx
  push ebx
  push ecx
  push esi
  push edi
  mov ax, es
  push eax
  mov ax, 8
  mov es, ax
;Obliczenie liczby niezb�dnych stron do dodania:
  mov eax, WIELKOSC_KOLEJKI_ZADAN * 8 +4
  xor edx, edx
  mov ebx,  4096
  div ebx
  cmp edx, 0
  je .dalej
  inc eax
  .dalej
   xor esi, esi
   mov edi, 5F000H
;Dodanie wymaganej liczby stron:
  call DODAJ_N_STRON_DO_PRZESTRZENI_ADRESOWEJ
  mov edi, ebx
  mov edx, 4 ; rozmiar pojedynczego elementu pola danych
  mov ecx, WIELKOSC_KOLEJKI_ZADAN
  CALL INICJUJ_PULE_DYNAMICZNA
  mov [kolejka_zadan+ KOLEJKA_ZADAN.ADRES_PULI], edi
  mov DWORD [kolejka_zadan+ KOLEJKA_ZADAN.POCZATEK], 0      ;Kolejka zada� jest pusta
  mov DWORD [kolejka_zadan+ KOLEJKA_ZADAN.KONIEC], 0
  pop eax
  mov es, ax
  pop edi
  pop esi
  pop ecx
  pop ebx
  pop edx
  pop eax
RET

DODAJ_ZADANIE_DO_KOLEJKI_ZADAN
;Procedura dodaje element do kolejki zada�.
;Parametry procedury:
;EAX - adres identyfikatora procesu
  push eax
  push edx
  push ebx
  push ecx
  push esi
  push edi
  mov bx, es
  push ebx
  mov bx, 8
  mov es, bx
  mov edi,  [kolejka_zadan+ KOLEJKA_ZADAN.ADRES_PULI]
  mov edx, 4      ; rozmiar pola danych
  call POBIERZ_ELEMENT_Z_PULI
  cmp edi, 0
  jne .pula_zwrocila_element
;Gdy ca�a pula jest zaj�ta:
  jmp .koniec_procedury
  .pula_zwrocila_element
  mov [es:edi], eax  ;Do pola danych zapisywany jest adres identyfikatora procesu
  mov esi, edi
  mov edi, [kolejka_zadan+ KOLEJKA_ZADAN.KONIEC]     ; adres ostatniego elementu kolejki
  mov edx, 4                                         ; rozmiar pola danych
  call DOLUZ_ELEMENT_NA_KONIEC_KOLEJKI
  mov eax, 0
  cmp eax, [kolejka_zadan+ KOLEJKA_ZADAN.POCZATEK]   ; je�eli adres pierwszego elementu kolejki jest r�wny 0 to znaczy, ze do�o�ono pierwszy element
  jne .kolejka_zawiera_wiecej_niz_jeden_element
  mov [kolejka_zadan+ KOLEJKA_ZADAN.POCZATEK], edi
  .kolejka_zawiera_wiecej_niz_jeden_element:
  mov [kolejka_zadan+KOLEJKA_ZADAN.KONIEC], edi
  .koniec_procedury:
  pop ebx
  mov es, bx
  pop edi
  pop esi
  pop ecx
  pop ebx
  pop edx
  pop eax
RET

USUN_ZADANIE_Z_KOLEJKI_ZADAN
;Procedura usuwa element z kolejki zada�.
;Parametry procedury:
;EAX - adres identyfikatora procesu.
  push eax
  push edx
  push ebx
  push ecx
  push esi
  push edi
  mov bx, es
  push ebx
  mov bx, 8
  mov es, bx
  mov edi,  [kolejka_zadan+ KOLEJKA_ZADAN.POCZATEK]  ; pierwszy element
  CALL ZNAJDZ_ELEMENT_O_OKRESLONYM_POLU_DANYCH
; ESI wskazuje adres znalezionego elementu
  cmp esi, 0
  je .nie_ma_takiego_elementu
  mov edi, [kolejka_zadan+ KOLEJKA_ZADAN.POCZATEK]
  mov ecx, [kolejka_zadan+ KOLEJKA_ZADAN.KONIEC]
  mov edx, 4
  call USUN_ELEMENT_Z_KOLEJKI
  mov [kolejka_zadan+ KOLEJKA_ZADAN.POCZATEK], ebx
  mov [kolejka_zadan+ KOLEJKA_ZADAN.KONIEC], ecx
  mov edi, [kolejka_zadan+KOLEJKA_ZADAN.ADRES_PULI]
  CALL DOLUZ_ELEMENT_DO_PULI
  .nie_ma_takiego_elementu
  pop ebx
  mov es, bx
  pop edi
  pop esi
  pop ecx
  pop ebx
  pop edx
  pop eax
RET


PRZELACZ_ZADANIA
;Procedura rotuje w lewo kolejk� zada�, a� do odnalezienia nieu�pionego zadania.
  push ebx
  mov bx, es
  push ebx
  mov bx, 8
  mov es, bx
  mov edi,  [kolejka_zadan+ KOLEJKA_ZADAN.POCZATEK]
  mov esi,  [kolejka_zadan+ KOLEJKA_ZADAN.KONIEC]
  mov edx, 4
  .petla:
    CALL ROTUJ_KOLEJKE_W_LEWO_Z_PRZENIESIENIEM_NA_KONIEC
    mov eax, [es:edi]
    test eax, 1           ; gdy ostatni bit ustawiony jest na 0 to zadanie jest gotowe
    jz .znaleziono_zadanie_aktywne
  jmp .petla
  .znaleziono_zadanie_aktywne
  mov [kolejka_zadan+ KOLEJKA_ZADAN.POCZATEK], edi
  mov [kolejka_zadan+ KOLEJKA_ZADAN.KONIEC], esi
  mov edi, [es:edi]
  pop ebx
  mov es, bx
  pop ebx
RET


UAKTUALNIJ_KATALOG_STRON_WSZYSTKICH_ZADAN
;Procedura ma za zadanie wprowadzi� 32-bitowy wpis (rejestr EBX) do wszystkich
;katalog�w stron zada�, pod adres wzgl�dem poc�tku katalogu stron okre�lony
;rejestrem EDI.
  PUSHA
  mov ax, es
  push eax
  sub edi, 5f000h
  mov esi,  [kolejka_zadan+KOLEJKA_ZADAN.POCZATEK]
  .petla_skakania_po_wszystkich_zadaniach
    cmp esi, 0
    je .koniec_petli
    push esi
    mov esi, [es:esi]  ;adres identyfiaktora procesu
    mov esi, [es:esi + IDENTYFIKATOR_PROCESU.ADRES_TSS] ;adres TSS zadania
    mov esi, [es:esi + TSS.CR3]  ;adres katalogu stron
    and esi, 0fffff000h
    add esi, edi                 ;obliczenie adresu, pod kt�ry nale�y wprowadzi� wpis
    mov [es:esi], ebx
    pop esi
    mov esi, [es:esi+ 4]
  jmp   .petla_skakania_po_wszystkich_zadaniach
  .koniec_petli:
  pop eax
  mov es, ax
  POPA
RET


PRZYGOTUJ_TSS
;Procedura inicjalizuje segment TSS zadania.
;Parametry procedury:
;ES:EDI - adres TSS zadania
;EBX - EIP zadania
;ECX - wierzcho�ek stosu.
  pusha
  push eax
  mov WORD  [es:edi+ TSS.LINK_DO_POPRZEDNIEGO_ZADANIA], 0
  mov word  [es:edi+ TSS.NULL_1], 0
  mov dword [es:edi+ TSS.ESP0],ESP
  sub dword [es:edi+TSS.ESP0], ecx
  sub dword [es:edi+TSS.ESP0],  100
  mov ax, ss
  mov      [es:edi+TSS.SS0],  ax
  mov word [es:edi+TSS.NULL_2], 0
  mov dword [es:edi+ TSS.ESP1], ESP
  SUB  [ES:EDI+TSS.ESP1], ecx

  mov ax, ss
  mov      [es:edi+TSS.SS1],  ax
  mov word [es:edi+TSS.NULL_3],  0
  mov dword [es:edi+ TSS.ESP2], ESP
  mov ax, ss
  mov      [es:edi+TSS.SS2], ax
  mov word [es:edi+TSS.NULL_4],   0
   
  mov eax, cr3
  mov [es:edi+TSS.CR3], eax
   
  mov [es:edi+TSS.EIP], ebx
   
  mov eax,  esp
  mov [es:edi+TSS.ESP], eax
  SUB  [ES:EDI+TSS.ESP], ecx
  mov ax, es
  mov [es:edi+TSS.ES], ax
   
  mov ax, cs
  mov [es:edi+TSS.CS],   ax
   
  mov ax, ss
  mov [es:edi+TSS.SS],  ax
   
  mov ax, ds
  mov [es:edi+TSS.DS], ax
   
  mov ax, ds
  mov [es:edi+TSS.FS], ax
   
  mov ax, ds
  mov [es:edi+TSS.GS],  ax

  xor ax, ax
  mov [es:edi+TSS.T],  ax
  pop eax
  popa
RET


INICJALIZUJ_WIELOZADANIOWOSC
;Procedura wykonuje nast�puj�ce czynno�ci:
; - inicjuje pule dynamiczn� przeznaczon� dla kolejki zada�,
; - wype�nia segment TSS oraz identyfikator procesu g��wnego,
; - dodaje element kolejki zada� dla procesu g��wnego.
  pusha
  mov ax, es
  push eax
;Poszukiwanie pierwszej wolnej pozycji w tablicy GDT
  mov edi, 70008h   ;pocz�tkowy adres
  mov ecx, 0ffffh + 70000h   ;limit szukania
  call ZNAJDZ_PIERWSZA_WOLNA_POZYCJE_W_TABLICY_DESKYPTOROW
  mov ebx, jadro_
  add ebx, 80000h
;Tworzenie deskryptora TSS:
  mov eax, 104
  mov cx, 1100000010001001b
  call ODLUZ_DESKRYPTOR_DO_TABLICY_DESKRYPTOROW
  sub edi, 70000h  ;obliczenie warto�ci selektora TSS
  mov [jadro+ IDENTYFIKATOR_PROCESU.SELEKTOR_TSS], di
  ltr di    ;Zapis do rejestru TR selektor TSS
  MOV EAX, CR3
  mov [jadro+IDENTYFIKATOR_PROCESU.CR3], EAX  ;adres katalogu stron (warto�� rejestru CR3)
  call INICJALIZUJ_PULE_DYNAMICZNA_DLA_ZADAN
  mov ebx, jadro
  add ebx, 80000h
  mov edi, 5f000h
  call ZAMIEN_ADRES_LINIOWY_NA_FIZYCZNY
  mov eax, edi
  mov [id_interpretatora], eax
  call  DODAJ_ZADANIE_DO_KOLEJKI_ZADAN
  mov ax, 8
  mov gs, ax
  mov edi, jadro_
  add edi, 80000h
;Ustalenie warto�ci poszczeg�lnych p�l segmentu TSS:
  mov dword [es:edi+ TSS.ESP0], ESP
  mov ax, ss
  mov      [es:edi+TSS.SS0],  ax

  mov dword [es:edi+ TSS.ESP1],  ESP
  mov ax, ss
  mov      [es:edi+TSS.SS1], ax

  mov dword [es:edi+ TSS.ESP2], ESP
  mov ax, ss
  mov      [es:edi+TSS.SS2], ax
   
  mov eax, cr3
  mov [es:edi+TSS.CR3], eax
  pop eax
  mov es, ax
;uruchomienie wielozadaniowo�ci:
  mov byte [nimo], 1
  popa
RET

TWORZ_SEGMENTY_ZADANIA
;Procedura tworzy segmenty zadania (kodu, stosu, danych) oraz wype�nia tablic� LDT.
;Parametry procedury:
;ES:EDI - adres struktury pocz�tkowej programu.
  PUSHA
   mov esi, edi
   push esi
   add esi, STRUKTURA_POCZATKU_PROGRAMU.POCZATEK_KODU  ;adres kodu
   add edi, STRUKTURA_POCZATKU_PROGRAMU.LDT ; adres tablicy LDT
   add edi, 8

   mov ebx, esi ;adres kodu
   mov eax, 0ffffffffh ;limit
   mov cx, 1100000011111010b  ; G=1, D/B=1, 0=0, avl=0, 0=0, 0=0, 0=0, 0=0, P=1, DPL1=1, DPL2=1, S=1, program=1, c=0, r=1, a=0
   call ODLUZ_DESKRYPTOR_DO_TABLICY_DESKRYPTOROW ;deskryptor programu
   add edi, 8
   mov ebx, esi
   mov eax, 0ffffffffh
   mov cx,  1100000011110010b  ; G=1, D/B=1, 0=0, avl=0, 0=0, 0=0, 0=0, 0=0, P=1, DPL1=1, DPL2=1, S=1, program=0, expand-down=0, W=1, a=0
   call ODLUZ_DESKRYPTOR_DO_TABLICY_DESKRYPTOROW  ;deskryptor danych
   push edi
;dodanie strony na segmenty stos�w:
   mov eax, 1
   mov edi, 5f000h
   call DODAJ_N_STRON_DO_PRZESTRZENI_ADRESOWEJ_USER
   pop edi
   push ebx       ; odkladam adres stosu
   add edi, 8
   mov eax, 0
   mov cx, 0100000011110110b  ; G=0, D/B=1, 0=0, avl=0, 0=0, 0=0, 0=0, 0=0, P=1, DPL1=1, DPL2=1, S=1, program=0, expand-down=1, W=1, a=0
   call ODLUZ_DESKRYPTOR_DO_TABLICY_DESKRYPTOROW    ;deskryptor stosu
;stos zadania
  add edi, 8
  mov eax, 0
  mov cx, 0100000010010110b
  call ODLUZ_DESKRYPTOR_DO_TABLICY_DESKRYPTOROW
  pop ebx
  pop edi ;adres pocz�tkowej struktury programu
  mov [es:edi+STRUKTURA_POCZATKU_PROGRAMU.IDENTYFIKATOR_PROCESU +IDENTYFIKATOR_PROCESU.SS], ebx
  mov [es:edi+STRUKTURA_POCZATKU_PROGRAMU.IDENTYFIKATOR_PROCESU +IDENTYFIKATOR_PROCESU.ADRES_TSS], edi
  mov WORD  [es:edi+ TSS.LINK_DO_POPRZEDNIEGO_ZADANIA], 0
  mov word  [es:edi+ TSS.NULL_1], 0
;pozosta�e stosy:
   mov dword [es:edi+ TSS.ESP0],  2047
   mov ax, 32
   or ax, 100b
   mov      [es:edi+TSS.SS0], ax
   mov word [es:edi+TSS.NULL_2],   0

   mov dword [es:edi+ TSS.ESP1], 2047
   mov      [es:edi+TSS.SS1], ax
   mov word [es:edi+TSS.NULL_3], 0

   mov dword [es:edi+ TSS.ESP2], 2047
   mov      [es:edi+TSS.SS2], ax
   mov word [es:edi+TSS.NULL_4], 0

;rejestry zadania:
   mov dword [es:edi+TSS.EIP],  0
   mov dword [es:edi+TSS.ESP],   4095
   mov ax, 16
   or  ax, 111b
   mov [es:edi+TSS.ES], ax
   mov [es:edi+TSS.DS], ax
   mov [es:edi+TSS.FS], ax
   mov [es:edi+TSS.GS], ax
   mov ax, 8
   or ax, 111b
   mov [es:edi+TSS.CS], ax
   mov ax, 24
   or ax, 111b
   mov [es:edi+TSS.SS], ax
   xor ax, ax
   mov [es:edi+TSS.T], ax
   pushfd
   pop eax
   or eax, 1000000000b
   mov [es:edi+TSS.EFLAGS],  eax
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;TABLICA LDT ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   push edi
   mov edi, 70008h
   mov ecx, 0ffffh + 70000h
   call ZNAJDZ_PIERWSZA_WOLNA_POZYCJE_W_TABLICY_DESKYPTOROW
   pop ebx  ;adres struktury pocz�tkowej zadania
   push ebx
   add ebx, STRUKTURA_POCZATKU_PROGRAMU.LDT
   mov eax, 160  ; tyle maksymalnie bedzie wpisow
   mov cx, 1100000011100010b      ; ; G=1, D/B=1, 0=0, avl=0, 0=0, 0=0, 0=0, 0=0, P=1, DPL1=1, DPL2=1, S=1, ldt1, ldt2, ldt3, ldt4
   call ODLUZ_DESKRYPTOR_DO_TABLICY_DESKRYPTOROW
   sub edi, 70000h
   or di, 11b    ; poziom uprzywilejowania 3
   pop eax
;;;;;;;;;;;;;;;;;;;;;;;;;;;; TSS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   push eax
   xchg eax, edi
   mov [es:edi+TSS.LDT_SELEKTOR],   ax
   xchg eax, edi
   mov edi, 70008h
   mov ecx, 0ffffh + 70008h
   call ZNAJDZ_PIERWSZA_WOLNA_POZYCJE_W_TABLICY_DESKYPTOROW
   pop ebx    ; adres bazowby tablicy LDT
   push ebx
   add ebx, STRUKTURA_POCZATKU_PROGRAMU.TSS
   mov eax, 104
   mov cx, 1100000011101001b
   call ODLUZ_DESKRYPTOR_DO_TABLICY_DESKRYPTOROW
   sub edi, 70000h
   or edi, 11b
   pop eax
   xchg eax, edi
   mov [es:edi + STRUKTURA_POCZATKU_PROGRAMU.IDENTYFIKATOR_PROCESU +IDENTYFIKATOR_PROCESU.SELEKTOR_TSS], ax
   xchg eax, edi
   POPA
RET


INICJUJ_STRONICOWANIE_ZADANIA
;Procedura tworzy elemety stronicowania zadania.
;Parametry procedury:
;ES:EDI - adres pocz�tkowej struktury zadania.
  pusha
  mov ax, es
  push eax
  mov ax, 8
  mov es, ax
  push edi
  mov eax, 1
  mov edi, 5f000h
  call DODAJ_N_STRON_DO_PRZESTRZENI_ADRESOWEJ_USER ;tworzone jest miejsce na katalog stron zadania
  push ebx
  mov edi, 5f000h
  call ZAMIEN_ADRES_LINIOWY_NA_FIZYCZNY
  mov eax, cr3
  and eax, 0fffh
  and edi, 0fffff000h
  or eax, edi
  pop ebx
  pop edi
  mov [es:edi+TSS.CR3], eax
  mov [es:edi+STRUKTURA_POCZATKU_PROGRAMU.IDENTYFIKATOR_PROCESU+IDENTYFIKATOR_PROCESU.CR3], eax
  mov [es:edi+STRUKTURA_POCZATKU_PROGRAMU.IDENTYFIKATOR_PROCESU+IDENTYFIKATOR_PROCESU.PD],  ebx
  pop eax
  mov es, ax
  popa
RET

KOPIUJ_KATALOG_STRON_DLA_ZADANIA
;Procedura tworzy kopi� katalogu stron zadania g��wnego dla dodawanego zadania.
;Parametry procedury:
;ES:EDI - adres pocz�tkowej struktury programu.
  PUSHA
  mov edi, [es:edi+STRUKTURA_POCZATKU_PROGRAMU.TSS+ TSS.CR3]
  and edi, 0fffff000h
  call OGOLNA_NORMALIZACJA_ADRESU
  call KOPIUJ_GLOWNY_KATALOG_STRON
  POPA
RET

PRZYGOTUJ_MIEJSCE_NA_NOWE_ZADANIE
;Procedura organizuje pami�� na nowo dodawane zadanie.
;Parametry procedury:
;EAX - rozmiar programu,
;Wyniki:
;ES:EDI - adres pocz�tkowej struktury programu.
  push eax
  push edx
  push ecx
  mov cx, es
  push ecx
  mov cx, 8
  mov es, cx
  mov edi, 5f000h
  add eax, STRUKTURA_POCZATKU_PROGRAMU.POCZATEK_KODU     ;do rozmiaru programu nast�puje dodanie rozmiaru struktury pocz�tkowej programu
  xor edx, edx
;Obliczenie niezb�dnej ilo�ci stron na program i struktur� pocz�tkow�:
  mov ecx, 4096
  div ecx
  cmp edx, 0
  je .nie_ma_reszty
  inc eax
  .nie_ma_reszty
  push eax
  call DODAJ_N_STRON_DO_PRZESTRZENI_ADRESOWEJ_USER ;uzyskanie obszaru pami�ci na program i struktur� pocz�tkow�.
  pop eax
  mov edi, ebx
  mov [es:edi + STRUKTURA_POCZATKU_PROGRAMU.IDENTYFIKATOR_PROCESU + IDENTYFIKATOR_PROCESU.WIELKOSC], ax
  call TWORZ_SEGMENTY_ZADANIA
  call INICJUJ_STRONICOWANIE_ZADANIA
  push edi
  call KOPIUJ_KATALOG_STRON_DLA_ZADANIA
  pop edi
  pop eax
  mov es, ax
  pop ecx
  pop edx
  pop eax
RET

KOPIUJ_KOD_ZADANIA_NA_JEGO_MIEJSCE
;Procedura umieszcza kod programu we wskazanym obszarze pami�ci.
;Parametry procedury:
;EDI - adres pocz�tkowej struktury programu,
;ESI - adrs, z kt�rego zostanie skopiowany kod,
;EAX - rozmiar programu.
  PUSHA
  mov cx, es
  push ecx
  mov cx, ds
  push ecx
  mov cx, 8
  mov es, cx
  mov cx, 8
  mov ds, cx
  add edi, STRUKTURA_POCZATKU_PROGRAMU.POCZATEK_KODU  ;kod programu znajdzie si� za pocz�tkow� struktur� programu.
  mov ecx, eax
  rep movsb
  pop eax
  mov ds, ax
  pop eax
  mov es, ax
  POPA
RET

PRZYGOTUJ_ZADANIE_DO_ODPALENIA
;Procedura dodaje zadanie do kolejki zada�.
;Parametry procedury:
;EDI - adres pocz�tkowej struktury programu.
  PUSHA
  mov ebx, edi
  add ebx, STRUKTURA_POCZATKU_PROGRAMU.IDENTYFIKATOR_PROCESU
  mov edi, 5f000h ; adres katalogu stron
  call ZAMIEN_ADRES_LINIOWY_NA_FIZYCZNY
  mov eax, edi        ;EAX zawiera identyfikator procesu
  call DODAJ_ZADANIE_DO_KOLEJKI_ZADAN
  POPA
RET

PRZYGOTUJ_ZADANIE_DO_ODPALENIA_W_ZAWIESZENIU
;Procedura dodaje zadanie do kolejki zada�, zadanie zostaje u�pione.
;Parametry procedury:
;EDI - adres pocz�tkowej struktury programu.
  PUSHA
  mov ebx, edi
  add ebx, STRUKTURA_POCZATKU_PROGRAMU.IDENTYFIKATOR_PROCESU
  mov edi, 5f000h ; adres katalogu stron
  call ZAMIEN_ADRES_LINIOWY_NA_FIZYCZNY
  or edi, 1              ;u�pienie zadania
  mov eax, edi
  call DODAJ_ZADANIE_DO_KOLEJKI_ZADAN
  POPA
RET

ZWROC_ADRES_FIZYCZY_IDENTYFIKATORA_AKTUALNEGO_ZADANIA
;Procedura zwraca adres fizyczny identyfikatora aktualnego zadania
;(czyli jego pole danych w kolejce zada�).
  PUSH EAX
  push edi
  mov ax, es
  push eax
  mov ax, 8
  mov es, ax
  mov al, [nimo]
  cmp al, 0
  je .koniec
  mov edi, [kolejka_zadan + KOLEJKA_ZADAN.POCZATEK]
  mov ecx, [es:edi]
  .koniec
  pop eax
  mov es, ax
  pop edi
  POP EAX
RET

PROCEDURA_WYWLASZCZAJACA
;Wywo�anie procedury ko�czy dzia�anie obecnego zadania i uruchamia nast�pne z kolejki zada�.
;Podejmowane dzia�ania przez procedur� s� analogiczne do dzia�a� schedulera.
  CLI
  pusha
  pushf
  mov ax, ds
  push eax
  mov ax, es
  push eax
  mov ax, 24
  mov ds, ax
  mov ax, 8
  mov es, ax
  cmp byte [nimo], 0    ;sprawdzenie, czy wielozadaniowo�� zosta�a zainicjalizowana
  je .dalej
  call ZWROC_ADRES_FIZYCZY_IDENTYFIKATORA_AKTUALNEGO_ZADANIA
  CALL PRZELACZ_ZADANIA
  cmp ecx, edi
  jne .zadania_sa_rozne
  jmp nie_mozna_przelaczyc_zadan
  .zadania_sa_rozne
  CALL OGOLNA_NORMALIZACJA_ADRESU    ;uzyskanie identyfikatora zadania.
  PUSH EDI
  mov di, [es:edi+IDENTYFIKATOR_PROCESU.SELEKTOR_TSS]
  mov [SELEKTOR_], DI
  POP EDI
  mov edx, cr3
  mov ecx, [es:edi+IDENTYFIKATOR_PROCESU.CR3]
  mov cr3, ecx
  .dalej
  cmp byte [nimo], 0
  je PROCEDURA_WYWLASZCZAJACA_dalej2
  PREFIX_          db 67h
  POLECENIE_       db 0eah
  OFFSET_          dd 12345
  SELEKTOR_      dw 40h
  mov cr3, edx
  PROCEDURA_WYWLASZCZAJACA_dalej2
  nie_mozna_przelaczyc_zadan
  pop eax
  mov es, ax
  pop eax
  mov ds, ax
popf
popa
STI
RET

USPANIE_WSZYSTKICH_ZADAN
;Procedura usypia wszysktie zadania z kolejki zada�.
  PUSHA
  mov ax, es
  push eax
  mov ax, ds
  push eax
  mov ax, 24
  mov ds, ax
  mov edi, [kolejka_zadan+KOLEJKA_ZADAN.POCZATEK]
  push edi
  mov ax, 8
  mov es, ax
  cmp edi, 0
  jne .petla_poszukiwania
;Gdy kolejka jest pusta:
  mov esi, 0
  jmp .koniec_procedury
  .petla_poszukiwania:
    or dword [es:edi], 1    ; u�pienie zadania
    mov edi, [es:edi+4]
    cmp edi, 0
    jne .mozna_dalej
    mov esi, 0
    jmp .koniec_procedury
    .mozna_dalej:
  jmp .petla_poszukiwania
  .koniec_procedury:
  pop edi
;nale�y obudzi� proces interpretatora polece� systemu, aby nie "zaci��" systemu:
;Poszukiwanie elementu zadania g��wnego:
  mov eax, [id_interpretatora]
  or eax, 1
  call ZNAJDZ_ELEMENT_O_OKRESLONYM_POLU_DANYCH
  mov edi, esi
  and dword [es:esi], 0fffffffeh
;Zwolnienie urz�dze�:
  mov WORD [FDD_ + URZADZENIE.STAN],0
  mov DWORD [FDD_+  URZADZENIE.ID_PROCESU_WLASCICIELA], 0
  mov WORD [EKRAN_ + URZADZENIE.STAN], 0
  mov DWORD [EKRAN_+  URZADZENIE.ID_PROCESU_WLASCICIELA], 0
  mov WORD [KLAWIATURA_ + URZADZENIE.STAN], 0
  mov DWORD [KLAWIATURA_+  URZADZENIE.ID_PROCESU_WLASCICIELA], 0
  pop eax
  mov ds, ax
  pop eax
  mov es, ax
  POPA
RET


OBUDZENIE_WSZYSTKIEGO
;Procedura budzi wszystkie u�pione zadania.
  PUSHA
  mov ax, es
  push eax
  cli
  mov edi, [kolejka_zadan+KOLEJKA_ZADAN.POCZATEK]
  push edi
  mov ax, 8
  mov es, ax
  cmp edi, 0
  jne .petla_poszukiwania
  mov esi, 0
  jmp .koniec_procedury
  .petla_poszukiwania:
    and dword [es:edi], 0fffffffeh  ;budzenie procesu
    mov edi, [es:edi+4] ; z zalozenia 4 bajty powyzej adresu elementu znajduje sie wskaznik na nastepny elementy
    cmp edi, 0
    jne .mozna_dalej
    mov esi, 0
    jmp .koniec_procedury  ; jezeli wskaznik nastepnego elementu jest null-em, to kone procedure
    .mozna_dalej:
  jmp .petla_poszukiwania
  .koniec_procedury:
  pop edi
;Zwolnienie wszystkich urz�dze�:
  mov WORD [FDD_ + URZADZENIE.STAN], 0
  mov DWORD [FDD_+  URZADZENIE.ID_PROCESU_WLASCICIELA], 0
  mov WORD [EKRAN_ + URZADZENIE.STAN], 0
  mov DWORD [EKRAN_+  URZADZENIE.ID_PROCESU_WLASCICIELA], 0
  mov WORD [KLAWIATURA_ + URZADZENIE.STAN], 0
  mov DWORD [KLAWIATURA_+  URZADZENIE.ID_PROCESU_WLASCICIELA], 0
  sti
  pop eax
  mov es, ax
  POPA
RET


USUN_ZADANIE
;Procedura usuwa zadanie z systemu.
;Parametry procedury:
;EAX - ID procesu.
  pusha
;Usuni�cie wpisu z kolejki zada�:
  call USUN_ZADANIE_Z_KOLEJKI_ZADAN
  and eax, 0fffff000h
  mov edi, eax
  push edi
;Tworzony dost�p do pierwszej strony zadania:
  call OGOLNA_NORMALIZACJA_ADRESU
  mov ebx, [es:edi+STRUKTURA_POCZATKU_PROGRAMU.IDENTYFIKATOR_PROCESU+IDENTYFIKATOR_PROCESU.PD]   ;adres katalogu stron zadania
  mov ecx, 1
  mov edi, 5f000h
  call USUN_N_STRON_POCZAWSZY_OD_EBX         ;usuni�cie strony katalogu stron
  pop edi
  push edi
;Czynno�ci zwi�zane z usuwanie stos�w zadania:
  call OGOLNA_NORMALIZACJA_ADRESU
  mov ebx, [es:edi+STRUKTURA_POCZATKU_PROGRAMU.IDENTYFIKATOR_PROCESU+IDENTYFIKATOR_PROCESU.SS]
  mov ecx, 1
  mov edi, 5f000h
  call USUN_N_STRON_POCZAWSZY_OD_EBX
  pop edi
  push edi
;Czynno�ci zwi�zane z usuni�ciem stron zajmowanych przez kod zadania:
  call OGOLNA_NORMALIZACJA_ADRESU
  mov ebx, [es:edi+STRUKTURA_POCZATKU_PROGRAMU.IDENTYFIKATOR_PROCESU+IDENTYFIKATOR_PROCESU.ADRES_TSS]
  xor ecx, ecx
  mov cx, [es:edi+STRUKTURA_POCZATKU_PROGRAMU.IDENTYFIKATOR_PROCESU+IDENTYFIKATOR_PROCESU.WIELKOSC]
  mov edi, 5f000h
  call USUN_N_STRON_POCZAWSZY_OD_EBX
  pop edi
  popa
ret

KILL_ALL
;Procedura usuwa wszystkie u�pione procesy.
  pusha
  mov ax, es
  push eax
  mov ax, ds
  push eax
  cli
  mov edi, [kolejka_zadan+KOLEJKA_ZADAN.POCZATEK]
  push edi
  mov ax, 8
  mov es, ax
  mov ax, 24
  mov ds, ax
  cmp edi, 0
  jne .petla_poszukiwania
  mov esi, 0
  jmp .koniec_procedury
  .petla_poszukiwania:
    mov eax,  [es:edi]
    mov ecx,  [es:edi+4]
    test eax, 1
    jz .dalej
    call USUN_ZADANIE
    .dalej:
    mov edi, ecx
    cmp edi, 0
    jne .mozna_dalej
    mov esi, 0
    jmp .koniec_procedury
    .mozna_dalej:
  jmp .petla_poszukiwania
  .koniec_procedury:
  pop edi
;Zwolnienie wszystkich urz�dze�:
  mov WORD [FDD_ + URZADZENIE.STAN], 0
  mov DWORD [FDD_+  URZADZENIE.ID_PROCESU_WLASCICIELA], 0
  mov WORD [EKRAN_ + URZADZENIE.STAN], 0
  mov DWORD [EKRAN_+  URZADZENIE.ID_PROCESU_WLASCICIELA], 0
  mov WORD [KLAWIATURA_ + URZADZENIE.STAN], 0
  mov DWORD [KLAWIATURA_+  URZADZENIE.ID_PROCESU_WLASCICIELA], 0
  sti
  pop eax
  mov ds, ax
  pop eax
  mov es, ax
  popa
ret


OBUDZENIE_WSZYSTKICH_ZADAN
  PUSHA
  mov ax, es
  push eax
  cli
  mov edi, [kolejka_zadan+KOLEJKA_ZADAN.POCZATEK]
  push edi
  mov ax, 8
  mov es, ax
  cmp edi, 0
  jne .petla_poszukiwania
  mov esi, 0
  jmp .koniec_procedury
  .petla_poszukiwania:
    and dword [es:edi], 0fffffffeh
    mov edi, [es:edi+4]
    cmp edi, 0
    jne .mozna_dalej
    mov esi, 0
    jmp .koniec_procedury
    .mozna_dalej:
  jmp .petla_poszukiwania
  .koniec_procedury:
;Obudzenie interpretatora polece�:
  pop edi
  mov eax, [id_interpretatora]
  call ZNAJDZ_ELEMENT_O_OKRESLONYM_POLU_DANYCH
  or dword [es:esi], 1h
  mov WORD [FDD_ + URZADZENIE.STAN], 0
  mov DWORD [FDD_+  URZADZENIE.ID_PROCESU_WLASCICIELA], 0
  mov WORD [EKRAN_ + URZADZENIE.STAN], 0
  mov DWORD [EKRAN_+  URZADZENIE.ID_PROCESU_WLASCICIELA], 0
  mov WORD [KLAWIATURA_ + URZADZENIE.STAN], 0
  mov DWORD [KLAWIATURA_+  URZADZENIE.ID_PROCESU_WLASCICIELA], 0
  sti
  pop eax
  mov es, ax
  POPA
RET
