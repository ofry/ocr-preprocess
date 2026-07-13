#!/bin/bash

set -euo pipefail


#
# Значения параметров по умолчанию.
#
DEFAULT_THRESHOLD="40%"
DEFAULT_BACKGROUND="white"


show_usage() {
  cat <<'EOF'
Usage:

    process-imagemagick.sh \
        --input-file <file> \
        --output-file <file> \
        [--threshold <value>] \
        [--background <color>]

Arguments:

    --input-file
        Входное изображение.

    --output-file
        Выходное изображение.

    --threshold
        Порог алгоритма ImageMagick.
        По умолчанию: 40%

    --background
        Цвет заполнения после поворота.
        По умолчанию: white

EOF
}


#
# Значения аргументов командной строки.
#
INPUT_FILE=""
OUTPUT_FILE=""
THRESHOLD="$DEFAULT_THRESHOLD"
BACKGROUND="$DEFAULT_BACKGROUND"


#
# Разбор аргументов командной строки.
#
while [[ $# -gt 0 ]]; do

  case "$1" in

  --input-file)
    INPUT_FILE="$2"
    shift 2
    ;;

  --output-file)
    OUTPUT_FILE="$2"
    shift 2
    ;;

  --threshold)
    THRESHOLD="$2"
    shift 2
    ;;

  --background)
    BACKGROUND="$2"
    shift 2
    ;;

  -h|--help)
    show_usage
    exit 0
    ;;

  *)
    echo "Unknown argument: $1" >&2
    echo >&2
    show_usage
    exit 1
    ;;

  esac

done


#
# Проверить обязательные параметры.
#
if [[ -z "$INPUT_FILE" ]]; then
  echo "ERROR: --input-file is required." >&2
  exit 1
fi

if [[ -z "$OUTPUT_FILE" ]]; then
  echo "ERROR: --output-file is required." >&2
  exit 1
fi


#
# Проверить существование входного файла.
#
if [[ ! -f "$INPUT_FILE" ]]; then
  echo "ERROR: Input file does not exist:" >&2
  echo "    $INPUT_FILE" >&2
  exit 1
fi


#
# Проверить наличие ImageMagick.
#
if ! command -v magick >/dev/null 2>&1; then
  echo "ERROR: ImageMagick (magick) not found." >&2
  exit 1
fi


#
# Создать каталог назначения.
#
mkdir -p "$(dirname "$OUTPUT_FILE")"


echo
echo "========================================"
echo "Deskew started"
echo "========================================"
echo
echo "Input file:"
echo "    $INPUT_FILE"
echo
echo "Output file:"
echo "    $OUTPUT_FILE"
echo
echo "Threshold:"
echo "    $THRESHOLD"
echo
echo "Background:"
echo "    $BACKGROUND"
echo
echo "Running ImageMagick..."
echo


#
# Выполнить автоматическое исправление наклона.
#
magick \
  "$INPUT_FILE" \
  -background "$BACKGROUND" \
  -deskew "$THRESHOLD" \
  "$OUTPUT_FILE"


#
# Проверить успешность обработки.
#
if [[ ! -f "$OUTPUT_FILE" ]]; then
  echo "ERROR: Output file was not created." >&2
  exit 1
fi

if [[ ! -s "$OUTPUT_FILE" ]]; then
  echo "ERROR: Output file is empty." >&2
  exit 1
fi


echo
echo "========================================"
echo "Deskew completed successfully"
echo "========================================"
echo