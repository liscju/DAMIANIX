ZAREZERWOJ_STRONE
;Procedura szuka w binarnej mapie pami�ci wolnej ramki.
;Wyniki:
;EAX - adres zarezerwowanej ramki (0 gdy ca�a pami�� jest zaj�ta)
  push ebx
  mov ax, es
  push eax
  push ecx
  push edi
  mov ax, 8
  mov es, ax
  mov edi, 1024*1024
;P�tla szuka pierwszego bajtu binarnej mapy pami�ci r�nego od warto�ci 0FFH:
  .petla_znajdowania_wolnej_przestrzeni:
    mov al, [es:edi]
    cmp al, 0ffh
    jne .koniec_petli_znajdowania_wolnej_przestrzeni
    inc edi
  jmp .petla_znajdowania_wolnej_przestrzeni
  .koniec_petli_znajdowania_wolnej_przestrzeni:
;Okre�lenie numeru bitu w odnalezionym bajcie:
  not al
  shl ax, 8
  xor ebx, ebx
  bsr bx, ax    ; binarne poszukiwanie w ty�
  mov cx, 16
  sub cx, bx   ;W CX zosta�a obliczona pozycja bitu
  btc ax, bx   ;prze��czenie warto�ci bitu
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
;Sprawdzenie, czy adres ramki nie przekracza dost�pnego rozmiaru pami�ci:
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
;Obliczenie indeksu ramki w pami�ci:
  mov ebx, 4096
  xor edx, edx
  div ebx
;Obliczenie adresu bajtu w binarnej mapie pami�ci, przechowuj�cego informacj�
;o ramce:
  xor edx, edx
  mov ebx, 8
  div ebx
  INC EDX
  mov bx, 8
  mov es, bx
  mov edi, 1024*1024       ; adres binarnej mapy pami�ci
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
;Procedura odszukuje pierwsz� woln� pozycj� w katalogu stron lub tablicy stron
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
;Procedura tworzy dost�p do tablicy lub katalogu stron (tablica stron lub
;katalog stron mo�e znajdowa� si� poza przestrzeni� adresow� utworzon� przez
;stronicowanie).
;Parametry procedury:
;EDI - adres fizyczny
;Wyniki:
;Adres 1000h b�dzie wskazywa� na adres fizyczny przekazany procedurze w parametrze.
push esi
push eax
  mov ax, es
  push eax
  ;Opr�nienie pami�ci cache:
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
;Procedura szuka okre�lonej gruy wolnych wpis�w PTE znajduj�cych si�
;przy sobie.
;Parametry procedury:
;ES - selektor adresu liniowego,
;EDI - adres katalogu stron,
;AX - ilo�� PTE.
;Wyniki:
;ES:EDI - adres pierwszego wolnego PTE z odnalezionej grupy,
;AX - 0 gdy nie odnaleziono dostatecznie du�ej grupy wolnych PTE.
  mov dx, ax
;Poszukiwanie tablic stron nale��cych do poziomu supervisor:
  mov ecx, 1024
  .petla1:
    mov ax, dx
    mov esi, [es:edi]
    cmp esi, 0
    jne .jest_tablica_stron
    mov ax, dx
    jmp .nie_ma_tablicy_stron
    .jest_tablica_stron:
    test esi, 100b        ;Sprawdzenie czy tablica stron nale�y do poziomu supervisor
    jz .jest_przestrzen_adresowa_dla_supervisora
    xor ax, ax
    jmp .koniec_petel
    .jest_przestrzen_adresowa_dla_supervisora:
    and esi, 11111111111111111111000000000000b          ;Uzyskanie adresu fizycznego tablicy stron
    push edi
    mov edi, esi
    call NORMALIZACJA_ADRESU_TABLICY                    ;Utworzenie dost�pu do pami�ci zajmowanej przez odnalezion� tablic� stron
    mov esi, edi
    pop edi
