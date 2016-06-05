ZAREZERWOJ_STRONE
;Procedura szuka w binarnej mapie pamiêci wolnej ramki.
;Wyniki:
;EAX - adres zarezerwowanej ramki (0 gdy ca³a pamiêæ jest zajêta)
  push ebx
  mov ax, es
  push eax
  push ecx
  push edi
  mov ax, 8
  mov es, ax
  mov edi, 1024*1024
;Pêtla szuka pierwszego bajtu binarnej mapy pamiêci ró¿nego od wartoœci 0FFH:
  .petla_znajdowania_wolnej_przestrzeni:
    mov al, [es:edi]
    cmp al, 0ffh
    jne .koniec_petli_znajdowania_wolnej_przestrzeni
    inc edi
  jmp .petla_znajdowania_wolnej_przestrzeni
  .koniec_petli_znajdowania_wolnej_przestrzeni:
;Okreœlenie numeru bitu w odnalezionym bajcie:
  not al
  shl ax, 8
  xor ebx, ebx
  bsr bx, ax    ; binarne poszukiwanie w ty³
  mov cx, 16
  sub cx, bx   ;W CX zosta³a obliczona pozycja bitu
  btc ax, bx   ;prze³¹czenie wartoœci bitu
  clc
  xchg bx, cx
  not ah
  mov [es:edi], ah ;rezerwacja ramki
;Obliczenie adresu ramki:
  dec ebx
  mov eax, edi
  mov ecx, 1024*1024
  sub eax, ecx
  xor edx, edx
  mov ecx, 8
  mul ecx
  add eax, ebx
  mov ecx, 4096
  xor edx, edx
  mul ecx
;Sprawdzenie, czy adres ramki nie przekracza dostêpnego rozmiaru pamiêci:
  cmp eax, [calkowita_wielkosc_pamieci_w_B]
  jb .dalej
    xor eax, eax
  .dalej:
  pop edi
  pop ecx
  pop ebx
  mov es, bx
  pop ebx
RET

ZWOLNIJ_STRONE
;Parametry procedury:
;EAX - adres fizyczny ramki
  mov bx, es
  push ebx
  pusha
;Obliczenie indeksu ramki w pamiêci:
  mov ebx, 4096
  xor edx, edx
  div ebx
;Obliczenie adresu bajtu w binarnej mapie pamiêci, przechowuj¹cego informacjê
;o ramce:
  xor edx, edx
  mov ebx, 8
  div ebx
  INC EDX
  mov bx, 8
  mov es, bx
  mov edi, 1024*1024       ; adres binarnej mapy pamiêci
  add edi, eax
  mov al, [es:edi]
;Zwolnienie ramki:
  mov cx, 8
  sub cl, dl
  btr ax, cx
  mov [es:edi], al
  popa
  pop ebx
  mov es, bx
RET


SZUKAJ_PIERWSZEJ_WOLNEJ_POZYCJI_W_ELEMENTACH_STRONICOWANIA
;Procedura odszukuje pierwsz¹ woln¹ pozycjê w katalogu stron lub tablicy stron
;Parametry procedury:
;ES:EDI - adres katalogu lub tablicy stron
;Wyniki:
;AX - indeks odnalezionej pozycji (0FFFFH gdy nie odnaleziono wolnej pozycji)
;ES:EDI - adres odnalezionej pozycji
  mov ecx, 1024
  xor ax, ax
  .petla:
    mov ebx, [es:edi]
    cmp ebx, 0
    je .koniec_petli
    add edi, 4
    inc ax
  loop .petla
  mov ax, 0ffffh
  .koniec_petli:
RET

NORMALIZACJA_ADRESU_TABLICY
;Procedura tworzy dostêp do tablicy lub katalogu stron (tablica stron lub
;katalog stron mo¿e znajdowaæ siê poza przestrzeni¹ adresow¹ utworzon¹ przez
;stronicowanie).
;Parametry procedury:
;EDI - adres fizyczny
;Wyniki:
;Adres 1000h bêdzie wskazywa³ na adres fizyczny przekazany procedurze w parametrze.
push esi
push eax
  mov ax, es
  push eax
  ;Opró¿nienie pamiêci cache:
  mov eax, cr3
  mov cr3, eax
;Zapis do drugiego PTE zerowej tablicy stron adresu fizycznego przekazanego
;procedurze w parametrze:
  mov ax, 8
  mov es, ax       ;zapis do ES selektora segmentu adresu liniowego
  mov esi,55000h   ;adres zerowej tablicy stron
  add esi, 4       ;adres drugiego PTE zerowej tabliy stron.
  mov eax, edi
  and eax, 0fffh
  and edi, 0fffff000h
  or edi, 11b
  mov [es:esi],edi
  mov edi, 1000h
  or edi, eax
  pop eax
  mov es, ax
pop eax
pop esi
RET

OGOLNA_NORMALIZACJA_ADRESU
  CALL NORMALIZACJA_ADRESU_TABLICY
RET

SZUKAJ_N_PIERWSZYCH_WOLNYCH_PTE ; wersja dla supervisor
;Procedura szuka okreœlonej gruy wolnych wpisów PTE znajduj¹cych siê
;przy sobie.
;Parametry procedury:
;ES - selektor adresu liniowego,
;EDI - adres katalogu stron,
;AX - iloœæ PTE.
;Wyniki:
;ES:EDI - adres pierwszego wolnego PTE z odnalezionej grupy,
;AX - 0 gdy nie odnaleziono dostatecznie du¿ej grupy wolnych PTE.
  mov dx, ax
