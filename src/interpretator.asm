;Tablica przechowywuj¹ca wprowadzane polecenie:
polecenie           times   500      db         0
;wskaŸnik po³o¿enia w tablicy polecenie:
pointer_polecenia                    dw         0

dlugosc_polecenia                    dw         0
stala_wywlaszczenia                  dw       255
licznik_wywlaszczenia                dw         0

struc ARGUMENT
      .POCZATEK                    resd    1
      .KONIEC                      resd    1
endstruc

argument1     times 2 dd 0
argument2     times 2 dd 0
komenda                              times 3 db 0

;Struktura umo¿liwiaj¹ca powi¹zanie polecenia wpisanego z klawiatury
;z odpowiedni¹ procedur¹ w systemie:
NULL                                 DB         0
polecenia:
czy_plik_dostepny_w_katalogu_glownym
                                     db         '.'
                                     db         '?'
                                     db         0
                                     dd         INTERPRETATOR_CZY_JEST_PLIK_W_K_G
                                     
wielkosc_pliku_k_g                   db         '.'
                                     db         '#'
                                     db          0
                                     dd          INTERPRETATOR_PODAJ_WIELKOSC_PLIKU_K_G
                                     
wyswietl_pliki_k_g                   db          '.'
                                     db          '*'
                                     db          0
                                     dd          INTERPRETATOR_WYPISZ_PLIKI_KATALOGU_GLOWNEGO

obudz_wszystkie_zadania              db         '*'
                                     db          0
                                     db          0
                                     dd          OBUDZENIE_WSZYSTKICH_ZADAN
                                     
                                     
obudzenie_wszystkiego                db         '*'
                                     db         '*'
                                     db          0
                                     dd          OBUDZENIE_WSZYSTKIEGO

                                     
pierwszy_sektor_k_g                  db          '.'
                                     db          '1'
                                     db          0
                                     dd          INTERPRETATOR_PODAJ_PIERWSZY_SEKTOR_PLIKU_K_G
                                     
wyswietl_plik_k_g                    db          '.'
                                     db          ':'
                                     db          0
                                     dd          INTERPRETATOR_WYSWIETL_PLIK_K_G

uruchom_program                      db          '.'
                                     db          '^'
                                     db           0
                                     dd           PRZYGOTUJ_PLIK_DO_URUCHOMIENIA
                                     

uruchom_program_w_zawieszeniu        db          '.'
                                     db          '^'
                                     db          '_'
                                     dd           PRZYGOTUJ_PLIK_DO_URUCHOMIENIA_W_ZAWIESZENIU
                                     
zabicie_wszystkich_zadan             db          '*'
                                     db          'x'
                                     db          0
                                     dd          KILL_ALL
                                     
polecenie_koncowe                                       times 7 db 0 ;"wartownik" struktury oznaczaj¹cy jej koniec

INTERPRETATOR_POLECEN:
  call ODCZYTAJ_Z_BUFORA     ;uzyskanie kolejnego znaku z bufora klawiatury.
  cmp ax, 0
  jne .dalej2
