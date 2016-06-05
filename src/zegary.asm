USTAW_TAKT_ZEGARA:
;Procedura ustala now¹ wartoœæ dzielnika czêstotliwoœci uk³adu czasomierza systemowego.
;Parametry procedury:
;BX - nowy licznik uk³adu.
  mov al, 00110100b
  out 43h, al
  mov al, bl
  out 40h, al
  mov al, bh
  out 40h, al
RET

ZAMIEN_CZESTOTLIWOSC_NA_DZIELNIK:
;Procedura zamienia czêstotliwoœæ na dzielnik czêstotliwoœci uk³adu czasomierza systemowego.
;Parametry procedury:
;EBX - czêstotliwoœæ,
;Wyniki:
;BX - dzielnik czêstotliwoœci.
  xor edx, edx
  mov eax, 1193180     ; czêstotliwoœæ zegara
  div ebx
  cmp eax, 0ffffh
  jb .dalej
    mov ax, 0ffffh
  .dalej
  mov bx, ax
RET

USTAW_CZESTOTLIWOSC_ZEGARA
;Procedura ustawia czêstotliwoœæ generowanych przerwañ przez czasomierz systemowy.
;Parametry procedury:
;EBX - czêstotliwoœæ.
PUSHA
  CALL ZAMIEN_CZESTOTLIWOSC_NA_DZIELNIK
  CALL USTAW_TAKT_ZEGARA
POPA
RET