;Poszukiwanie tablic stron nale¿¹cych do poziomu supervisor:
  mov ecx, 1024
  .petla1:
    mov ax, dx
    mov esi, [es:edi]
    cmp esi, 0
    jne .jest_tablica_stron
    mov ax, dx
    jmp .nie_ma_tablicy_stron
    .jest_tablica_stron:
    test esi, 100b        ;Sprawdzenie czy tablica stron nale¿y do poziomu supervisor
    jz .jest_przestrzen_adresowa_dla_supervisora
    xor ax, ax
    jmp .koniec_petel
    .jest_przestrzen_adresowa_dla_supervisora:
    and esi, 11111111111111111111000000000000b          ;Uzyskanie adresu fizycznego tablicy stron
    push edi
    mov edi, esi
    call NORMALIZACJA_ADRESU_TABLICY                    ;Utworzenie dostêpu do pamiêci zajmowanej przez odnalezion¹ tablicê stron
    mov esi, edi
    pop edi
;Przeszukiwanie PTE wewn¹trz odnalezionej tablicy stron:
    push ecx
    mov ecx, 1024
    .petla2:
      mov ebx, [es:esi]
      cmp ebx, 0  ;Je¿eli wartoœæ PTE wynosi 0, oznacza to, ¿e wpis jest wolny
      je .znaleziono_jeden_wolny_pte
      mov ax, dx  ;Gdy odnaleziono zajêty PTE, nale¿y przywróciæ licznik iloœci PTE koniecznych do odnalezienia.
      jmp .dalej
      .znaleziono_jeden_wolny_pte:
      dec ax     ;Zmniejszenie wartoœci licznika iloœci PTE koniecznych do odnalezienia.
      cmp ax, 0
      jne .dalej2
      mov ax, 1
      pop ecx
      jmp .koniec_petel
      .dalej2:
      .dalej:
      add esi, 4
    loop .petla2
    pop ecx
    .nie_ma_tablicy_stron:
    add edi, 4
  loop .petla1
  mov ax, 0
  .koniec_petel:
  cmp ax, 0
  je .koniec_procedury
  xor eax, eax
  mov ax, dx
  dec ax
  shl eax, 2   ;mno¿enie przez 4
  sub esi, eax
  xchg edi, esi
  mov ax, 3
  .koniec_procedury:
RET


SZUKAJ_N_OSTATNICH_WOLNYCH_PTE ; wersja dla user
;Procedura szuka okreœlonej gruy wolnych wpisów PTE znajduj¹cych siê
;przy sobie.
;Parametry procedury:
;ES - selektor adresu liniowego,
;EDI - adres katalogu stron,
;AX - iloœæ PTE.
;Wyniki:
;ES:EDI - adres pierwszego wolnego PTE z odnalezionej grupy,
;AX - 0 gdy nie odnaleziono dostatecznie du¿ej grupy wolnych PTE.
  mov dx, ax
;Strony dla poziomu user znajduj¹ pocz¹wszy od koñca przestrzeni adresowej,
;poszukiwania nale¿y wiêc rozpocz¹æ od ostatniej tablicy stron.
  add edi, 1023 * 4      ;Obliczenie adresu ostatniego PDE
;Poszukiwanie tablic stron nale¿¹cych do poziomu user:
  mov ecx, 1024
  .petla1:
    mov esi, [es:edi]
    cmp esi, 0
    jne .jest_tablica_stron
    mov ax, dx
    jmp .nie_ma_tablicy_stron
    .jest_tablica_stron:
    test esi, 100b        ;Sprawdzenie czy tablica stron nale¿y do poziomu user
    jnz .jest_przestrzen_adresowa_dla_usera
    xor ax, ax
    jmp .koniec_petel
    .jest_przestrzen_adresowa_dla_usera:
    and esi, 11111111111111111111000000000000b          ;Uzyskanie adresu fizycznego tablicy stron
    push edi
    mov edi, esi
    call NORMALIZACJA_ADRESU_TABLICY                    ;Utworzenie dostêpu do pamiêci zajmowanej przez odnalezion¹ tablicê stron
    mov esi, edi
    pop edi
    add esi, 1023*4                                     ;Adres ostatniego PTE tablicy stron (poszukiwania od koñca tablicy)
;Przeszukiwanie PTE wewn¹trz odnalezionej tablicy stron:
    push ecx
    mov ecx, 1024
    .petla2:
      mov ebx, [es:esi]
      cmp ebx, 0        ;Je¿eli wartoœæ PTE wynosi 0, oznacza to, ¿e wpis jest wolny
      je .znaleziono_jeden_wolny_pte
      mov ax, dx        ;Gdy odnaleziono zajêty PTE, nale¿y przywróciæ licznik iloœci PTE koniecznych do odnalezienia.
      jmp .dalej
      .znaleziono_jeden_wolny_pte:
      dec ax            ;Zmniejszenie wartoœci licznika iloœci PTE koniecznych do odnalezienia.
      cmp ax, 0
      jne .dalej2
      mov ax, 1
      pop ecx
      jmp .koniec_petel
      .dalej2:
      .dalej:
      sub esi, 4
    loop .petla2
    pop ecx
    .nie_ma_tablicy_stron:
    sub edi, 4
  loop .petla1
  mov ax, 0
  .koniec_petel:
  cmp ax, 0
  je .koniec_procedury
  xchg edi, esi
  mov ax, 3
  .koniec_procedury:
RET



SZUKAJ_N_PIERWSZYCH_WOLNYCH_PDE
;Procedura poszukuje grupy wolnych PDE, poszukiwania rozpoczyna od pocz¹ktu
;katalogu stron.
;Parametry procedury:
;ES - selektor segmentu adresu liniowego,
;EDI - adres katalogu stron,
;AX - iloœæ potrzebnych PDE
;Wyniki:
;ES:EDI - adres pierwszego z grupy wolnych wpisów PDE,
;AX - 0 gdy nie odnaleziono wymaganej grupy wolnych PDE.
  mov dx, ax
;Przeszukiwanie pozycji katalogu stron:
  mov ecx, 1024
  .petla:
    mov ebx, [es:edi]
    cmp ebx, 0
    je .znaleziono_jeden_wolny_pde
    mov ax, dx ;Gdy odnaleziono zajêty PDE, nale¿y przywróciæ licznik iloœci PDE koniecznych do odnalezienia.
    jmp .dalej
    .znaleziono_jeden_wolny_pde:
    dec ax
    cmp ax, 0
    jne .dalej2
    mov ax, 1
    jmp .koniec_peteli
    .dalej2:
    .dalej:
    add edi, 4
  loop .petla
  mov ax, 0
  .koniec_peteli:
  cmp ax, 0
  je .koniec_procedury
  xor eax, eax
  mov ax, dx
  dec ax
  shl eax, 2
  sub edi, eax
  mov ax, 3
  .koniec_procedury:
RET

SZUKAJ_N_OSTATNICH_WOLNYCH_PDE
;Procedura poszukuje grupy wolnych PDE, poszukiwania rozpoczyna od koñca katalogu stron
;katalogu stron.
;Parametry procedury:
;ES - selektor segmentu adresu liniowego,
;EDI - adres katalogu stron,
;AX - iloœæ potrzebnych PDE
;Wyniki:
;ES:EDI - adres pierwszego z grupy wolnych wpisów PDE,
;AX - 0 gdy nie odnaleziono wymaganej grupy wolnych PDE.
  mov dx, ax
  add edi, 1023*4     ;Obliczenie adresu ostatniego PDE w katalogu stron
; petla skacze po elementach katalogu stron
  mov ecx, 1024
  .petla:
    mov ebx, [es:edi]
    cmp ebx, 0
    je .znaleziono_jeden_wolny_pde
    mov ax, dx ;Gdy odnaleziono zajêty PDE, nale¿y przywróciæ licznik iloœci PDE koniecznych do odnalezienia.
    jmp .dalej
    .znaleziono_jeden_wolny_pde:
    dec ax
    cmp ax, 0
    jne .dalej2
    mov ax, 1
    jmp .koniec_peteli
    .dalej2:
    .dalej:
    sub edi, 4
  loop .petla
  mov ax, 0
  .koniec_peteli:
  cmp ax, 0
  je .koniec_procedury
  mov ax, 3
  .koniec_procedury:
RET


ZAMIEN_ADRES_LINIOWY_NA_FIZYCZNY
;Procedura na podstawie podanego adresu, nale¿¹cego do przestrzeni adresowej
;wyznaczonej przez stronicowanie, oblicza adres fizyczny.
;Parametry procedury:
;EBX - adres do zamiany,
;ES:EDI - adres katalogu stron.
;Wyniki:
;EDI - adres fizyczny.
push eax
push ebx
push ecx
push edx
push esi
;Wyznaczenie adresu tablicy stron:
  mov ecx, ebx
  and ebx, 11111111110000000000000000000000b ;indeks PDE
  shr ebx, 22
  shl ebx, 2
  add edi, ebx
  mov eax, [es:edi]
  and eax, 0FFFFF000h
  mov ebx, ecx
;Wyznaczenie adresu fizycznego:
  and ebx, 00000000001111111111000000000000b ;indeks PTE
  shr ebx, 12
  shl ebx, 2
  add eax, ebx
  mov edi, eax
  call NORMALIZACJA_ADRESU_TABLICY     ;utworzenie dostêpu do tablicy stron
  mov eax, [es:edi]
  and eax, 0fffff000h
  mov edi, eax
  and ecx, 0fffh
  or edi, ecx
pop esi
pop edx
pop ecx
pop ebx
pop eax
RET

TWORZ_PDE  ;dla poziomu supervisor
;Procedura tworzy nowy wpis katalogu stron
;Parametry procedury:
;ES:EDI - adres, pod który nale¿y od³o¿yæ wpis PDE,
;EAX - adres ramki, w której bêdzie przechowywana tablica stron
  push ebx
  xor ebx, ebx
;Ustalenie atrybutów PDE:
  mov bl, 00000011b   ; PS, 0, A, PCD, PWT, U/S, R/W, P
  mov bh, 0000b       ; AV, G
  push edi
  mov edi, eax
  call ZERUJ_TABLICE_STRON
  pop edi
  or ebx, eax