;W przypadku, gdy interpretator przez okreœlon¹ liczbê cykli pêtli nie
;odczyta ¿adnego znaku z bufora klawiatury, mo¿e wywo³aæ procedurê wyw³aszczaj¹c¹
;(element pozostawiony czytelnikom do realizacji).
  inc word [licznik_wywlaszczenia]
  mov ax, licznik_wywlaszczenia
  cmp ax, [stala_wywlaszczenia]
  jb .dalej
  mov word [licznik_wywlaszczenia], 0
     ;tu powinno znaleŸæ siê wywo³anie procedury wyw³aszczaj¹cej.
  .dalej:
  jmp INTERPRETATOR_POLECEN
  .dalej2:
  cmp ah, 0     ;czy przyciœniêty klawisz posiada znak ASCII
  jne .znak_ascii
  jmp .znak_nacisniecia
  .znak_ascii
  xor edi, edi
  mov di, [pointer_polecenia]
  cmp ah, 13   ;czy naciœniêto ENTER
  jne .nie_enter
  call NACISNIETY_ENTER
  jmp INTERPRETATOR_POLECEN
  .nie_enter:
  cmp ah, 08h  ;czy naciœniêto BACK SPACE
  jne .nie_back_space
  call NACISNIETY_BACK_SPACE
  jmp INTERPRETATOR_POLECEN
  .nie_back_space:
  call NACISNIETY_ZNAK_ASCII
  jmp INTERPRETATOR_POLECEN
  .znak_nacisniecia:
  cmp al, 75  ;czy naciœniêto strza³kê w lewo
  jne .nie_strzalka_w_lewo
  CALL STRZALKA_W_LEWO
  jmp INTERPRETATOR_POLECEN
  .nie_strzalka_w_lewo:
  cmp al, 77  ;czy naciœniêto strza³kê w prawo
  jne .nie_strzalka_w_prawo
  CALL STRZALKA_W_PRAWO
  jmp INTERPRETATOR_POLECEN
  .nie_strzalka_w_prawo:
  cmp al, 79
  jne .nie_end
  CALL END
  jmp INTERPRETATOR_POLECEN
  .nie_end:
  jmp INTERPRETATOR_POLECEN

NORMALIZACJA_PRZED_WPROWADZENIEM_ZNAKU_EKRAN
;Procedura przygotowuje miejsce na ekranie, w któe zostanie umieszczony nowy znak.
;W przypadku, gdy kursor znajduje siê wewn¹trz wpisywanego ci¹gu znaków, procedura
;musi przesun¹æ wszystkie znaki stoj¹ce za kursorem o jedn¹ pozycjê do przodu.
  PUSHA
  mov bl, [kursor+KURSOR.x]
  mov bh, [kursor+KURSOR.y]
  push ebx
  xor edi, edi
  mov di, [pointer_polecenia]
  cmp di, [dlugosc_polecenia]
  je .koniec_petli
  mov dl, ' '
  call WYSWIETL_ZNAK
  .petla:
    mov dl, [polecenie+edi]
    cmp di, [dlugosc_polecenia]
    je .koniec_petli
    call WYSWIETL_ZNAK
    inc edi
  jmp .petla
  .koniec_petli:
  pop ebx
  mov [kursor+KURSOR.x], bl
  mov [kursor+KURSOR.y], bh
  call NORMALIZACJA_PRZED_USTAWIENIEM_KURSORA
  call USTAW_KURSOR_
POPA
RET


NORMALIZACJA_PRZED_WPROWADZENIEM_ZNAKU_POLECENIE
;Procedura organizuje miejsce w zmiennej tablicowej na wprowadzany znak.
;(nale¿y obs³u¿yæ sytuacjê, w której u¿ytkownik w œrodku wprowadzanego
;polecenia chce dodaæ znak).
  PUSHA
  xor edi, edi
  xor esi, esi
  xor ebx, ebx
  mov di, [dlugosc_polecenia] ;koniec polecenia
  mov si, [dlugosc_polecenia] 
  dec si
  mov bx, [pointer_polecenia]
  .petla
    mov al, [polecenie+esi]
    mov [polecenie+edi], al  ;kopiowanie znaku z tablicy o jedn¹ pozycjê dalej
    dec esi
    dec edi                  ;przygotowanie do kolejnego przebiegu pêtli.
    
    cmp di, [pointer_polecenia]  ;je¿eli miejsce docelowego kopiowania bêdzie siê pokrywaæ z ostatnim znakiem do skopiowania
                                 ;to oznacza, ¿e przekopiowane zosta³y wszystkie niezbêdne znaki.
  je .koniec_petli
  jmp .petla
  .koniec_petli
  POPA
RET


NORMALIZACJA_PO_SKASOWANIU_ZNAKU_EKRAN
;Procedura zape³nia puste miejsce, które powstanie w wyniku zkasowania znaku
;umieszczonego wewn¹trz wpisywanego ci¹gu na ekranie.
  PUSHA
  mov bl, [kursor+KURSOR.x]
  mov bh, [kursor+KURSOR.y]
  push ebx
  xor edi, edi
  mov di, [pointer_polecenia]
