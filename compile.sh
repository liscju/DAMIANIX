OLDPWD=$(pwd)
BASEDIR=$( cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd )
SRC="${BASEDIR}/src"
PROGRAMS="${BASEDIR}/src/programy"
CONTRIB="${BASEDIR}/contrib"
OUT="${BASEDIR}/out"

echo "BASEDIR=$BASEDIR"
echo "SRC=$SRC"
echo "PROGRAMS=$PROGRAMS"
echo "OUT=$OUT"

rm -Rf "${OUT}"

mkdir "${OUT}"

rm -Rf "${OUT}/*"

cd ${SRC}

nasm -f bin "jadro.asm" -o "${OUT}/jadro111.cor"

nasm -f bin "boot.asm" -o "${OUT}/boot.bin"

cd ${PROGRAMS}

nasm -f bin "dmx.asm" -o "${OUT}/dmx"

cd ${OUT}

dd if=/dev/zero ibs=1024 count=1440 of=floppy.img 

mkfs.msdos floppy.img

mkdir floppy_content

sudo mount -o loop floppy.img floppy_content

cp jadro111.cor floppy_content/
cp dmx floppy_content/

sudo umount floppy_content

dd if=boot.bin of=floppy.img seek=0 count=1 conv=notrunc

cp -n "${CONTRIB}/bochsrc.txt" "${OUT}"

cd $OLDPWD