;Od³o¿enie PDE pod wskazany adres:
  mov [es:edi], ebx
  pop ebx
RET

TWORZ_PDE_USER   ;dla poziomu user
;Procedura tworzy nowy wpis katalogu stron
;Parametry procedury:
;ES:EDI - adres, pod który nale¿y od³o¿yæ wpis PDE,
;EAX - adres ramki, w której bêdzie przechowywana tablica stron
  push ebx
  xor ebx, ebx
;Ustalenie atrybutów PDE:
  mov bl, 00000111b   ; PS, 0, A, PCD, PWT, U/S, R/W, P
  mov bh, 0000b       ; AV, G
  push edi
  mov edi, eax
  call ZERUJ_TABLICE_STRON
  pop edi
  or ebx, eax
;Od³o¿enie PDE pod wskazany adres:
  mov [es:edi], ebx
  pop ebx
RET

TWORZ_PTE   ;dla poziomu supervisor
;Procedura tworzy nowy wpis tablicy stron
;Parametry procedury:
;ES:EDI - adres, pod który nale¿y od³o¿yæ wpis PTE,
;EAX - adres ramki, w której bêdzie przechowywana strona
  push ebx
  xor ebx, ebx
;Ustalenie atrybutów PTE:
  mov bl, 00000011b   ; 0, D, A, PCD, PWT, U/S, R/W, P
  mov bh, 0000b       ; AV, G
  or ebx, eax
  mov [es:edi], ebx
  pop ebx
RET


TWORZ_PTE_USER  ;dla poziomu user
;Procedura tworzy nowy wpis tablicy stron
;Parametry procedury:
;ES:EDI - adres, pod który nale¿y od³o¿yæ wpis PTE,
;EAX - adres ramki, w której bêdzie przechowywana strona
  push ebx
  xor ebx, ebx
  mov bl, 00000111b   ; 0, D, A, PCD, PWT, U/S, R/W, P
  mov bh, 0000b       ; AV, G
  or ebx, eax
  mov [es:edi], ebx
  pop ebx
RET

TWORZ_N_PDE  ;dla poziomu supervisor
;Procedura tworzy grupê PDE s¹siaduj¹cych ze sob¹.
;Parametry procedury:
;ES - selektor segmentu adresu liniowego,
;EDI - adres pierwszego wpisu PDE,
;AX - iloœæ wpisów.
  push edi
  push ecx
  movzx ecx, ax
  jcxz .koniec_petli
  .petla
    call ZAREZERWOJ_STRONE
    cmp eax, 0
    jne .dalej
    jmp .koniec_petli
    .dalej
    call TWORZ_PDE
    add edi, 4
  loop .petla
  .koniec_petli:
  pop ecx
  pop edi
RET



TWORZ_N_PDE_USER  ;dla poziomu user
;Procedura tworzy grupê PDE s¹siaduj¹cych ze sob¹.
;Parametry procedury:
;ES - selektor segmentu adresu liniowego,
;EDI - adres pierwszego wpisu PDE,
;AX - iloœæ wpisów.
  push edi
  push ecx
  movzx ecx, ax
  jcxz .koniec_petli
  .petla
    call ZAREZERWOJ_STRONE
    cmp eax, 0
    jne .dalej
    jmp .koniec_petli
    .dalej
    call TWORZ_PDE_USER
    add edi, 4
  loop .petla
  .koniec_petli:
  pop ecx
  pop edi
RET

TWORZ_N_PTE    ;dla poziomu supervisor
;procedura tworzy grupê PTE s¹siaduj¹cych ze sob¹.
;Parametry procedury:
;ES - selektor segmentu adresu liniowego,
;EDI - adres do zapisu pierwszego PTE,
;AX - iloœæ PTE.
  push edi
  push ebx
  push ecx
  call NORMALIZACJA_ADRESU_TABLICY
  movzx ecx, ax
  jcxz .koniec_petli
  .petla
    call ZAREZERWOJ_STRONE
    cmp eax, 0
    jne .dalej
    jmp .koniec_petli
    .dalej
    call TWORZ_PTE
    add edi, 4
   loop .petla
   mov ax, 3
  .koniec_petli:
  pop ecx
  pop ebx
  pop edi
RET

TWORZ_N_PTE_USER     ;dla poziomu user
;procedura tworzy grupê PTE s¹siaduj¹cych ze sob¹.
;Parametry procedury:
;ES - selektor segmentu adresu liniowego,
;EDI - adres do zapisu pierwszego PTE,
;AX - iloœæ PTE.
  push edi
  push ebx
  push ecx
  call NORMALIZACJA_ADRESU_TABLICY
  movzx ecx, ax
  jcxz .koniec_petli
  .petla
    call ZAREZERWOJ_STRONE
    cmp eax, 0
    jne .dalej
    jmp .koniec_petli
    .dalej
    call TWORZ_PTE_USER
    add edi, 4
  loop .petla
  mov ax, 3
  .koniec_petli:
  pop ecx
  pop ebx
  pop edi
RET

