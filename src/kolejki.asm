;Procedury zosta³y opisane w rozdziale 8.

DOLUZ_ELEMENT_NA_KONIEC_KOLEJKI
;Parametry procedury
;ESI - adres dok³adanego elementu,
;EDI - adres ostatiego elementu kolejki,
;EDX - rozmiar pola danych elementu
  push eax
  push esi
  push ebx
  mov ax, es
  push eax
  mov ax, 8
  mov es, ax
  cmp edi, 0
  jne .kolejka_nie_jest_pusta
  mov edi, esi
  jmp .zerowanie_pola_nastepnego_elementu
  .kolejka_nie_jest_pusta:
  add edi, edx
  mov [es:edi], esi
  mov edi, esi
  .zerowanie_pola_nastepnego_elementu:
  add esi, edx
  mov dword [es:esi], 0
  pop eax
  mov es, ax
  pop ebx
  pop esi
  pop eax
RET

USUN_ELEMENT_Z_KOLEJKI
;Parametry procedury:
;ESI - adres usuwanego elementu,
;EDI - adres pocz¹tku kolejki,
;ECX - adres koñca kolejki,
;EDX -rozmiar pola danych.
;Wyniki:
;EBX - nowy adres pocz¹tku kolejki,
;ECX - nowy adres koñca kolejki,
;ESI - adres elementu usuniêtego z kolejki.
  push eax
  push esi
  mov ax, es
  push eax
  mov ax, 8
  mov es, ax
  mov ebx, edi
  cmp esi, edi
  jne .usowany_element_nie_jest_pierwszym
  push esi
  add esi, edx
  mov edi, [es:esi]
  mov ebx, edi
  pop esi
  jmp .koniec_procedury
  .usowany_element_nie_jest_pierwszym:
  push edi
  call ZNAJDZ_ELEMENT_POPRZEDZAJACY
  cmp esi, ecx
  jne .usowany_element_nie_jest_ostatnim
  mov ecx, edi
  .usowany_element_nie_jest_ostatnim
  add edi, edx
  add esi, edx
  mov eax, [es:esi]
  sub esi, edx
  mov [es:edi], eax
  pop edi
  .koniec_procedury:
  cmp ebx, 0
  jne .mozna_konczyc
  xor ecx, ecx
  .mozna_konczyc
  pop eax
  mov es, ax
  pop esi
  pop eax
RET

ZNAJDZ_ELEMENT_POPRZEDZAJACY
;Parametry procedury:
;ESI - adres elementu, wzglêdem którego bêdzie szukany element poprzedzaj¹cy,
;EDI - adres pocz¹tku kolejki,
;EDX - rozmiar pola danych.
;Wyniki:
;EDI - adres odnalezionego elementu (0 gdy nie zosta³ odnaleziony).
  push eax
  cmp edi, 0
  je .koniec_petli
  .petla:
    add edi, edx
    mov eax, [es:edi]
    cmp eax, esi
    jne .to_jeszcze_nie_jest_element_poprzedzajacy
    sub edi, edx
    jmp .koniec_petli
    .to_jeszcze_nie_jest_element_poprzedzajacy:
    mov edi, eax
    cmp edi, 0
    je .koniec_petli
  jmp .petla
  .koniec_petli:
  pop eax
RET

ZNAJDZ_ELEMENT_O_OKRESLONYM_POLU_DANYCH
;Procedura zak³ada 4 bajtowe pole danych.
;Parametry procedury:
;EDI - adres pierwszego elementu kolejki,
;EAX - zawartoœæ pola danych.
;Wyniki:
;ESI - adres odnalezionego elementu.
  push eax
  push edi
  push ebx
  mov bx, es
  push ebx
  mov bx, 8
  mov es, bx
  cmp edi, 0
  jne .petla_poszukiwania
  mov esi, 0
  jmp .koniec_procedury
  .petla_poszukiwania:
    cmp eax, [es:edi]
    jne .nie_jest_to_jeszcze_ten_element
    mov esi, edi
    jmp .koniec_procedury
    .nie_jest_to_jeszcze_ten_element
    mov edi, [es:edi+4]
    cmp edi, 0
    jne .mozna_dalej
    mov esi, 0
    jmp .koniec_procedury
    .mozna_dalej:
  jmp .petla_poszukiwania
  .koniec_procedury:
  pop eax
  mov es, ax
  pop ebx
  pop edi
  pop eax
RET

ROTUJ_KOLEJKE_W_LEWO_Z_PRZENIESIENIEM_NA_KONIEC
;Parametry procedury:
;EDI - adres pierwszego elementu kolejki,
;ESI - adres ostatniego elementu kolejki,
;EDX - rozmiar pola danych.
;Wyniki:
;EDI - adres nowego pierwszego elementu kolejki,
;ESI - adres nowego ostatniego elementu kolejki.
  push eax
  mov ax, es
  push eax
  mov ax, 8
  mov es, ax
  cmp esi, edi
  je .kolejka_zawiera_tylko_jeden_element
  add esi, edx
  mov [es:esi], edi
  mov esi, edi
  mov edi, [es:edi+4]
  mov dword [es:esi+4], 0
  .kolejka_zawiera_tylko_jeden_element:
  pop eax
  mov es, ax
  pop eax
RET
