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
        INI-файл с параметрами бинаризации.
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
echo "Binarization started"
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

otsu)

  echo
  echo "Running process-otsu.py..."
  echo

  python3 \
    "$SCRIPT_DIR/process-otsu.py" \
    --input-file "$INPUT_FILE" \
    --output-file "$OUTPUT_FILE"

  ;;


sauvola)

#
# Прочитать параметры Sauvola.
#
  WINDOW="$(
    crudini \
      --get \
      "$SETTINGS_FILE" \
      sauvola \
      window
  )"

  K="$(
    crudini \
      --get \
      "$SETTINGS_FILE" \
      sauvola \
      k
  )"

  echo
  echo "Sauvola parameters:"
  echo "    window = $WINDOW"
  echo "    k      = $K"

  echo
  echo "Running process-sauvola.py..."
  echo

  python3 \
    "$SCRIPT_DIR/process-sauvola.py" \
    --input-file "$INPUT_FILE" \
    --window "$WINDOW" \
    --k "$K" \
    --output-file "$OUTPUT_FILE"

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
echo "Binarization completed successfully"
echo "========================================"
echo