#!/bin/bash

set -euo pipefail


#
# Значения параметров по умолчанию.
#
DESKEW_SCAN_RANGE="5.0"
DESKEW_SCAN_STEP="0.1"
INTERPOLATION="cubic"
VERBOSE=false


usage()
{
  cat << EOF
Usage:

    process-unpaper.sh
        --input-file FILE
        --output-file FILE
        [--deskew-scan-range DEG]
        [--deskew-scan-step DEG]
        [--interpolate nearest|linear|cubic]
        [--verbose]

Description:

    Выполнить автоматическое исправление
    небольшого наклона изображения
    с использованием unpaper.

EOF
}


#
# Разобрать аргументы командной строки.
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

  --deskew-scan-range)
    DESKEW_SCAN_RANGE="$2"
    shift 2
    ;;

  --deskew-scan-step)
    DESKEW_SCAN_STEP="$2"
    shift 2
    ;;

  --interpolate)
    INTERPOLATION="$2"
    shift 2
    ;;

  --verbose)
    VERBOSE=true
    shift
    ;;

  -h|--help)
    usage
    exit 0
    ;;

  *)
    echo "Unknown argument: $1" >&2
    exit 1
    ;;

  esac
done


#
# Проверить обязательные параметры.
#
: "${INPUT_FILE:?--input-file is required}"
: "${OUTPUT_FILE:?--output-file is required}"


#
# Проверить существование входного файла.
#
if [[ ! -f "$INPUT_FILE" ]]
then
  echo "Input file does not exist:"
  echo "    $INPUT_FILE"
  exit 1
fi


#
# Создать каталог назначения.
#
mkdir -p "$(dirname "$OUTPUT_FILE")"


echo
echo "========================================"
echo "Deskew (unpaper)"
echo "========================================"
echo
echo "Input file:"
echo "    $INPUT_FILE"
echo
echo "Output file:"
echo "    $OUTPUT_FILE"
echo
echo "Deskew parameters:"
echo "    range         = $DESKEW_SCAN_RANGE deg"
echo "    step          = $DESKEW_SCAN_STEP deg"
echo "    interpolation = $INTERPOLATION"
echo


#
# Сформировать командную строку.
#
COMMAND=(
  unpaper
  --overwrite
  --layout single
  --deskew-scan-range "$DESKEW_SCAN_RANGE"
  --deskew-scan-step "$DESKEW_SCAN_STEP"
  --interpolate "$INTERPOLATION"
)


#
# При необходимости включить
# подробный вывод unpaper.
#
if $VERBOSE
then
  COMMAND+=(
    --verbose
  )
fi


#
# Добавить входной
# и выходной файлы.
#
COMMAND+=(
  "$INPUT_FILE"
  "$OUTPUT_FILE"
)


echo "Executing:"
echo

printf '    %q' "${COMMAND[@]}"
echo
echo


#
# Выполнить deskew.
#
"${COMMAND[@]}"


echo
echo "========================================"
echo "Deskew completed successfully"
echo "========================================"