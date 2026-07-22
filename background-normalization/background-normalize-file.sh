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

    $0 \
        --input-file FILE \
        --output-file FILE \
        --settings-file FILE

Arguments:

    --input-file
        Входное изображение.

    --output-file
        Выходное изображение.

    --settings-file
        INI-файл с параметрами
        нормализации фона.
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

  -h | --help)

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
[[ -n "$OUTPUT_FILE" ]] || usage
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
echo "Background normalization started"
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
  METHOD="$(
    crudini \
      --get \
      "$SETTINGS_FILE" \
      imagemagick \
      method
  )"

  CONTRAST_STRETCH="$(
    crudini \
      --get \
      "$SETTINGS_FILE" \
      imagemagick \
      contrast_stretch
  )"

  CLAHE="$(
    crudini \
      --get \
      "$SETTINGS_FILE" \
      imagemagick \
      clahe
  )"

  echo
  echo "ImageMagick parameters:"
  echo "    method             = $METHOD"
  echo "    contrast_stretch   = $CONTRAST_STRETCH"
  echo "    clahe              = $CLAHE"

  echo
  echo "Running process-imagemagick.sh..."
  echo

  COMMAND=(
    "$SCRIPT_DIR/process-imagemagick.sh"
    --input-file
    "$INPUT_FILE"
    --output-file
    "$OUTPUT_FILE"
    --method
    "$METHOD"
  )

  #
  # Передать дополнительные параметры
  # только тем методам,
  # которым они действительно нужны.
  #
  case "$METHOD" in

  contrast-stretch)

    COMMAND+=(
      --contrast-stretch
      "$CONTRAST_STRETCH"
    )

    ;;

  clahe)

    COMMAND+=(
      --clahe
      "$CLAHE"
    )

    ;;

  esac

  "${COMMAND[@]}"

  ;;

opencv)

#
# Прочитать параметры OpenCV.
#
  METHOD="$(
    crudini \
      --get \
      "$SETTINGS_FILE" \
      opencv \
      method
  )"

  CLIP_LIMIT="$(
    crudini \
      --get \
      "$SETTINGS_FILE" \
      opencv \
      clip_limit
  )"

  TILE_GRID_SIZE="$(
    crudini \
      --get \
      "$SETTINGS_FILE" \
      opencv \
      tile_grid_size
  )"

  KERNEL_SIZE="$(
    crudini \
      --get \
      "$SETTINGS_FILE" \
      opencv \
      kernel_size
  )"

  echo
  echo "OpenCV parameters:"
  echo "    method          = $METHOD"
  echo "    clip_limit      = $CLIP_LIMIT"
  echo "    tile_grid_size  = $TILE_GRID_SIZE"
  echo "    kernel_size     = $KERNEL_SIZE"

  echo
  echo "Running process-opencv.py..."
  echo

  COMMAND=(
    python3
    "$SCRIPT_DIR/process-opencv.py"
    --input-file
    "$INPUT_FILE"
    --output-file
    "$OUTPUT_FILE"
    --method
    "$METHOD"
  )

  #
  # Передать параметры,
  # относящиеся только
  # к выбранному алгоритму.
  #
  case "$METHOD" in

  clahe)

    COMMAND+=(
      --clip-limit
      "$CLIP_LIMIT"

      --tile-grid-size
      "$TILE_GRID_SIZE"
    )

    ;;

  illumination)

    COMMAND+=(
      --kernel-size
      "$KERNEL_SIZE"
    )

    ;;

  esac

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
echo "Background normalization completed successfully"
echo "========================================"
echo