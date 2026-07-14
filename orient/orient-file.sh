#!/bin/bash

set -euo pipefail


#
# Каталог, в котором находится данный скрипт.
#
# Это позволяет запускать wrapper
# из любого текущего каталога.
#
SCRIPT_DIR="$(
  cd "$(dirname "$0")"
  pwd
)"


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
        --output-file FILE \\
        --settings-file FILE


Arguments:


    --input-file

        Входное изображение.


    --output-file

        Выходное изображение.


    --settings-file

        INI-файл с параметрами
        определения ориентации.

EOF

  exit 1
}


#
# Переменные,
# которые будут заполнены
# после разбора командной строки.
#
INPUT_FILE=""
OUTPUT_FILE=""
SETTINGS_FILE=""


#
# Разобрать командную строку.
#
while [[ $# -gt 0 ]]
do
  case "$1" in


  --input-file)

    INPUT_FILE="$2"
    shift 2
    ;;


  --output-file)

    OUTPUT_FILE="$2"
    shift 2
    ;;


  --settings-file)

    SETTINGS_FILE="$2"
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
[[ -n "$INPUT_FILE" ]] ||
  usage

[[ -n "$OUTPUT_FILE" ]] ||
  usage

[[ -n "$SETTINGS_FILE" ]] ||
  usage


#
# Проверить существование файлов.
#
[[ -f "$INPUT_FILE" ]] || {

  echo "Input file not found:"
  echo "    $INPUT_FILE"

  exit 1

}


[[ -f "$SETTINGS_FILE" ]] || {

  echo "Settings file not found:"
  echo "    $SETTINGS_FILE"

  exit 1

}


echo
echo "========================================"
echo "Orientation detection started"
echo "========================================"
echo


echo "Input file:"
echo "    $INPUT_FILE"


echo
echo "Output file:"
echo "    $OUTPUT_FILE"


echo
echo "Settings:"
echo "    $SETTINGS_FILE"



#
# Прочитать название алгоритма.
#
ALGORITHM="$(
  crudini \
    --get \
    "$SETTINGS_FILE" \
    general \
    algorithm
)"


echo
echo "Algorithm:"
echo "    $ALGORITHM"



#
# Временный файл
# для stdout backend-а.
#
TMP_OUTPUT="$(
  mktemp
)"


cleanup()
{
  rm -f "$TMP_OUTPUT"
}


trap cleanup EXIT



case "$ALGORITHM" in


tesseract)


#
# Прочитать параметры Tesseract.
#

  LANGUAGE="$(
    crudini \
      --get \
      "$SETTINGS_FILE" \
      tesseract \
      language
  )"


  LOGLEVEL="$(
    crudini \
      --get \
      "$SETTINGS_FILE" \
      tesseract \
      loglevel
  )"


  #
  # DPI необязательный.
  #
  DPI=""


  if crudini \
    --get \
    "$SETTINGS_FILE" \
    tesseract \
    dpi \
    >/dev/null 2>&1
  then

    DPI="$(
      crudini \
        --get \
        "$SETTINGS_FILE" \
        tesseract \
        dpi
    )"

  fi



  echo
  echo "Tesseract parameters:"
  echo "    language = $LANGUAGE"
  echo "    loglevel = $LOGLEVEL"


  if [[ -n "$DPI" ]]
  then

    echo "    dpi      = $DPI"

  fi



  echo
  echo "Running process-tesseract.sh..."
  echo



  COMMAND=(

    "$SCRIPT_DIR/process-tesseract.sh"

    --input-file
    "$INPUT_FILE"

    --language
    "$LANGUAGE"

    --loglevel
    "$LOGLEVEL"

  )


  if [[ -n "$DPI" ]]
  then

    COMMAND+=(

      --dpi
      "$DPI"

    )

  fi



  "${COMMAND[@]}" > "$TMP_OUTPUT"



  ;;


*)


  echo
  echo "Unsupported algorithm:"
  echo "    $ALGORITHM"

  exit 1


  ;;

esac



#
# Прочитать стандартизированный stdout.
#
STATUS=""

ROTATE=""



while IFS= read -r LINE
do

  case "$LINE" in


  STATUS=*)

    STATUS="${LINE#*=}"
    ;;


  ROTATE=*)

    ROTATE="${LINE#*=}"
    ;;


  esac


done < "$TMP_OUTPUT"



#
# Проверить успешность
# определения ориентации.
#
if [[ "$STATUS" != "ok" ]]
then

  echo
  echo "Orientation detection failed"

  exit 1

fi



if [[ -z "$ROTATE" ]]
then

  echo
  echo "Rotation angle not detected"

  exit 1

fi



echo
echo "Detected rotation:"
echo "    $ROTATE"



#
# Если поворот не требуется,
# просто копируем файл.
#
if [[ "$ROTATE" == "0" ]]
then


  echo
  echo "Image already correctly oriented."


  mkdir -p "$(dirname "$OUTPUT_FILE")"


  cp \
    "$INPUT_FILE" \
    "$OUTPUT_FILE"


else


  #
  # Выполнить поворот.
  #
  echo
  echo "Rotating image..."



  mkdir -p "$(dirname "$OUTPUT_FILE")"



  magick \
    "$INPUT_FILE" \
    -rotate "$ROTATE" \
    "$OUTPUT_FILE"


fi



echo
echo "========================================"
echo "Orientation completed successfully"
echo "========================================"
echo