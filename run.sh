OLDPWD=$(pwd)
BASEDIR=$( cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd )
OUT="${BASEDIR}/out"

echo "OUT=$OUT"

cd $OUT

bochs -f bochsrc.txt

cd $OLDPWD