;Kopiowanie wszystkich znaków stoj¹cych za kursorem o jedn¹ pozycjê wczeœniej:
  .petla:
    mov dl, [polecenie+edi+1]
    cmp di, [dlugosc_polecenia]
    ja .koniec_petli
    call WYSWIETL_ZNAK
    inc edi
  jmp .petla
  .koniec_petli:
  pop ebx
  mov [kursor+KURSOR.x], bl
  mov [kursor+KURSOR.y], bh
  call NORMALIZACJA_PRZED_USTAWIENIEM_KURSORA
  call USTAW_KURSOR_
  POPA
RET


NORMALIZACJA_PO_SKASOWANIU_ZNAKU_POLECENIE
;Procedura zape³nia puste miejsce w tablicy polecenie, powsta³e w wyniku
;skasowania znaku umieszczonego wewn¹trz ci¹gu znaków.
  PUSHA
  xor edi, edi
  xor esi, esi
  xor ebx, ebx
  mov di, [pointer_polecenia]
  mov si, [pointer_polecenia]
  inc si
  mov bx, [dlugosc_polecenia] ; bx wskazuje na dlugosc polecenia
;Kopiowanie wszystkich znaków po³o¿onych bezpoœrednio za znakiem skasowanym o jedn¹
;pozycjê wczeœniej:
  .petla
    mov al, [polecenie+esi]
    mov [polecenie+edi], al
    inc esi
    inc edi
    cmp di, [dlugosc_polecenia]
    je .koniec_petli
  jmp .petla
  .koniec_petli
  POPA
RET


NACISNIETY_ENTER:
;Procedura wywo³ywana po naciœniêciu ENTERA przez u¿ytkownika.

;Zmiana koloru tekstu (po naciœniêciu ENTERA interpretator koloruje
;kolejn¹ liniê innym kolorem):
  mov al, [kursor+KURSOR.atrybut]
  cmp al, 0fh
  je .nie_bialy
  mov byte [kursor+KURSOR.atrybut], 0fh
  jmp .koniec_kolorowania_kursora
  .nie_bialy
  mov byte [kursor+KURSOR.atrybut], 0eh
  .koniec_kolorowania_kursora:
  call END  ;ustawienie kursora oraz zmiennej pointer_polecenia na koñcu wprowadzonego ci¹gu
;Gdy kursor jest ustawiony w przedostatniej linii ekranu, nastêpuje przewiniêcie ekranu
;o jedn¹ liniê w dó³:
  mov al, [kursor+KURSOR.y]
  cmp al, 24
  jne .dalej
  call LINIA_W_DOL
  dec byte [kursor+KURSOR.y]
  .dalej
;Ustawienie kursora w nowej linii:
  inc byte [kursor+KURSOR.y]
  mov byte [kursor+KURSOR.x], 0
  CALL NORMALIZACJA_PRZED_USTAWIENIEM_KURSORA
  CALL USTAW_KURSOR_
;Interpretacja wprowadzonego przez u¿ytkownika ci¹gu znaków:
 call INTERPRETACJA_KOMENDY
;Przygotowania do obs³ugi kolejnego polecenia u¿ytkownika:
  mov byte [komenda],     0
  mov byte [komenda +1 ], 0
  mov byte [komenda+2],   0
  mov ecx, 500
  xor edi, edi
  .petla_czyszczaca_polecenie
    mov byte [polecenie+edi], 0
    inc edi
  loop .petla_czyszczaca_polecenie
  mov word [pointer_polecenia], 0
  mov word [dlugosc_polecenia], 0
RET

NACISNIETY_BACK_SPACE
;Procedura wywo³ywana, gdy nast¹pi przyciœniêcie BACK SPACE

