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

    $0 \
        --input-file FILE \
        --output-file FILE \
        [--layout VALUE] \
        [--border-scan-direction VALUE] \
        [--border-scan-size VALUE] \
        [--border-scan-step VALUE] \
        [--border-scan-threshold VALUE] \
        [--no-border-scan] \
        [--verbose]


Arguments:

    --input-file
        Входное изображение.

    --output-file
        Выходное изображение.


    --layout

        Макет документа.

        По умолчанию:
            single


    --border-scan-direction

        Направление поиска границ.

        По умолчанию:
            v


    --border-scan-size

        Размер области поиска границы.

        По умолчанию:
            5,5


    --border-scan-step

        Шаг поиска границы.

        По умолчанию:
            5,5


    --border-scan-threshold

        Порог обнаружения границы.

        По умолчанию:
            5


    --no-border-scan

        Не выполнять поиск границ.


    --verbose

        Включить подробный вывод unpaper.

EOF

  exit 1
}


INPUT_FILE=""
OUTPUT_FILE=""

LAYOUT="single"

BORDER_SCAN_DIRECTION="v"
BORDER_SCAN_SIZE="5,5"
BORDER_SCAN_STEP="5,5"
BORDER_SCAN_THRESHOLD="5"

NO_BORDER_SCAN=false
VERBOSE=false


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

  --layout)

    LAYOUT="$2"
    shift 2
    ;;

  --border-scan-direction)

    BORDER_SCAN_DIRECTION="$2"
    shift 2
    ;;

  --border-scan-size)

    BORDER_SCAN_SIZE="$2"
    shift 2
    ;;

  --border-scan-step)

    BORDER_SCAN_STEP="$2"
    shift 2
    ;;

  --border-scan-threshold)

    BORDER_SCAN_THRESHOLD="$2"
    shift 2
    ;;

  --no-border-scan)

    NO_BORDER_SCAN=true
    shift
    ;;

  --verbose)

    VERBOSE=true
    shift
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


[[ -n "$INPUT_FILE"  ]] || usage
[[ -n "$OUTPUT_FILE" ]] || usage


[[ -f "$INPUT_FILE" ]] || {
  echo "Input file not found:"
  echo "    $INPUT_FILE"
  exit 1
}


UNPAPER_ARGS=(
  --layout "$LAYOUT"

  --border-scan-direction "$BORDER_SCAN_DIRECTION"
  --border-scan-size "$BORDER_SCAN_SIZE"
  --border-scan-step "$BORDER_SCAN_STEP"
  --border-scan-threshold "$BORDER_SCAN_THRESHOLD"
)


if $NO_BORDER_SCAN
then
  UNPAPER_ARGS+=(
    --no-border-scan
  )
fi


if $VERBOSE
then
  UNPAPER_ARGS+=(
    --verbose
  )
fi


UNPAPER_ARGS+=(
  "$INPUT_FILE"
  "$OUTPUT_FILE"
)


exec unpaper "${UNPAPER_ARGS[@]}"