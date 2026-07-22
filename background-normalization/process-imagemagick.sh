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
        [--method VALUE] \
        [--contrast-stretch VALUE] \
        [--clahe VALUE]


Arguments:

    --input-file
        Входное изображение.


    --output-file
        Выходное изображение.


    --method
        Метод нормализации.

        Поддерживаемые значения:

            normalize
            auto-level
            contrast-stretch
            clahe

        По умолчанию:

            normalize


    --contrast-stretch
        Значение,
        передаваемое непосредственно
        параметру

            -contrast-stretch

        Используется только при

            --method contrast-stretch

        По умолчанию:

            1%x1%


    --clahe
        Значение,
        передаваемое непосредственно
        параметру

            -clahe

        Используется только при

            --method clahe

        По умолчанию:

            8x8+128+3

EOF

  exit 1
}


#
# Значения параметров
# командной строки.
#
INPUT_FILE=""
OUTPUT_FILE=""

METHOD="normalize"

CONTRAST_STRETCH="1%x1%"

CLAHE="8x8+128+3"


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


  --output-file)

    OUTPUT_FILE="$2"
    shift 2
    ;;


  --method)

    METHOD="$2"
    shift 2
    ;;


  --contrast-stretch)

    CONTRAST_STRETCH="$2"
    shift 2
    ;;


  --clahe)

    CLAHE="$2"
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
[[ -n "$INPUT_FILE"  ]] || usage
[[ -n "$OUTPUT_FILE" ]] || usage


#
# Проверить наличие входного файла.
#
if [[ ! -f "$INPUT_FILE" ]]
then

  echo "Input file not found:"
  echo "    $INPUT_FILE"

  exit 1

fi


#
# Проверить поддерживаемый метод.
#
case "$METHOD" in

normalize|auto-level|contrast-stretch|clahe)

  ;;

*)

  echo "Unsupported method:"
  echo "    $METHOD"

  exit 1

  ;;

esac


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
echo "Method:"
echo "    $METHOD"


#
# Подготовить команду
# ImageMagick.
#
COMMAND=(
  magick
  "$INPUT_FILE"
)


case "$METHOD" in


normalize)

  COMMAND+=(
    -normalize
  )

  ;;


auto-level)

  COMMAND+=(
    -auto-level
  )

  ;;


contrast-stretch)

  echo
  echo "contrast-stretch:"
  echo "    $CONTRAST_STRETCH"

  COMMAND+=(
    -contrast-stretch
    "$CONTRAST_STRETCH"
  )

  ;;


clahe)

  echo
  echo "clahe:"
  echo "    $CLAHE"

  COMMAND+=(
    -clahe
    "$CLAHE"
  )

  ;;

esac


COMMAND+=(
  "$OUTPUT_FILE"
)


echo
echo "Running ImageMagick..."
echo

"${COMMAND[@]}"


echo
echo "========================================"
echo "Background normalization completed successfully"
echo "========================================"
echo