;Gdy BACK SPACE zosta³ przyciœniêty przed wprowadzeniem jakiegokolwiek znaku,
;mo¿na zakoñczyæ procedurê:
  cmp di, 0
  je .koniec
  dec edi
  dec word [pointer_polecenia]      ;dekrementacja pozycji wskazuj¹cej aktualne po³o¿enie w zmiennej polecenie
  dec word [dlugosc_polecenia]      ;dekrementacja zmiennej wskazuj¹cej liczbê znaków polecenia
  call SKASUJ_ZNAK                  ;skasowanie znaku z miejsca ustawienia kursora na ekranie
;Je¿eli skasowany znak znajdowa³ siê w œrodku wpowadzanego ci¹gu, nale¿y wype³niæ powsta³¹ lukê na ekranie i w tablicy polecenie:
  mov bx, [dlugosc_polecenia]
  cmp bx, [pointer_polecenia]
  je .dalej
  CALL NORMALIZACJA_PO_SKASOWANIU_ZNAKU_EKRAN
  CALL NORMALIZACJA_PO_SKASOWANIU_ZNAKU_POLECENIE
  .dalej
  xor edi, edi
  mov di, [dlugosc_polecenia]
  mov byte [polecenie+edi], 0
  .koniec
RET

NACISNIETY_ZNAK_ASCII
;Proceura wywo³ywana, gdy zostanie naciœniêty zwyk³y znak ASCII
  cmp di, 499     ;Sprawdzenie, czy polecenie nie jest zbyt d³ugie
  jae .koniec
  mov bx, [dlugosc_polecenia]
  cmp bx, [pointer_polecenia]  ;je¿eli wprowadzany jest znak na koñcu polecenia, to nie trzeba przesuwaæ innych znaków polecenia.
  je .dalej
;Gdy wprowadzany bêdzie znajdowa³ siê wewn¹trz innych znaków polecenia,
;nale¿y znaki stoj¹ce za kursorem (na ekranie i w tablicy polecenie)
;przekopiowaæ o jedn¹ pozycjê dalej:
  CALL NORMALIZACJA_PRZED_WPROWADZENIEM_ZNAKU_EKRAN
  CALL NORMALIZACJA_PRZED_WPROWADZENIEM_ZNAKU_POLECENIE
  .dalej
  mov dl, ah
  CALL WYSWIETL_ZNAK    ;wyœwietlenie znaku
  mov [polecenie+edi], ah
;aktualizacja wartoœci zmiennych pointer_polecenia i dlugosc_polecenia
  inc word [pointer_polecenia]
  inc word [dlugosc_polecenia]
  .koniec
RET

STRZALKA_W_LEWO
;Procedura wywo³ywana, gdy u¿ytkownik naciœnie strza³kê w lewo.
  xor ax, ax
  cmp ax, [pointer_polecenia]   ;gdy kursor znajduje siê na pocz¹tku polecenia
  je .koniec
  dec word [pointer_polecenia]  ;dekrementacja aktualnej pozycji w tablicy polecenie
;Czynnoœci zwi¹zane z prawid³owym ustawieniem kursora na ekranie:
  mov eax, 80
  mul byte [kursor + KURSOR.y]
  mov bl, [kursor+KURSOR.x]
  movzx bx, bl
  add ax, bx
  dec eax
  push eax
  mov bl, 80
  div bl
  mov [kursor+KURSOR.y], al
  mov [kursor+KURSOR.x], ah
  pop eax
  call USTAW_KURSOR_
  .koniec
RET

STRZALKA_W_PRAWO
;Procedura wywo³ywana, gdy u¿ytkownik naciœnie strza³kê w prawo
  mov ax, [dlugosc_polecenia]
  cmp ax, [pointer_polecenia]    ;gdy kursor stoi na koñcu nale¿y zakoñczyæ procedurê
  je .koniec
  inc word [pointer_polecenia]   ;inkrementacja aktualnej pozycji w tablicy polecenie