WYPELNIJ_CIAG_TABLIC_STRON    ;poziom supervisor
;Procedura tworzy okreœlon¹ liczbê stron.
;Parametry procedury:
;ES:ESI - adres PDE, pocz¹wszy od którego bêd¹ tworzone tablice stron,
;AX - liczba stron.
  push ebx
  push ecx
  push edx
  push edi
  push esi
  xor ecx, ecx
  and eax, 0ffffh
  xor edx, edx
  mov ebx, 1024
  div ebx  ;obliczenie liczby pe³nych tablic stron
  mov cx, ax
  jcxz .mniej_stron
  push edx
  .petla:
    push ecx
    mov edi, [es:esi]
    and edi, 0fffff000h     ;Wyznaczenie adresu tablicy stron
;Wype³nienie ca³ej tablicy stron:
    mov eax, 1024
    push esi
    call TWORZ_N_PTE
    pop esi
    add esi,4              ;Adres kolejnego wpisu PDE
    pop ecx
  loop .petla
  pop edx
  .mniej_stron:
  mov edi, [es:esi]
  and edi, 0fffff000h     ;Wyznaczenie adresu tablicy stron
;Wype³nienie czêœci tablicy stron:
  mov ax, dx
  call TWORZ_N_PTE
  pop esi
  pop edi
  pop edx
  pop ecx
  pop ebx
RET


WYPELNIJ_CIAG_TABLIC_STRON_USER   ;poziom user
;Procedura tworzy okreœlon¹ liczbê stron.
;Parametry procedury:
;ES:ESI - adres PDE, pocz¹wszy od którego bêd¹ tworzone tablice stron,
;AX - liczba stron.
  push ebx
  push ecx
  push edx
  push edi
  push esi
  xor ecx, ecx
  and eax, 0ffffh
  xor edx, edx
  mov ebx, 1024
  div ebx     ;obliczenie liczby pe³nych tablic stron
  mov cx, ax
  jcxz .mniej_stron
  push edx
  .petla:
    push ecx
    mov edi, [es:esi]
    and edi, 0fffff000h   ;Wyznaczenie adresu tablicy stron
;Wype³nienie ca³ej tablicy stron:
    mov eax, 1024
    push esi
    call TWORZ_N_PTE_USER
    pop esi
    add esi,4      ;Adres kolejnego wpisu PDE
    pop ecx
  loop .petla
  pop edx
  .mniej_stron:
  mov edi, [es:esi]
  and edi, 0fffff000h   ;Wyznaczenie adresu tablicy stron
;Wype³nienie czêœci tablicy stron:
  mov ax, dx
  call TWORZ_N_PTE_USER
  pop esi
  pop edi
  pop edx
  pop ecx
  pop ebx
RET

DODAJ_N_STRON  ;poziom supervisor
;Procedura dodaje okreœlon¹ liczbê stron, pocz¹wszy od okreœlonego miejsca
;w tablicy stron (procedura zak³ada, ¿e pocz¹wszy od podanego indeksu reszta
;wpisów w tablicy jest pusta).
;Parametry procedury:
;ES - selektor segmentu adresu liniowego,
;ESI - adres PDE tablicy stron, w której zostan¹ dodane pierwsze wpisy,
;CX - liczba stron do dodania,
;BX - indeks PTE w tablicy stron, pocz¹wszy od którego zostan¹ dodane strony.
  cmp bx, 1024
  jae .przejdz_do_tworzenia_pde
  mov ax, 1024
  sub ax, bx              ;obliczenie liczby wolnych wpisów PTE w tablicy stron
  mov edi, [es:esi]
  and edi, 0fffff000h     ;Obliczenie adresu tablicy stron.
  movzx ebx, bx
;Obliczenie adresu pierwszego wpisu PTE, od którego nast¹pi dodawanie stron:
  shl ebx, 2
  add edi, ebx
  shr ebx, 2
  cmp cx, ax
  jb .zmiesci_sie
;W przypadku niedostatecznej liczby pustych wpisów PTE we wskazanej tablicy stron,
;nastêpuje utworzenie nowej:
  sub cx, ax ;odjêcie od ca³kowitej liczby PTE do dodania tych, które zmieszcz¹ siê we wskazanej tablicy
  push ecx
  call TWORZ_N_PTE       ;tworzenie stron we wskazanej tablicy stron
  pop ecx
  add esi, 4
  .przejdz_do_tworzenia_pde:
  xor edx, edx
  xor eax, eax
  mov ax, cx         ;w CX znajduje siê liczba stron do dodania
;Okreœlenie liczby niezbêdnych tablic stron do dodania:
  mov ebx, 1024
  div ebx
  cmp edx, 0
  je .dalej
  inc ax
  .dalej:
  push eax
  push ecx
  mov edi, esi
  call TWORZ_N_PDE
  pop ecx
  pop eax
;Wype³nie utworzonych tablic stron nowymi pozycjami:
  mov ax, cx
  mov esi, edi
  call WYPELNIJ_CIAG_TABLIC_STRON
  jmp .koniec
  .zmiesci_sie:
  mov ax, cx
  call TWORZ_N_PTE
  .koniec:
RET

