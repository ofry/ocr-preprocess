#!/bin/bash

set -euo pipefail


#
# Вывести справку
# и завершить программу.
#
usage()
{
  cat <<EOF
Usage:

    $0 \\
        --input-file FILE \\
        [--language LANG] \\
        [--dpi VALUE] \\
        [--loglevel LEVEL]


Arguments:

    --input-file
        Входное изображение.


    --language
        Язык для Tesseract OSD.

        По умолчанию:
            osd


    --dpi
        DPI входного изображения.

        Если параметр не указан,
        значение DPI не передается
        в Tesseract.


    --loglevel
        Уровень вывода Tesseract.

        По умолчанию:
            ERROR

EOF

  exit 1
}


#
# Значения параметров
# командной строки.
#
INPUT_FILE=""

LANGUAGE="osd"

DPI=""

LOGLEVEL="ERROR"


#
# Разбор аргументов
# командной строки.
#
while [[ $# -gt 0 ]]
do
  case "$1" in


  --input-file)

    INPUT_FILE="$2"
    shift 2
    ;;


  --language)

    LANGUAGE="$2"
    shift 2
    ;;


  --dpi)

    DPI="$2"
    shift 2
    ;;


  --loglevel)

    LOGLEVEL="$2"
    shift 2
    ;;


  -h|--help)

    usage
    ;;


  *)

    echo "Unknown argument: $1" >&2
    usage
    ;;

  esac
done


#
# Проверить обязательные параметры.
#
[[ -n "$INPUT_FILE" ]] || usage


#
# Проверить наличие входного файла.
#
if [[ ! -f "$INPUT_FILE" ]]
then

  echo "Input file not found:" >&2
  echo "    $INPUT_FILE" >&2

  echo "STATUS=error"

  exit 1

fi


#
# Временный файл
# для вывода Tesseract.
#
TMP_OUTPUT="$(
  mktemp
)"


#
# Гарантированное удаление
# временного файла.
#
cleanup()
{
  rm -f "$TMP_OUTPUT"
}


trap cleanup EXIT


#
# Подготовить параметры
# вызова Tesseract.
#
TESSERACT_ARGS=(

  "$INPUT_FILE"

  stdout

  --psm
  0

  -l
  "$LANGUAGE"

  --loglevel
  "$LOGLEVEL"

)


#
# Добавить DPI только если
# пользователь его указал.
#
if [[ -n "$DPI" ]]
then

  TESSERACT_ARGS+=(
    --dpi
    "$DPI"
  )

fi


#
# Запустить Tesseract.
#
# Весь оригинальный вывод
# сохраняется во временный файл.
#
# При этом stderr Tesseract
# напрямую отправляется
# в stderr wrapper-а.
#
if ! tesseract "${TESSERACT_ARGS[@]}" \
  >"$TMP_OUTPUT"
then

  echo "STATUS=error"

  exit 1

fi


#
# Вывести оригинальный
# вывод Tesseract в stderr.
#
cat "$TMP_OUTPUT" >&2


#
# Извлечь необходимые поля.
#
ORIENTATION=""
ROTATE=""
ORIENTATION_CONFIDENCE=""
SCRIPT=""
SCRIPT_CONFIDENCE=""


while IFS= read -r LINE
do

  case "$LINE" in


  "Orientation in degrees:"*)

    ORIENTATION="${LINE#*: }"
    ;;


  "Rotate:"*)

    ROTATE="${LINE#*: }"
    ;;


  "Orientation confidence:"*)

    ORIENTATION_CONFIDENCE="${LINE#*: }"
    ;;


  "Script:"*)

    SCRIPT="${LINE#*: }"
    ;;


  "Script confidence:"*)

    SCRIPT_CONFIDENCE="${LINE#*: }"
    ;;


  esac

done < "$TMP_OUTPUT"


#
# Проверить,
# удалось ли получить
# минимально необходимые данные.
#
if [[ -z "$ROTATE" ]]
then

  echo "STATUS=error"

  exit 1

fi


#
# Стандартизированный stdout API.
#
echo "STATUS=ok"

echo "ROTATE=$ROTATE"

echo "ORIENTATION=$ORIENTATION"

echo "ORIENTATION_CONFIDENCE=$ORIENTATION_CONFIDENCE"

echo "SCRIPT=$SCRIPT"

echo "SCRIPT_CONFIDENCE=$SCRIPT_CONFIDENCE"