;Czynnoœci zwi¹zane z w³aœciwym ustawieniem kursora na ekranie:
  mov eax, 80
  mul byte [kursor + KURSOR.y]
  mov bl, [kursor+KURSOR.x]
  movzx bx, bl
  add ax, bx
  inc eax
  push eax
  mov bl, 80
  div bl
  mov [kursor+KURSOR.y], al
  mov [kursor+KURSOR.x], ah
  pop eax
  call USTAW_KURSOR_
  .koniec
RET

END
;Procedura ustawia kursor oraz akutaln¹ pozycjê w tablicy polecenie na koñcu
;wprowadzonego ci¹gu znaków.
  pusha
  mov ax, [dlugosc_polecenia]
  cmp ax, [pointer_polecenia]   ;gdy kursor znajduje siê na koñcu
  je .koniec
  sub ax, [pointer_polecenia]   ;obliczana jest iloœæ znaków oddzielaj¹ca aktualn¹ pozycjê od ostatniego znaku
  push eax
;Ustawienie kursora na ekranie:
  mov eax, 80
  mul byte [kursor + KURSOR.y]
  mov bl, [kursor+KURSOR.x]
  movzx bx, bl
  add ax, bx
  pop ebx
  add eax, ebx             ;do przesuniêcia kursora na ekranie dodawana jest wartoœæ okreœlaj¹ca ile pozycji dalej znajduje siê koniec polecenia
  push eax
  mov bl, 80
  div bl
  mov [kursor+KURSOR.y], al
  mov [kursor+KURSOR.x], ah
  pop eax
  call USTAW_KURSOR_
  mov ax, [dlugosc_polecenia]
  mov [pointer_polecenia], ax    ;ustwienie zmiennej pointer_polecenia na koniec polecenia
  .koniec
  popa
RET


INTERPRETACJA_KOMENDY
;Procedura okreœla komendê wydan¹ przez u¿ytkownika, znajduje jej argumenty
;oraz wywo³uje procedurê obs³ugi polecenia.
  pusha
  mov ax, es
  push eax
  mov ax, ds
  push eax
  mov ax, 24
  mov es, ax
  mov ds, ax
  mov edi, polecenie        ;zapis do EDI adresu tablicy polecenie
  cmp word [dlugosc_polecenia], 2   ;je¿eli polecenie nie jest d³u¿sze od dwóch znaków, oznacza to, ¿e nie ma argumentów
  ja .polecenie_ma_argumenty
;Je¿eli polecenie za posiada argumentów, to zerowane s¹ zmienne opisuj¹ce ich po³o¿enie w talicy polecenie
  mov dword [argument1 +ARGUMENT.POCZATEK], 0
  mov dword [argument1 +ARGUMENT.KONIEC], 0
  mov dword [argument2+ ARGUMENT.POCZATEK], 0
  mov dword [argument2+ ARGUMENT.KONIEC], 0
  call UZYSKAJ_POLECENIE       ;skopiowanie polecenia do tablicy komenda
  jmp .koniec
  .polecenie_ma_argumenty
  call SZUKAJ_CIAGU_ZNAKOW ;poszukiwanie pozycji znaku innego od spacji
  cmp edi, 0       ;gdy u¿ytkownik nic nie napisa³, nale¿y zakoñczyæ procedurê
  jne .jest_polecenie
;przygotowania do kolejnej interpretacji polecenia:
  mov byte [komenda],     0
  mov byte [komenda +1 ], 0
  mov byte [komenda+2],   0
  jmp .koniec
  .jest_polecenie
;gdy odnalezione ci¹g znaków ró¿nych od spacji, indeks jego pocz¹tku i koñca
;zachowywany jest w strukturze argumet1:
  mov  [argument1 +ARGUMENT.POCZATEK], edi
  call SZUKAJ_KONCA_CIAGU_ZNAKOW        ;szukanie koñca ci¹gu znaków
  mov  [argument1 +ARGUMENT.KONIEC], edi
  inc edi
  call SZUKAJ_CIAGU_ZNAKOW ;poszukiwanie kolejnego ci¹gu znaków
  cmp edi, 0
  jne .dalej
