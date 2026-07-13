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
        исправления наклона.
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
[[ -n "$INPUT_FILE"    ]] || usage
[[ -n "$OUTPUT_FILE"   ]] || usage
[[ -n "$SETTINGS_FILE" ]] || usage


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
echo "Deskew started"
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


case "$ALGORITHM" in

imagemagick)

#
# Прочитать параметры ImageMagick.
#
  THRESHOLD="$(
    crudini \
      --get \
      "$SETTINGS_FILE" \
      imagemagick \
      threshold
  )"

  BACKGROUND="$(
    crudini \
      --get \
      "$SETTINGS_FILE" \
      imagemagick \
      background
  )"

  echo
  echo "ImageMagick parameters:"
  echo "    threshold = $THRESHOLD"
  echo "    background = $BACKGROUND"

  echo
  echo "Running process-imagemagick.sh..."
  echo

  "$SCRIPT_DIR/process-imagemagick.sh" \
    --input-file "$INPUT_FILE" \
    --output-file "$OUTPUT_FILE" \
    --threshold "$THRESHOLD" \
    --background "$BACKGROUND"

  ;;


unpaper)

#
# Прочитать параметры unpaper.
#
  DESKEW_SCAN_RANGE="$(
    crudini \
      --get \
      "$SETTINGS_FILE" \
      unpaper \
      deskew_scan_range
  )"

  DESKEW_SCAN_STEP="$(
    crudini \
      --get \
      "$SETTINGS_FILE" \
      unpaper \
      deskew_scan_step
  )"

  INTERPOLATION="$(
    crudini \
      --get \
      "$SETTINGS_FILE" \
      unpaper \
      interpolation
  )"

  VERBOSE="$(
    crudini \
      --get \
      "$SETTINGS_FILE" \
      unpaper \
      verbose
  )"

  echo
  echo "unpaper parameters:"
  echo "    deskew_scan_range = $DESKEW_SCAN_RANGE"
  echo "    deskew_scan_step  = $DESKEW_SCAN_STEP"
  echo "    interpolation     = $INTERPOLATION"
  echo "    verbose           = $VERBOSE"

  echo
  echo "Running process-unpaper.sh..."
  echo

  COMMAND=(
    "$SCRIPT_DIR/process-unpaper.sh"
    --input-file "$INPUT_FILE"
    --output-file "$OUTPUT_FILE"
    --deskew-scan-range "$DESKEW_SCAN_RANGE"
    --deskew-scan-step "$DESKEW_SCAN_STEP"
    --interpolate "$INTERPOLATION"
  )

  #
  # Передать параметр --verbose
  # только при необходимости.
  #
  if [[ "$VERBOSE" == "true" ]]
  then
    COMMAND+=(
      --verbose
    )
  fi

  "${COMMAND[@]}"

  ;;


*)

  echo
  echo "Unsupported algorithm:"
  echo "    $ALGORITHM"
  exit 1
  ;;

esac


echo
echo "========================================"
echo "Deskew completed successfully"
echo "========================================"
echo