;Przeszukiwanie PTE wewn�trz odnalezionej tablicy stron:
    push ecx
    mov ecx, 1024
    .petla2:
      mov ebx, [es:esi]
      cmp ebx, 0  ;Je�eli warto�� PTE wynosi 0, oznacza to, �e wpis jest wolny
      je .znaleziono_jeden_wolny_pte
      mov ax, dx  ;Gdy odnaleziono zaj�ty PTE, nale�y przywr�ci� licznik ilo�ci PTE koniecznych do odnalezienia.
      jmp .dalej
      .znaleziono_jeden_wolny_pte:
      dec ax     ;Zmniejszenie warto�ci licznika ilo�ci PTE koniecznych do odnalezienia.
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
  shl eax, 2   ;mno�enie przez 4
  sub esi, eax
  xchg edi, esi
  mov ax, 3
  .koniec_procedury:
RET


SZUKAJ_N_OSTATNICH_WOLNYCH_PTE ; wersja dla user
;Procedura szuka okre�lonej gruy wolnych wpis�w PTE znajduj�cych si�
;przy sobie.
;Parametry procedury:
;ES - selektor adresu liniowego,
;EDI - adres katalogu stron,
;AX - ilo�� PTE.
;Wyniki:
;ES:EDI - adres pierwszego wolnego PTE z odnalezionej grupy,
;AX - 0 gdy nie odnaleziono dostatecznie du�ej grupy wolnych PTE.
  mov dx, ax
;Strony dla poziomu user znajduj� pocz�wszy od ko�ca przestrzeni adresowej,
;poszukiwania nale�y wi�c rozpocz�� od ostatniej tablicy stron.
  add edi, 1023 * 4      ;Obliczenie adresu ostatniego PDE
;Poszukiwanie tablic stron nale��cych do poziomu user:
  mov ecx, 1024
  .petla1:
    mov esi, [es:edi]
    cmp esi, 0
    jne .jest_tablica_stron
    mov ax, dx
    jmp .nie_ma_tablicy_stron
    .jest_tablica_stron:
    test esi, 100b        ;Sprawdzenie czy tablica stron nale�y do poziomu user
    jnz .jest_przestrzen_adresowa_dla_usera
    xor ax, ax
    jmp .koniec_petel
    .jest_przestrzen_adresowa_dla_usera:
    and esi, 11111111111111111111000000000000b          ;Uzyskanie adresu fizycznego tablicy stron
    push edi
    mov edi, esi
    call NORMALIZACJA_ADRESU_TABLICY                    ;Utworzenie dost�pu do pami�ci zajmowanej przez odnalezion� tablic� stron
    mov esi, edi
    pop edi
    add esi, 1023*4                                     ;Adres ostatniego PTE tablicy stron (poszukiwania od ko�ca tablicy)
;Przeszukiwanie PTE wewn�trz odnalezionej tablicy stron:
    push ecx
    mov ecx, 1024
    .petla2:
      mov ebx, [es:esi]
      cmp ebx, 0        ;Je�eli warto�� PTE wynosi 0, oznacza to, �e wpis jest wolny
      je .znaleziono_jeden_wolny_pte
      mov ax, dx        ;Gdy odnaleziono zaj�ty PTE, nale�y przywr�ci� licznik ilo�ci PTE koniecznych do odnalezienia.
      jmp .dalej
      .znaleziono_jeden_wolny_pte:
      dec ax            ;Zmniejszenie warto�ci licznika ilo�ci PTE koniecznych do odnalezienia.
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
;Procedura poszukuje grupy wolnych PDE, poszukiwania rozpoczyna od pocz�ktu
;katalogu stron.
;Parametry procedury:
;ES - selektor segmentu adresu liniowego,
;EDI - adres katalogu stron,
;AX - ilo�� potrzebnych PDE
;Wyniki:
;ES:EDI - adres pierwszego z grupy wolnych wpis�w PDE,
;AX - 0 gdy nie odnaleziono wymaganej grupy wolnych PDE.
  mov dx, ax
;Przeszukiwanie pozycji katalogu stron:
  mov ecx, 1024
  .petla:
    mov ebx, [es:edi]
    cmp ebx, 0
    je .znaleziono_jeden_wolny_pde
    mov ax, dx ;Gdy odnaleziono zaj�ty PDE, nale�y przywr�ci� licznik ilo�ci PDE koniecznych do odnalezienia.
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
;Procedura poszukuje grupy wolnych PDE, poszukiwania rozpoczyna od ko�ca katalogu stron
;katalogu stron.
;Parametry procedury:
;ES - selektor segmentu adresu liniowego,
;EDI - adres katalogu stron,
;AX - ilo�� potrzebnych PDE
;Wyniki:
;ES:EDI - adres pierwszego z grupy wolnych wpis�w PDE,
;AX - 0 gdy nie odnaleziono wymaganej grupy wolnych PDE.
  mov dx, ax
  add edi, 1023*4     ;Obliczenie adresu ostatniego PDE w katalogu stron