;Gdy odnaleziono tylko jeden ci¹g znaków, oznacza to, ¿e jest on komend¹
  mov edi, [argument1+ARGUMENT.POCZATEK]
  call UZYSKAJ_POLECENIE
  mov dword [argument1 +ARGUMENT.POCZATEK], 0
  mov dword [argument1 +ARGUMENT.KONIEC], 0
  mov dword [argument2 +ARGUMENT.POCZATEK], 0
  mov dword [argument2 +ARGUMENT.KONIEC], 0
  jmp .koniec
  .dalej
;ta czêœæ procedury wykona siê, gdy odnaleziono drugi ci¹g znaków oddzielony spacj¹:
  push edi
  call UZYSKAJ_POLECENIE        ;drugi ci¹g znaków jest komend¹ u¿ytkownika
  pop edi
  call SZUKAJ_KONCA_CIAGU_ZNAKOW
  inc edi
  call SZUKAJ_CIAGU_ZNAKOW ;poszukiwanie kolejnego ci¹gu znaków
  cmp edi, 0
  jne .jest_drugi_atrybut
;w przypadku gdy polecenie ma tylko jeden atrybut struktura argument2 jest zerowana:
  mov dword [argument2 +ARGUMENT.POCZATEK], 0
  mov dword [argument2 +ARGUMENT.KONIEC], 0
  jmp .koniec
  .jest_drugi_atrybut
;ta czêœæ procedury wykona siê w pzrypadku, gdy polecenie ma 2 argumenty
  mov  [argument2 +ARGUMENT.POCZATEK], edi
  call SZUKAJ_KONCA_CIAGU_ZNAKOW
  mov  [argument2 +ARGUMENT.KONIEC], edi
  .koniec
  call WYWOLAJ_WLASCIWE_DZIALANIE        ;procedura szuka i wywo³uje procedruê obs³ugi polecenia
  pop eax
  mov ds, ax
  pop eax
  mov es, ax
  popa
RET

WYWOLAJ_WLASCIWE_DZIALANIE
;Procedura szuka w tablicy poleceñ procedury obs³uguj¹cej komendê u¿ytkownika,
;a nastêpnie wywo³uje j¹.
  pusha
  mov ax, ds
  push eax
  mov ax, es
  push eax
  mov ax, 24
  mov ds, ax
  mov es, ax
  mov edi, polecenia   ;adres tablicy polecenia
  mov esi, komenda     ;adres ci¹gu znaków okreœlaj¹cego komendê
;Szukanie pozycji tablicy polecenia, która odpowiada wydanej przez u¿ytkownika komendzie:
  .szukanie_wlasciwej_komendy
    call SZUKAJ_KOMENDY   ;procedura porównuje 3 pierwsze bajty aktualnego wpisu w tablicy poleceñ z zawartoœci¹ tablicy komenda
    cmp eax, 0
    je .nie_znaleziono_jeszcze
    jmp .wyjscie
    .nie_znaleziono_jeszcze
    add edi, 7 ;adres kolejnego wpisu tabicy poleceñ
  jmp .szukanie_wlasciwej_komendy
  .wyjscie
  cmp eax, 1
  jne .nie_sa_rowne
  call ZNALEZIONO_WLASCIWE_POLECENIE         ;procedura wywo³ywana, gdy w tablicy komend znajduje siê odpowiednia pozycja
  jmp .koniec
  .nie_sa_rowne
  CALL WYKONAJ_POLECENIE_DOMYSLNE           ;procedura wywo³ywana, gdy w tablicy komend nie odnaleziono wprowadzonej przez u¿ytkownika komendy
  .koniec:
  pop eax
  mov es, ax
  pop eax
  mov ds, ax
  popa
RET

ZNALEZIONO_WLASCIWE_POLECENIE
;Procedura wywo³uje odpowiedni¹ procedurê obs³ugi komendy u¿ytkownika
;Parametry procedury:
;EDI - adres wpisu w tablicy poleceñ okreœlaj¹cy wydan¹ przez u¿ytkownika komendê.
  add edi, 3   ;3 bajty dalej znajduje siê adres procedury obs³ugi komendy
  call dword [es:edi] ;wywo³anie odpowidniej procedury
