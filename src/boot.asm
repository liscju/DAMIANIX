;KOD ANALOGICZNY DO KODU BOOT LOADERA Z ROZDZIA£U 9 KSI¥¯KI
;W KSI¥¯CE ZNAJDUJE SIÊ OPIS PODEJMOWANYCH DZIA£AÑ.
[BITS 16]
[ORG 000h]

jmp poczatek

nazwa_systemu	          		DB	'DAMIANIX'
wielkosc_sektora		    	DW	200h
welkosc_clustra			        DB	1h
ile_zarezerwowanych_sektorow	        DW	1h
ile_tablic_alokacji			DB	2h
ile_elementow_katalogu_glownego	        DW	0E0h
calkowita_liczba_sektorow		DW	0B40h
media_descriptor_byte		        DB	0f0h
ile_sektorow_na_fat			DW	9h
ile_sektorow_na_sciezke		        DW	12h
ile_glowic				DW	2h
ile_ukrytych_sektorow		        DD	0h
total_sectors_large			DD	0h
numer_dyskietki			        DB	0h
flags2				        DB	0h
signature				DB	029h
volume_id			        DD	0ffffffffh
nazwa_volumenu			        DB	'DAMIANIX_OS'
nazwa_systemu_plikow		        DB	'FAT12   '



poczatek:
  cli
  mov ax, 07c0h
  mov ds, ax
  mov ax, 0h
  mov ss, ax
  mov sp, 0ffffh
  sti
  mov dx, boot_zaladowany
  CALL WYPISZ_TEKST
  mov ax, ds
  add ax, 200h
  mov es, ax
  xor bx, bx
;Wczytanie katalogu g³ównego:
  mov dx, [SEKTOR_ROOT_DIRECTORY]
  mov cl,[WIELKOSC_ROOT_DIRECTORY]
  mov ch, 0
  CALL ODCZYT_Z_DYSKU
;Szukanie pliku systemu operacyjnego:
  xor di, di
  mov dx, jadro
  CALL SZUKAJ_JADRA
  push ax
;Wczytanie tablicy FAT:
  xor bx, bx
  mov dx, [SEKTOR_FAT]
  mov cl, [WIELKOSC_FAT]
  mov ch, 0
  CALL ODCZYT_Z_DYSKU
  mov si, 2000h
  mov ax, 8000h
  mov es, ax
  xor bx, bx
  pop ax
  CALL WCZYTAJ_PLIK_JADRA
  mov ax, 8000h
  push ax
  mov ax, 0h
  push ax
  retf
  CALL PROCEDURA_BEZ_KONCA

WYPISZ_TEKST:
  push bx
  xor bh, bh
  mov bl, 07h
  mov si, dx
  mov ah, 0eh
  petla1_1:
    mov al, [si]
    cmp al, 0
    je end_petla1_1
    int 10h
    inc si
  jmp petla1_1
  end_petla1_1:
  pop bx
RET


CHS:
  push bx
  mov ax, dx
  mov bx, dx
  xor dx, dx
  mov cx, [ile_sektorow_na_sciezke]
  div cx
  inc dx
  push dx
  xor dx, dx
  mov cx, [ile_glowic]
  div cx
  pop cx
  mov ch, al
  mov dh, dl
  xor dl, dl
  pop bx
RET

ODCZYT_Z_DYSKU:
petla_odczytu:
  push bx
  push cx
  push dx
  CALL CHS
  mov al, 1
  mov dl, 0
  mov ah, 02h
  int 13h
  jnc koniec_p_o
  mov dx, blad
  CALL WYPISZ_TEKST
  mov dx, blad_0
  CALL WYPISZ_TEKST
  CALL PROCEDURA_BEZ_KONCA
  koniec_p_o:
  pop dx
  pop cx
  pop bx
  inc dx
  add bx, 200h
loop petla_odczytu
RET

SZUKAJ_JADRA:
  mov cx, [ile_elementow_katalogu_glownego]
  petla_s_j:
    CALL POROWNAJ_NAPISY
    jc napisy_rowne
    add di, 20h
  loop petla_s_j
  mov dx, blad
  CALL WYPISZ_TEKST
  mov dx, blad_1
  CALL WYPISZ_TEKST
  CALL PROCEDURA_BEZ_KONCA
  napisy_rowne:
  mov ax, WORD [es:di+1ah]
  push ax
  mov dx, znalezione_jadro
  CALL WYPISZ_TEKST
  pop ax
RET

POROWNAJ_NAPISY
  push cx
  push si
  push di
  mov si, dx
  mov cx, 11
  petla:
    mov al, [es:di]
    mov ah, [si]
    cmp al, ah
    jne koniec_napisy_rozne
    inc di
    inc si
  loop petla
  stc
  jmp fin
  koniec_napisy_rozne:
  clc
  fin:
  pop di
  pop si
  pop cx
RET

PROCEDURA_BEZ_KONCA:
PETLA_GLOWNA_P_B_K:
nop
JMP PETLA_GLOWNA_P_B_K
RET


SPR:
  pusha
  push ax
  mov dx, ent
  CALL WYPISZ_TEKST
  pop ax
  mov ah, 0eh
  int 10h
  mov dx, ent
  CALL WYPISZ_TEKST
  mov ah, 0
  int 16h
  popa
ret



WCZYTAJ_PLIK_JADRA:
  push ax
  add ax, [PIERWSZY_SEKTOR_Z_DANYMI]
  mov dx, ax
  mov cl, 1h
  mov ch, 0h
  CALL ODCZYT_Z_DYSKU
  pop dx
  CALL NASTEPNY_CLUSTER
  CALL NORMALIZACJA_CLUSTRA
  cmp ax, 0ff7h
  jbe WCZYTAJ_PLIK_JADRA
RET

NASTEPNY_CLUSTER:
  push si
  mov ax, dx
  shr ax, 1h
  add ax, dx
  add si, ax
  mov ax, word [si]
  pop si
RET

NORMALIZACJA_CLUSTRA
  test dx, 1h
  jz parzysty
    shr ax, 4h
  jmp koniec_n_c
  parzysty:
   and ax, 0fffh
  koniec_n_c:
RET


SEKTOR_ROOT_DIRECTORY     DW  19
WIELKOSC_ROOT_DIRECTORY   DB 14

SEKTOR_FAT                DW  1
WIELKOSC_FAT              DB  9

PIERWSZY_SEKTOR_Z_DANYMI  DW  31

ent db 13, 10, 0
jadro db 'JADRO111COR'
boot_zaladowany db 'BOOTLOADER ZALADOWANY',13, 10, 0

znalezione_jadro  db   'Znalazlem jadro. LADUJE FAT', 13, 10, 0


blad    db       'blad o id: ', 0
blad_0  db       '0', 0

blad_1  db       '1', 0


times 510-($-$$) db 0
dw    0aa55h
