;Procedury opisane w rozdziale 8


INICJUJ_PULE_DYNAMICZNA
;Procedura tworzy pul� dynamiczn� (stert�).
;Parametry procedury:
;EDI - adres obszaru pami�ci, pocz�wszy od kt�rego zostanie utworzona pula,
;EDX - rozmiar pola danych elementu puli (do tej warto�ci zostanie dodane 4 na wska�nik nast�pnego elementu),
;ECX - liczba element�w puli.
;Procedura na pierwszych 32 bitach obszaru puli b�dzie przechowywa�a adres
;pierwszego wolnego elmentu puli.
  push edi
  push eax
  mov ax, es
  push eax
  mov ax, 8
  mov es, ax
  jecxz .koniec_procedury
  mov eax, edi
  add eax, 4
  mov [es:edi], eax  ; pierwszym wolnym elementem b�dzie element oddalony o 4 bajty od pocz�tku puli
  add edi, 4
  .petla
    add edi, edx  ;obliczenie adresu pola wska�nika nast�pnego elementu
    mov eax, edi
    add eax, 4   ;adres nast�pnego elementu puli
    mov [es:edi], eax ;zapis do wska�nika nast�pnego elmentu adresu nast�pnego elementu
    add edi, 4
  loop .petla
  sub edi, 4
  mov dword [es:edi], 0 ;ostatni element wskazuje na null
 .koniec_procedury:
  pop eax
  mov es, ax
  pop eax
  pop edi
RET


POBIERZ_ELEMENT_Z_PULI
;Procedura zwraca pierwszy wolny element puli.
;Parametry procedury:
;EDI - adres puli,
;EDX - rozmiar pola danych element�w puli,
;Wyniki:
;EDI - adres zwr�conego elmentu (0 gdy nie ma wolnych element�w).
  push eax
  push esi
  push ebx
  mov ax, es
  push eax
  mov esi, [es:edi]
  pusha
  mov edi, esi
  popa
  cmp esi, 0
  je .pula_w_calosci_jest_zajeta
  mov ebx, esi
  add esi, edx
  mov eax, [es:esi]
  mov [es:edi], eax
  mov edi, ebx
  jmp .koniec_procedury
  .pula_w_calosci_jest_zajeta:
  xor edi, edi
  .koniec_procedury:
  pop eax
  mov es, ax
  pop ebx
  pop esi
  pop eax
RET

DOLUZ_ELEMENT_DO_PULI
;Procedura zwraca element do puli.
;Parametry procedury:
;ESI - adres zwracanego elementu,
;EDI - adres puli,
;EDX - rozmiar pola danych element�w.
  push eax
  push ebx
  mov ax, es
  push eax
  mov ax, 8
  mov es, ax
  mov eax, [es:edi]
  mov [es:edi], esi
  add esi, edx
  mov [es:esi], eax
  pop eax
  mov es, ax
  pop ebx
  pop eax
RET
