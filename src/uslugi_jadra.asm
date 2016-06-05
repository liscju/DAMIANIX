;Do procedur zawartych w pliku utworzone s� furtki wywo�a� w tablicy GDT.
;W celu wywo�ania us�ugi j�dra w programie u�ytkowym nale�y pos�u�y� si�
;poleceniem CALL, po kt�rym nale�y poda� selektor furtki z polem RPL r�wnym 11B
;oraz ignorowany offset. Przyk�ad wywo�ania:
;CALL 107:25 - gdzie 107 jest selektorem furtki wywo�ania (RPL=3),  25 jest ignorowanym
;offsetem.

POZIOM_4_WYSWIETL_ZNAK
;Us�uga wy�wietlania znaku na ekranie.
   call WYSWIETL_ZNAK
RETF

POZIOM_4_WYSWIETL_LICZBE_DZIESIETNIE
;Us�uga wypiania liczby w formacie dziesi�tnym.
  cli
  CALL WYPISZ_LICZBE_DZIESIETNIE
  sti
RETF

POZIOM_4_SPRAWDZENIE_LICZBY
;Wypisanie liczby w formacie dziesi�tnym i wypisanie spacji.
  cli
  call WYPISZ_LICZBE_DZIESIETNIE
  mov dl, ' '
  CALL WYSWIETL_ZNAK
  sti
RETF

POZIOM_4_WYWLASZCZENIE
;Us�uga wyw�aszczaj�ca proces
  CALL PROCEDURA_WYWLASZCZAJACA
RETF

POZIOM_4_WYPISZ_TEKST
;Us�uga wypisuj�ca tekst na ekranie
pusha
  call WYPISZ_CIAG_ZNAKOW
popa
RETF

POZIOM_4_WYPISZ_TEKST_NA_EKRANIE
;Us�uga wypisuj�ca synchronicznie tekst na ekranie
  pusha
  mov ax, ds
  push eax
  mov ax, es
  push eax
  mov ax, 24
  mov ds, ax
  call WYPISZ_CIAG_ZNAKOW_NA_EKRANIE
  pop eax
  mov es, ax
  pop eax
  mov ds, ax
  popa
RETF

POZIOM_4_WYWLASZCZANIE_ZADANIA
;Wyw�aszczenie z zachowaniem rejest�w
  pusha
  call PROCEDURA_WYWLASZCZAJACA
  popa
RETF