DODAJ_N_STRON_USER   ;poziom user
;Procedura dodaje okreœlon¹ liczbê stron, pocz¹wszy od okreœlonego miejsca
;w tablicy stron (procedura zak³ada, ¿e pocz¹wszy od podanego indeksu reszta
;wpisów w tablicy jest pusta).
;Parametry procedury:
;ES - selektor segmentu adresu liniowego,
;ESI - adres PDE tablicy stron, w której zostan¹ dodane pierwsze wpisy,
;CX - liczba stron do dodania,
;BX - indeks PTE w tablicy stron, pocz¹wszy od którego zostan¹ dodane strony.
  cmp bx, 1024
  jae .przejdz_do_tworzenia_pde
  mov ax, 1024
  sub ax, bx      ;obliczenie liczby wolnych wpisów PTE w tablicy stron
  mov edi, [es:esi]
  and edi, 0fffff000h  ;Obliczenie adresu tablicy stron.
  movzx ebx, bx
;Obliczenie adresu pierwszego wpisu PTE, od którego nast¹pi dodawanie stron:
  shl ebx, 2
  add edi, ebx
  shr ebx, 2
  cmp cx, ax
  jb .zmiesci_sie
;W przypadku niedostatecznej liczby pustych wpisów PTE we wskazanej tablicy stron,
;nastêpuje utworzenie nowej:
  sub cx, ax
  push ecx
  call TWORZ_N_PTE_USER   ;tworzenie stron we wskazanej tablicy stron
  pop ecx
  add esi, 4
  .przejdz_do_tworzenia_pde:
  xor edx, edx
  xor eax, eax
  mov ax, cx             ;w CX znajduje siê liczba stron do dodania
;Okreœlenie liczby niezbêdnych tablic stron do dodania:
  mov ebx, 1024
  div ebx
  cmp edx, 0
  je .dalej
  inc ax
  .dalej:
  push eax
  push ecx
  mov edi, esi
  call TWORZ_N_PDE_USER
  pop ecx
  pop eax
;Wype³nie utworzonych tablic stron nowymi pozycjami:
  mov ax, cx
  mov esi, edi
  call WYPELNIJ_CIAG_TABLIC_STRON_USER
  jmp .koniec
  .zmiesci_sie:
  mov ax, cx
  call TWORZ_N_PTE_USER
  .koniec:
RET



OBLICZANIE_ADRESU_LINIOWEGO
;Parametry procedury:
;EDI - adres PTE,
;ESI - adres PDE.
;Wyniki:
;EBX - adres liniowy
  push esi
  push edi
  and esi, 111111111100b
  shl esi, 20
  and edi, 111111111100b
  shl edi, 10
  or esi, edi
  mov ebx, esi
  pop edi
  pop esi
RET

SZUKAJ_PRZESTRZENI_DLA_N_NOWYCH_STRON ; poziom supervisor
;Procedura ma za zadanie znaleŸæ miejsce dla dodawanych stron.
;Parametry procedury:
;ES - selektor segmentu adresu liniowego,
;EDI - adres katalogu stron,
;AX - liczba stron do dodania.
;Wyniki:
;ESI - adres PDE,
;EDI - adres PTE,
;EBX - adres liniowy,
;EAX - kod zakoñczenia procedury:
;0 - nie mo¿na dodaæ tylu stron,
;1 - w istniej¹cej tablicy stron zmieœci siê ¿¹dana iloœæ nowych stron,
;2 - nale¿y stworzyæ now¹ tablicê stron.
  push edi
  push eax
  cmp ax, 1023
  ja .nie_miesci_sie_w_tablicy_stron
;Poszukiwanie wymaganej liczby wolnych wpisów PTE:
  CALL SZUKAJ_N_PIERWSZYCH_WOLNYCH_PTE
  cmp ax, 0
  je .nie_miesci_sie_w_tablicy_stron
  call OBLICZANIE_ADRESU_LINIOWEGO
  pop eax
  pop eax
  mov eax, 1
  jmp .koniec_procedury
  .nie_miesci_sie_w_tablicy_stron:
  pop eax ;liczba stron
  pop edi ;adres katalogu stron
;Obliczanie liczby koniecznych do stworzenia tablic stron:
  xor edx, edx
  mov ecx, 1024
  div ecx
  mov ebx, eax
  cmp edx, 0
  je .nie_ma_reszty
  inc ebx
  xchg ebx, eax ;
  .nie_ma_reszty:
  call SZUKAJ_N_PIERWSZYCH_WOLNYCH_PDE
  cmp ax, 0        ;wartoœæ 0 w rejestrze AX oznacza, ¿e wolnych PDE jest za ma³o
  je .koniec_procedury
  xor esi, esi
  xchg edi, esi
  call  OBLICZANIE_ADRESU_LINIOWEGO
  mov eax, 2
  .koniec_procedury:
RET


SZUKAJ_PRZESTRZENI_DLA_N_NOWYCH_STRON_USER ; poziom supervisor
;Procedura ma za zadanie znaleŸæ miejsce dla dodawanych stron.
;Parametry procedury:
;ES - selektor segmentu adresu liniowego,
;EDI - adres katalogu stron,
;AX - liczba stron do dodania.
;Wyniki:
;ESI - adres PDE,
;EDI - adres PTE,
;EBX - adres liniowy,
;EAX - kod zakoñczenia procedury:
;0 - nie mo¿na dodaæ tylu stron,
;1 - w istniej¹cej tablicy stron zmieœci siê ¿¹dana iloœæ nowych stron,
;2 - nale¿y stworzyæ now¹ tablicê stron.
  push edi
  push eax
  cmp ax, 1023
  ja .nie_miesci_sie_w_tablicy_stron