RET

WYKONAJ_POLECENIE_DOMYSLNE
;procedura pusta
RET

SZUKAJ_KOMENDY
;Procedura okreœla, czy nazwa polecenia w tablicy poleceñ zgadza siê z wydan¹ przez u¿ytkownika komend¹
;Parametry procedury:
;ES:EDI - adres wpisu w tablicy poleceñ
;DS:ESI - adres ci¹gu znaków komendy wpisanej przez u¿ytkownika
;Wyniki:
;EAX - 1 w³aœciwy wpis w tablicy poleceñ, 0 niezgody wpis w tablicy poleceñ, 2 nie ma ju¿ poleceñ
  push edi
  push esi
  push ecx
  mov al, [es:edi]
  cmp al, 0
  jne .jeszcze_sa_komendy
  mov eax, 2
  jmp .koniec
  .jeszcze_sa_komendy:
  mov ecx, 3
  mov eax, 1
  .petla_sprawdzania_wyrazow
    cmpsb
    je .na_razie_rowne
    mov eax, 0
    jmp .koniec
    .na_razie_rowne:
  loop .petla_sprawdzania_wyrazow
  .koniec
  pop ecx
  pop esi
  pop edi
RET

UZYSKAJ_POLECENIE
;Procedura kopiuje do tablicy komenda 3 bajty okreœlaj¹ce znaki komendy.
;Parametry procedury:
;DS:ESI - adres pocz¹tku komendy w tablicy polecenie
  PUSH EAX
  PUSH ECX
  PUSH ESI
  mov ecx, 3
  mov esi, komenda
;Wyzerowanie tablicy komenda
  .czyszczenie_komendy
    mov byte [ds:esi], 0
  loop .czyszczenie_komendy
  mov ecx, 3
  mov esi, komenda
  .uzyskanie_komendy
    mov al, [ds:edi]
    cmp al, 0         ;znalezienie bajtu zerowego koñczy pêtlê
    je .koniec
    cmp al, 32        ;znalezienie spacji koñczy pêtlê
    je .koniec
    mov [ds:esi], al
    inc esi
    inc edi
  loop .uzyskanie_komendy
  .koniec
  POP ESI
  POP ECX
  POP EAX
RET

SZUKAJ_CIAGU_ZNAKOW
;Procedura szuka pierwszego znaku ró¿nego od spacji.
;Parametry procedury:
;DS:EDI - adres ci¹gu znaków
;Wyniki:
;EDI - adres pierwszego odnalezionego znaku nie bêd¹cego spacj¹, 0 gdy
;nie odnaleziono znaku ró¿nego od spacji.
  push eax
  .petla_poszukiwania_znaku
    mov al, [ds:edi]
    cmp al, 0
    jne .nie_jest_zero
    xor edi, edi
    jmp .koniec
    .nie_jest_zero
    cmp al, 32
    je .znaleziona_spacja
    jmp .koniec
    .znaleziona_spacja
    inc edi
  jmp .petla_poszukiwania_znaku
  .koniec:
  pop eax
RET

SZUKAJ_KONCA_CIAGU_ZNAKOW
;Procedura szuka ostatniego znaku ci¹gu nie bêd¹cego spacj¹.
;Parametry procedury:
;DS:EDI - adres ci¹gu znaków.
;Wyniki:
;EDI - adres ostatniego znaku z ci¹gu, który nie jest spacj¹,
;AL - kod ASCII znaku.
  .petla_szukania
    mov al, [ds:edi]
    cmp al, 0
    jne .nie_zero
    dec edi
    jmp .koniec
    .nie_zero
    cmp al, 32
    jne .nie_spacja
    dec edi
    jmp .koniec
    .nie_spacja
    inc edi
  jmp .petla_szukania
  .koniec:
RET
