USTAW_TAKT_ZEGARA:
;Procedura ustala now� warto�� dzielnika cz�stotliwo�ci uk�adu czasomierza systemowego.
;Parametry procedury:
;BX - nowy licznik uk�adu.
  mov al, 00110100b
  out 43h, al
  mov al, bl
  out 40h, al
  mov al, bh
  out 40h, al
RET

ZAMIEN_CZESTOTLIWOSC_NA_DZIELNIK:
;Procedura zamienia cz�stotliwo�� na dzielnik cz�stotliwo�ci uk�adu czasomierza systemowego.
;Parametry procedury:
;EBX - cz�stotliwo��,
;Wyniki:
;BX - dzielnik cz�stotliwo�ci.
  xor edx, edx
  mov eax, 1193180     ; cz�stotliwo�� zegara
  div ebx
  cmp eax, 0ffffh
  jb .dalej
    mov ax, 0ffffh
  .dalej
  mov bx, ax
RET

USTAW_CZESTOTLIWOSC_ZEGARA
;Procedura ustawia cz�stotliwo�� generowanych przerwa� przez czasomierz systemowy.
;Parametry procedury:
;EBX - cz�stotliwo��.
PUSHA
  CALL ZAMIEN_CZESTOTLIWOSC_NA_DZIELNIK
  CALL USTAW_TAKT_ZEGARA
POPA
RET
