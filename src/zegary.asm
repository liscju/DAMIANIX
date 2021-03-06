USTAW_TAKT_ZEGARA:
;Procedura ustala nową wartość dzielnika częstotliwości układu czasomierza systemowego.
;Parametry procedury:
;BX - nowy licznik układu.
  mov al, 00110100b
  out 43h, al
  mov al, bl
  out 40h, al
  mov al, bh
  out 40h, al
RET

ZAMIEN_CZESTOTLIWOSC_NA_DZIELNIK:
;Procedura zamienia częstotliwość na dzielnik częstotliwości układu czasomierza systemowego.
;Parametry procedury:
;EBX - częstotliwość,
;Wyniki:
;BX - dzielnik częstotliwości.
  xor edx, edx
  mov eax, 1193180     ; częstotliwość zegara
  div ebx
  cmp eax, 0ffffh
  jb .dalej
    mov ax, 0ffffh
  .dalej
  mov bx, ax
RET

USTAW_CZESTOTLIWOSC_ZEGARA
;Procedura ustawia częstotliwość generowanych przerwań przez czasomierz systemowy.
;Parametry procedury:
;EBX - częstotliwość.
PUSHA
  CALL ZAMIEN_CZESTOTLIWOSC_NA_DZIELNIK
  CALL USTAW_TAKT_ZEGARA
POPA
RET
