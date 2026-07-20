#!/bin/bash

set -euo pipefail


#
# Каталог, в котором находится данный скрипт.
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
        обрезки изображения.
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
echo "Crop started"
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
  FUZZ="$(
    crudini \
      --get \
      "$SETTINGS_FILE" \
      imagemagick \
      fuzz
  )"

  BACKGROUND="$(
    crudini \
      --get \
      "$SETTINGS_FILE" \
      imagemagick \
      background
  )"

  REPAGE="$(
    crudini \
      --get \
      "$SETTINGS_FILE" \
      imagemagick \
      repage
  )"


  echo
  echo "ImageMagick parameters:"
  echo "    fuzz       = $FUZZ"
  echo "    background = $BACKGROUND"
  echo "    repage     = $REPAGE"

  echo
  echo "Running process-imagemagick.sh..."
  echo


  COMMAND=(
    "$SCRIPT_DIR/process-imagemagick.sh"
    --input-file "$INPUT_FILE"
    --output-file "$OUTPUT_FILE"
    --fuzz "$FUZZ"
    --background "$BACKGROUND"
  )


  #
  # Передать --repage
  # только при необходимости.
  #
  if [[ "$REPAGE" == "true" ]]
  then
    COMMAND+=(
      --repage
    )
  fi


  "${COMMAND[@]}"

  ;;


unpaper)

#
# Прочитать параметры unpaper.
#
  LAYOUT="$(
    crudini \
      --get \
      "$SETTINGS_FILE" \
      unpaper \
      layout
  )"

  BORDER_SCAN_DIRECTION="$(
    crudini \
      --get \
      "$SETTINGS_FILE" \
      unpaper \
      border_scan_direction
  )"

  BORDER_SCAN_SIZE="$(
    crudini \
      --get \
      "$SETTINGS_FILE" \
      unpaper \
      border_scan_size
  )"

  BORDER_SCAN_STEP="$(
    crudini \
      --get \
      "$SETTINGS_FILE" \
      unpaper \
      border_scan_step
  )"

  BORDER_SCAN_THRESHOLD="$(
    crudini \
      --get \
      "$SETTINGS_FILE" \
      unpaper \
      border_scan_threshold
  )"

  NO_BORDER_SCAN="$(
    crudini \
      --get \
      "$SETTINGS_FILE" \
      unpaper \
      no_border_scan
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
  echo "    layout                  = $LAYOUT"
  echo "    border_scan_direction   = $BORDER_SCAN_DIRECTION"
  echo "    border_scan_size        = $BORDER_SCAN_SIZE"
  echo "    border_scan_step        = $BORDER_SCAN_STEP"
  echo "    border_scan_threshold   = $BORDER_SCAN_THRESHOLD"
  echo "    no_border_scan          = $NO_BORDER_SCAN"
  echo "    verbose                 = $VERBOSE"

  echo
  echo "Running process-unpaper.sh..."
  echo


  COMMAND=(
    "$SCRIPT_DIR/process-unpaper.sh"
    --input-file "$INPUT_FILE"
    --output-file "$OUTPUT_FILE"
    --layout "$LAYOUT"
    --border-scan-direction "$BORDER_SCAN_DIRECTION"
    --border-scan-size "$BORDER_SCAN_SIZE"
    --border-scan-step "$BORDER_SCAN_STEP"
    --border-scan-threshold "$BORDER_SCAN_THRESHOLD"
  )


  #
  # Передать --no-border-scan
  # только при необходимости.
  #
  if [[ "$NO_BORDER_SCAN" == "true" ]]
  then
    COMMAND+=(
      --no-border-scan
    )
  fi


  #
  # Передать --verbose
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
echo "Crop completed successfully"
echo "========================================"
echo