; petla skacze po elementach katalogu stron
  mov ecx, 1024
  .petla:
    mov ebx, [es:edi]
    cmp ebx, 0
    je .znaleziono_jeden_wolny_pde
    mov ax, dx ;Gdy odnaleziono zaj�ty PDE, nale�y przywr�ci� licznik ilo�ci PDE koniecznych do odnalezienia.
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
;Procedura na podstawie podanego adresu, nale��cego do przestrzeni adresowej
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
  call NORMALIZACJA_ADRESU_TABLICY     ;utworzenie dost�pu do tablicy stron
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
;ES:EDI - adres, pod kt�ry nale�y od�o�y� wpis PDE,
;EAX - adres ramki, w kt�rej b�dzie przechowywana tablica stron
  push ebx
  xor ebx, ebx
;Ustalenie atrybut�w PDE:
  mov bl, 00000011b   ; PS, 0, A, PCD, PWT, U/S, R/W, P
  mov bh, 0000b       ; AV, G
  push edi
  mov edi, eax
  call ZERUJ_TABLICE_STRON
  pop edi
  or ebx, eax
;Od�o�enie PDE pod wskazany adres:
  mov [es:edi], ebx
  pop ebx
RET

TWORZ_PDE_USER   ;dla poziomu user
;Procedura tworzy nowy wpis katalogu stron
;Parametry procedury:
;ES:EDI - adres, pod kt�ry nale�y od�o�y� wpis PDE,
;EAX - adres ramki, w kt�rej b�dzie przechowywana tablica stron
  push ebx
  xor ebx, ebx
;Ustalenie atrybut�w PDE:
  mov bl, 00000111b   ; PS, 0, A, PCD, PWT, U/S, R/W, P
  mov bh, 0000b       ; AV, G
  push edi
  mov edi, eax
  call ZERUJ_TABLICE_STRON
  pop edi
  or ebx, eax
;Od�o�enie PDE pod wskazany adres:
  mov [es:edi], ebx
  pop ebx
RET

TWORZ_PTE   ;dla poziomu supervisor
;Procedura tworzy nowy wpis tablicy stron
;Parametry procedury:
;ES:EDI - adres, pod kt�ry nale�y od�o�y� wpis PTE,
;EAX - adres ramki, w kt�rej b�dzie przechowywana strona
  push ebx
  xor ebx, ebx
;Ustalenie atrybut�w PTE:
  mov bl, 00000011b   ; 0, D, A, PCD, PWT, U/S, R/W, P
  mov bh, 0000b       ; AV, G
  or ebx, eax
  mov [es:edi], ebx
  pop ebx
RET


TWORZ_PTE_USER  ;dla poziomu user
;Procedura tworzy nowy wpis tablicy stron
;Parametry procedury:
;ES:EDI - adres, pod kt�ry nale�y od�o�y� wpis PTE,
;EAX - adres ramki, w kt�rej b�dzie przechowywana strona
  push ebx
  xor ebx, ebx
  mov bl, 00000111b   ; 0, D, A, PCD, PWT, U/S, R/W, P
  mov bh, 0000b       ; AV, G
  or ebx, eax
  mov [es:edi], ebx
  pop ebx
RET

TWORZ_N_PDE  ;dla poziomu supervisor
;Procedura tworzy grup� PDE s�siaduj�cych ze sob�.
;Parametry procedury:
;ES - selektor segmentu adresu liniowego,
;EDI - adres pierwszego wpisu PDE,
;AX - ilo�� wpis�w.
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
;Procedura tworzy grup� PDE s�siaduj�cych ze sob�.
;Parametry procedury:
;ES - selektor segmentu adresu liniowego,
;EDI - adres pierwszego wpisu PDE,
;AX - ilo�� wpis�w.
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
;procedura tworzy grup� PTE s�siaduj�cych ze sob�.
;Parametry procedury:
;ES - selektor segmentu adresu liniowego,
;EDI - adres do zapisu pierwszego PTE,
;AX - ilo�� PTE.
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
;procedura tworzy grup� PTE s�siaduj�cych ze sob�.
;Parametry procedury:
;ES - selektor segmentu adresu liniowego,
;EDI - adres do zapisu pierwszego PTE,
;AX - ilo�� PTE.
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
;Procedura tworzy okre�lon� liczb� stron.
;Parametry procedury:
;ES:ESI - adres PDE, pocz�wszy od kt�rego b�d� tworzone tablice stron,
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
  div ebx  ;obliczenie liczby pe�nych tablic stron
  mov cx, ax
  jcxz .mniej_stron
  push edx
  .petla:
    push ecx
    mov edi, [es:esi]
    and edi, 0fffff000h     ;Wyznaczenie adresu tablicy stron