;Poszukiwanie wymaganej liczby wolnych wpisów PTE:
  CALL SZUKAJ_N_OSTATNICH_WOLNYCH_PTE
  cmp ax, 0
  je .nie_miesci_sie_w_tablicy_stron
  call OBLICZANIE_ADRESU_LINIOWEGO
  pop eax
  pop eax
  mov eax, 1
  jmp .koniec_procedury
  .nie_miesci_sie_w_tablicy_stron:
  pop eax  ;liczba stron
  pop edi  ;adres katalogu stron
;Obliczanie liczby koniecznych do stworzenia tablic stron:
  xor edx, edx
  mov ecx, 1024
  div ecx
  mov ebx, eax
  cmp edx, 0
  je .nie_ma_reszty
  inc ebx
  xchg ebx, eax
  .nie_ma_reszty:
  call SZUKAJ_N_OSTATNICH_WOLNYCH_PDE
  cmp ax, 0      ;wartoœæ 0 w rejestrze AX oznacza, ¿e wolnych PDE jest za ma³o
  je .koniec_procedury
  xor esi, esi
  xchg edi, esi
  call  OBLICZANIE_ADRESU_LINIOWEGO
  mov eax, 2
  .koniec_procedury:
RET



DODAJ_N_STRON_DO_PRZESTRZENI_ADRESOWEJ ;poziom supervisor
;Procedura tworzy grupê nowych stron.
;Parametry procedury:
;ES:EDI - adres katalogu stron,
;EAX - liczba stron do dodania,
;Wyniki:
;ES:EDI - adres fizyczny pocz¹tku bloku stron.
;EBX - adres utworzonego ci¹gu pamiêci.
  push eax
  call SZUKAJ_PRZESTRZENI_DLA_N_NOWYCH_STRON
  cmp ax, 0
  jne .wystarcza_pamieci
;Zakoñczenie procedury (nie mo¿na dodaæ ¿¹danej iloœci stron):
  mov edi, 0
  mov ebx, 0
  jmp .koniec_procedury
  .wystarcza_pamieci
  pop ecx    ;liczba stron do dodania
  push ebx
  cmp ax, 1   ;Je¿eli AX == 1, znaleziona przestrzeñ w tablicy stron
              ; jest wystarczaj¹ca i nie trzeba dodawaæ ¿adnego PDE.
  je .bez_dodawania_pde
  mov ebx, 2000        ;parametr dla procedury DODAJ_N_STRON
  call DODAJ_N_STRON
  cmp eax, 0
  jne .jest_na_tyle_pamieci
  mov edi, 0
  .jest_na_tyle_pamieci
  jmp .koniec_procedury
  .bez_dodawania_pde:
;Obliczanie adresu pierwszego wolnego wpisu PTE w tablicy stron:
  mov ebx, edi
  and ebx, 0fffh
  shr ebx, 2
  call DODAJ_N_STRON
  cmp eax, 0
  jne .jest_na_tyle_pamieci2
  mov edi, 0
  .jest_na_tyle_pamieci2
  .koniec_procedury:
  pop ebx
RET


DODAJ_N_STRON_DO_PRZESTRZENI_ADRESOWEJ_USER ; poziom user
;Procedura tworzy grupê nowych stron.
;Parametry procedury:
;ES:EDI - adres katalogu stron,
;EAX - liczba stron do dodania,
;Wyniki:
;ES:EDI - pocz¹tek adresu fizyczny pocz¹tku bloku stron.
;EBX - adres utworzonego ci¹gu pamiêci.
  push eax
  call SZUKAJ_PRZESTRZENI_DLA_N_NOWYCH_STRON_USER
  cmp ax, 0
  jne .wystarcza_pamieci
;Zakoñczenie procedury (nie mo¿na dodaæ ¿¹danej iloœci stron):
  mov edi, 0
  mov ebx, 0
  jmp .koniec_procedury
  .wystarcza_pamieci   ;liczba stron do dodania
  pop ecx
  push ebx
  cmp ax, 1      ;Je¿eli AX == 1, znaleziona przestrzeñ w tablicy stron
                 ; jest wystarczaj¹ca i nie trzeba dodawaæ ¿adnego PDE.
  je .bez_dodawania_pde
  mov ebx, 2000   ;parametr dla procedury DODAJ_N_STRON
  call DODAJ_N_STRON_USER
  cmp eax, 0
  jne .jest_na_tyle_pamieci
  mov edi, 0
  .jest_na_tyle_pamieci
  jmp .koniec_procedury
  .bez_dodawania_pde:
;Obliczanie adresu pierwszego wolnego wpisu PTE w tablicy stron:
  mov ebx, edi
  and ebx, 0fffh
  shr ebx, 2
  call DODAJ_N_STRON_USER
  cmp eax, 0
  jne .jest_na_tyle_pamieci2
  mov edi, 0
  .jest_na_tyle_pamieci2
   .koniec_procedury:
  pop ebx
RET


