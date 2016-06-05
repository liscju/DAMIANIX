;Do procedur zawartych w pliku utworzone s¹ furtki wywo³añ w tablicy GDT.
;W celu wywo³ania us³ugi j¹dra w programie u¿ytkowym nale¿y pos³u¿yæ siê
;poleceniem CALL, po którym nale¿y podaæ selektor furtki z polem RPL równym 11B
;oraz ignorowany offset. Przyk³ad wywo³ania:
;CALL 107:25 - gdzie 107 jest selektorem furtki wywo³ania (RPL=3),  25 jest ignorowanym
;offsetem.

POZIOM_4_WYSWIETL_ZNAK
;Us³uga wyœwietlania znaku na ekranie.
   call WYSWIETL_ZNAK
RETF

POZIOM_4_WYSWIETL_LICZBE_DZIESIETNIE
;Us³uga wypiania liczby w formacie dziesiêtnym.
  cli
  CALL WYPISZ_LICZBE_DZIESIETNIE
  sti
RETF

POZIOM_4_SPRAWDZENIE_LICZBY
;Wypisanie liczby w formacie dziesiêtnym i wypisanie spacji.
  cli
  call WYPISZ_LICZBE_DZIESIETNIE
  mov dl, ' '
  CALL WYSWIETL_ZNAK
  sti
RETF

POZIOM_4_WYWLASZCZENIE
;Us³uga wyw³aszczaj¹ca proces
  CALL PROCEDURA_WYWLASZCZAJACA
RETF

POZIOM_4_WYPISZ_TEKST
;Us³uga wypisuj¹ca tekst na ekranie
pusha
  call WYPISZ_CIAG_ZNAKOW
popa
RETF

POZIOM_4_WYPISZ_TEKST_NA_EKRANIE
;Us³uga wypisuj¹ca synchronicznie tekst na ekranie
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
;Wyw³aszczenie z zachowaniem rejestów
  pusha
  call PROCEDURA_WYWLASZCZAJACA
  popa
RETF