;Wype�nienie ca�ej tablicy stron:
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
;Wype�nienie cz�ci tablicy stron:
  mov ax, dx
  call TWORZ_N_PTE
  pop esi
  pop edi
  pop edx
  pop ecx
  pop ebx
RET


WYPELNIJ_CIAG_TABLIC_STRON_USER   ;poziom user
;Procedura tworzy okre�lon� liczb� stron.
;Parametry procedury:
;ES:ESI - adres PDE, pocz�wszy od kt�rego b�d� tworzone tablice stron,
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
  div ebx     ;obliczenie liczby pe�nych tablic stron
  mov cx, ax
  jcxz .mniej_stron
  push edx
  .petla:
    push ecx
    mov edi, [es:esi]
    and edi, 0fffff000h   ;Wyznaczenie adresu tablicy stron
;Wype�nienie ca�ej tablicy stron:
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
;Wype�nienie cz�ci tablicy stron:
  mov ax, dx
  call TWORZ_N_PTE_USER
  pop esi
  pop edi
  pop edx
  pop ecx
  pop ebx
RET

DODAJ_N_STRON  ;poziom supervisor
;Procedura dodaje okre�lon� liczb� stron, pocz�wszy od okre�lonego miejsca
;w tablicy stron (procedura zak�ada, �e pocz�wszy od podanego indeksu reszta
;wpis�w w tablicy jest pusta).
;Parametry procedury:
;ES - selektor segmentu adresu liniowego,
;ESI - adres PDE tablicy stron, w kt�rej zostan� dodane pierwsze wpisy,
;CX - liczba stron do dodania,
;BX - indeks PTE w tablicy stron, pocz�wszy od kt�rego zostan� dodane strony.
  cmp bx, 1024
  jae .przejdz_do_tworzenia_pde
  mov ax, 1024
  sub ax, bx              ;obliczenie liczby wolnych wpis�w PTE w tablicy stron
  mov edi, [es:esi]
  and edi, 0fffff000h     ;Obliczenie adresu tablicy stron.
  movzx ebx, bx
;Obliczenie adresu pierwszego wpisu PTE, od kt�rego nast�pi dodawanie stron:
  shl ebx, 2
  add edi, ebx
  shr ebx, 2
  cmp cx, ax
  jb .zmiesci_sie
;W przypadku niedostatecznej liczby pustych wpis�w PTE we wskazanej tablicy stron,
;nast�puje utworzenie nowej:
  sub cx, ax ;odj�cie od ca�kowitej liczby PTE do dodania tych, kt�re zmieszcz� si� we wskazanej tablicy
  push ecx
  call TWORZ_N_PTE       ;tworzenie stron we wskazanej tablicy stron
  pop ecx
  add esi, 4
  .przejdz_do_tworzenia_pde:
  xor edx, edx
  xor eax, eax
  mov ax, cx         ;w CX znajduje si� liczba stron do dodania
;Okre�lenie liczby niezb�dnych tablic stron do dodania:
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
;Wype�nie utworzonych tablic stron nowymi pozycjami:
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
;Procedura dodaje okre�lon� liczb� stron, pocz�wszy od okre�lonego miejsca
;w tablicy stron (procedura zak�ada, �e pocz�wszy od podanego indeksu reszta
;wpis�w w tablicy jest pusta).
;Parametry procedury:
;ES - selektor segmentu adresu liniowego,
;ESI - adres PDE tablicy stron, w kt�rej zostan� dodane pierwsze wpisy,
;CX - liczba stron do dodania,
;BX - indeks PTE w tablicy stron, pocz�wszy od kt�rego zostan� dodane strony.
  cmp bx, 1024
  jae .przejdz_do_tworzenia_pde
  mov ax, 1024
  sub ax, bx      ;obliczenie liczby wolnych wpis�w PTE w tablicy stron
  mov edi, [es:esi]
  and edi, 0fffff000h  ;Obliczenie adresu tablicy stron.
  movzx ebx, bx