SPRAWDZ_CZY_TABELA_STRON_JEST_PUSTA
;Procedura okreœla czy tablica stron jest pusta.
;Parametry procedury:
;ES:ESI - adres tablicy stron,
;Wyniki:
;AX - 0 dla pustej tablicy stron, inna wartoœæ gdy tablica stron nie jest pusta.
  push edi
  push ecx
  push ebx
  mov ax, 0
  mov ecx, 1024
  .petla
    mov ebx, [es:esi]
    cmp ebx, 0
    je .dalej
    mov ax, 1
    jmp .koniec_petli
    .dalej:
    add esi, 4
  loop .petla
  .koniec_petli
  pop ebx
  pop ecx
  pop edi
RET

USUN_STRONE
;Procedura usuwa stronê z przestrzeni adresowej. Usuwa równie¿ tablicê stron, w
;przypadku, gdy usuniêcie strony spowoduje ca³kowite opró¿nienie tablicy stron.
;Parametry procedury:
;EBX - adres strony,
;ES:EDI - adres katalogu stron,
  pusha
  mov eax, edi
  mov ecx, ebx
  call ZAMIEN_ADRES_LINIOWY_NA_FIZYCZNY
  push edi
  mov edi, eax
  mov ebx, ecx
  mov eax, 11111111110000000000000000000000b
  and eax, ebx
  shr eax, 22 ;Obliczenie indeksu PDE
  shl eax, 2  ;offset w katalogu stron
  mov ecx, 00000000001111111111000000000000b
  and ecx, ebx
  shr ecx, 12 ;Obliczenie indeksu PTE
  shl ecx, 2 ;offset w tablicy stron
  add edi, eax   ;Obliczenie adresu PDE
  push edi
  mov edi, [es:edi]
  and edi, 0fffff000h ;Obliczenie adresu fizycznego tablicy stron
  push edi
  mov edx, edi
  call NORMALIZACJA_ADRESU_TABLICY   ;Utworzenie dostêpu do tablicy stron.
  add edi, ecx
  mov dword [es:edi], 0  ;Wykasowanie PTE strony.
  pop edi
  call NORMALIZACJA_ADRESU_TABLICY
  mov esi, edi
;Sprawdzenie, czy usuniêcie strony nie opró¿ni³o ca³ej tablicy:
  call SPRAWDZ_CZY_TABELA_STRON_JEST_PUSTA
;W przypadku pustej tablicy stron usuwany jest wpis PDE j¹ opisuj¹cy:
  pop edi    ;adres PDE
  cmp ax, 0  ;wynik procedury SPRAWDZ_CZY_TABELA_STRON_JEST_PUSTA
  jne .dalej
  mov dword [es:edi], 0   ;Wykasowanie PDE tablicy stron
;Usuniêcie ramek pamiêci zajmowanych przez tablicê stron i stronê:
  mov eax, edx
  call ZWOLNIJ_STRONE
  .dalej:
  pop eax
  call ZWOLNIJ_STRONE
  popa
RET



USUN_N_STRON_POCZAWSZY_OD_EBX
;Procedura usuwa grupê stron.
;Parametry procedury:
;EBX - adres tworzony przez pierwsz¹ stronê z grupy,
;ECX - liczba stron,
;ES:EDI - adres katalogu stron.
  PUSHA
  .petla_usuwania_stron
    call USUN_STRONE
    add ebx, 4096   ;adres tworzony przez nastêpn¹ stronê
  loop .petla_usuwania_stron
POPA
RET

KOPIUJ_GLOWNY_KATALOG_STRON
;Procedura tworzy kopiê katalogu stron.
;Parametry procedury:
;ES:EDI - adres bloku pamiêci, w którym ma zostaæ stworzona kopia katalogu stron.
  push eax
  push edi
  push esi
  push ecx
  mov ax, ds
  push eax
  mov ax, 8
  mov ds, ax
  mov esi, 5f000h      ;adres katalogu stron
  cld
  mov cx, 1024
  rep movsd
  pop eax
  mov ds, ax
  pop ecx
  pop esi
  pop edi
  pop eax
RET

CZYSC_PD_ZE_STRON_USERA
;Procedura kasuje wpisy PDE z katalogu stron
  push eax
  push edi
  push ebx
  mov ax, es
  push eax
  mov ax, 8
  mov es, ax
  mov edi, 5f000h
  mov cx, 1024
  mov ebx, 100b
  .petla:
    mov eax, [es:edi]
    test eax, ebx     ;Okreœlenie, czy tablica stron nale¿y do poziomu user
    jz .mozna_dalej
    mov dword [es:edi], 0   ;usuniêcie pozycji PDE
    .mozna_dalej:
    add edi, 4        ;adres nastêpnego wpisu PDE
  loop .petla
;Opró¿nienie pamiêci cache:
  mov eax, cr3
  mov cr3, eax
  pop eax
  mov es, ax
  pop ebx
  pop edi
  pop eax
RET

ZERUJ_TABLICE_STRON
;Procedura zeruje pamiêæ tablicy stron.
;Parametry procedury:
;ES - selektor segmentu adresu liniowego,
;EDI - adres fizyczny tablicy stron.
  PUSHA
  CALL NORMALIZACJA_ADRESU_TABLICY
  mov ecx, 1024
  mov eax, 0
  .petla
    mov [es:edi], eax
    add edi, 4
  loop .petla
  POPA
RET