;Obliczenie adresu pierwszego wpisu PTE, od kt�rego nast�pi dodawanie stron:
  shl ebx, 2
  add edi, ebx
  shr ebx, 2
  cmp cx, ax
  jb .zmiesci_sie
;W przypadku niedostatecznej liczby pustych wpis�w PTE we wskazanej tablicy stron,
;nast�puje utworzenie nowej:
  sub cx, ax
  push ecx
  call TWORZ_N_PTE_USER   ;tworzenie stron we wskazanej tablicy stron
  pop ecx
  add esi, 4
  .przejdz_do_tworzenia_pde:
  xor edx, edx
  xor eax, eax
  mov ax, cx             ;w CX znajduje si� liczba stron do dodania
;Okre�lenie liczby niezb�dnych tablic stron do dodania:
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
;Wype�nie utworzonych tablic stron nowymi pozycjami:
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
;Procedura ma za zadanie znale�� miejsce dla dodawanych stron.
;Parametry procedury:
;ES - selektor segmentu adresu liniowego,
;EDI - adres katalogu stron,
;AX - liczba stron do dodania.
;Wyniki:
;ESI - adres PDE,
;EDI - adres PTE,
;EBX - adres liniowy,
;EAX - kod zako�czenia procedury:
;0 - nie mo�na doda� tylu stron,
;1 - w istniej�cej tablicy stron zmie�ci si� ��dana ilo�� nowych stron,
;2 - nale�y stworzy� now� tablic� stron.
  push edi
  push eax
  cmp ax, 1023
  ja .nie_miesci_sie_w_tablicy_stron
;Poszukiwanie wymaganej liczby wolnych wpis�w PTE:
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
  cmp ax, 0        ;warto�� 0 w rejestrze AX oznacza, �e wolnych PDE jest za ma�o
  je .koniec_procedury
  xor esi, esi
  xchg edi, esi
  call  OBLICZANIE_ADRESU_LINIOWEGO
  mov eax, 2
  .koniec_procedury:
RET


SZUKAJ_PRZESTRZENI_DLA_N_NOWYCH_STRON_USER ; poziom supervisor
;Procedura ma za zadanie znale�� miejsce dla dodawanych stron.
;Parametry procedury:
;ES - selektor segmentu adresu liniowego,
;EDI - adres katalogu stron,
;AX - liczba stron do dodania.
;Wyniki:
;ESI - adres PDE,
;EDI - adres PTE,
;EBX - adres liniowy,
;EAX - kod zako�czenia procedury:
;0 - nie mo�na doda� tylu stron,
;1 - w istniej�cej tablicy stron zmie�ci si� ��dana ilo�� nowych stron,
;2 - nale�y stworzy� now� tablic� stron.
  push edi
  push eax
  cmp ax, 1023
  ja .nie_miesci_sie_w_tablicy_stron
;Poszukiwanie wymaganej liczby wolnych wpis�w PTE:
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
  cmp ax, 0      ;warto�� 0 w rejestrze AX oznacza, �e wolnych PDE jest za ma�o
  je .koniec_procedury
  xor esi, esi
  xchg edi, esi
  call  OBLICZANIE_ADRESU_LINIOWEGO
  mov eax, 2
  .koniec_procedury:
RET



DODAJ_N_STRON_DO_PRZESTRZENI_ADRESOWEJ ;poziom supervisor
;Procedura tworzy grup� nowych stron.
;Parametry procedury:
;ES:EDI - adres katalogu stron,
;EAX - liczba stron do dodania,
;Wyniki:
;ES:EDI - adres fizyczny pocz�tku bloku stron.
;EBX - adres utworzonego ci�gu pami�ci.
  push eax
  call SZUKAJ_PRZESTRZENI_DLA_N_NOWYCH_STRON
  cmp ax, 0
  jne .wystarcza_pamieci
;Zako�czenie procedury (nie mo�na doda� ��danej ilo�ci stron):
  mov edi, 0
  mov ebx, 0
  jmp .koniec_procedury
  .wystarcza_pamieci
  pop ecx    ;liczba stron do dodania
  push ebx
  cmp ax, 1   ;Je�eli AX == 1, znaleziona przestrze� w tablicy stron
              ; jest wystarczaj�ca i nie trzeba dodawa� �adnego PDE.
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
;Procedura tworzy grup� nowych stron.
;Parametry procedury:
;ES:EDI - adres katalogu stron,
;EAX - liczba stron do dodania,
;Wyniki:
;ES:EDI - pocz�tek adresu fizyczny pocz�tku bloku stron.
;EBX - adres utworzonego ci�gu pami�ci.
  push eax
  call SZUKAJ_PRZESTRZENI_DLA_N_NOWYCH_STRON_USER
  cmp ax, 0
  jne .wystarcza_pamieci
;Zako�czenie procedury (nie mo�na doda� ��danej ilo�ci stron):
  mov edi, 0
  mov ebx, 0
  jmp .koniec_procedury
  .wystarcza_pamieci   ;liczba stron do dodania
  pop ecx
  push ebx
  cmp ax, 1      ;Je�eli AX == 1, znaleziona przestrze� w tablicy stron
                 ; jest wystarczaj�ca i nie trzeba dodawa� �adnego PDE.
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
;Procedura okre�la czy tablica stron jest pusta.
;Parametry procedury:
;ES:ESI - adres tablicy stron,
;Wyniki:
;AX - 0 dla pustej tablicy stron, inna warto�� gdy tablica stron nie jest pusta.
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
;Procedura usuwa stron� z przestrzeni adresowej. Usuwa r�wnie� tablic� stron, w
;przypadku, gdy usuni�cie strony spowoduje ca�kowite opr�nienie tablicy stron.
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
  call NORMALIZACJA_ADRESU_TABLICY   ;Utworzenie dost�pu do tablicy stron.
  add edi, ecx
  mov dword [es:edi], 0  ;Wykasowanie PTE strony.
  pop edi
  call NORMALIZACJA_ADRESU_TABLICY
  mov esi, edi
;Sprawdzenie, czy usuni�cie strony nie opr�ni�o ca�ej tablicy:
  call SPRAWDZ_CZY_TABELA_STRON_JEST_PUSTA
;W przypadku pustej tablicy stron usuwany jest wpis PDE j� opisuj�cy:
  pop edi    ;adres PDE
  cmp ax, 0  ;wynik procedury SPRAWDZ_CZY_TABELA_STRON_JEST_PUSTA
  jne .dalej
  mov dword [es:edi], 0   ;Wykasowanie PDE tablicy stron
;Usuni�cie ramek pami�ci zajmowanych przez tablic� stron i stron�:
  mov eax, edx
  call ZWOLNIJ_STRONE
  .dalej:
  pop eax
  call ZWOLNIJ_STRONE
  popa
RET



USUN_N_STRON_POCZAWSZY_OD_EBX
;Procedura usuwa grup� stron.
;Parametry procedury:
;EBX - adres tworzony przez pierwsz� stron� z grupy,
;ECX - liczba stron,
;ES:EDI - adres katalogu stron.
  PUSHA
  .petla_usuwania_stron
    call USUN_STRONE
    add ebx, 4096   ;adres tworzony przez nast�pn� stron�
  loop .petla_usuwania_stron
POPA
RET

KOPIUJ_GLOWNY_KATALOG_STRON
;Procedura tworzy kopi� katalogu stron.
;Parametry procedury:
;ES:EDI - adres bloku pami�ci, w kt�rym ma zosta� stworzona kopia katalogu stron.
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
    test eax, ebx     ;Okre�lenie, czy tablica stron nale�y do poziomu user
    jz .mozna_dalej
    mov dword [es:edi], 0   ;usuni�cie pozycji PDE
    .mozna_dalej:
    add edi, 4        ;adres nast�pnego wpisu PDE
  loop .petla
;Opr�nienie pami�ci cache:
  mov eax, cr3
  mov cr3, eax
  pop eax
  mov es, ax
  pop ebx
  pop edi
  pop eax
RET

ZERUJ_TABLICE_STRON
;Procedura zeruje pami�� tablicy stron.
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
