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
        --output-file FILE \\
        [--fuzz VALUE] \\
        [--background COLOR] \\
        [--repage]


Arguments:

    --input-file
        Входное изображение.


    --output-file
        Выходное изображение.


    --fuzz
        Порог сравнения цветов.

        Передается напрямую
        в ImageMagick.

        По умолчанию:
            10%


    --background
        Цвет фона страницы.

        Используется при обработке
        прозрачных областей.

        По умолчанию:
            white


    --repage
        Выполнить +repage
        после trim.

        По умолчанию:
            выключено

EOF

  exit 1
}


#
# Значения параметров
# командной строки.
#
INPUT_FILE=""

OUTPUT_FILE=""

FUZZ="10%"

BACKGROUND="white"

REPAGE=false


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


  --fuzz)

    FUZZ="$2"
    shift 2
    ;;


  --background)

    BACKGROUND="$2"
    shift 2
    ;;


  --repage)

    REPAGE=true
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

  echo "Input file not found:" >&2
  echo "    $INPUT_FILE" >&2

  exit 1

fi


#
# Подготовить команду ImageMagick.
#
COMMAND=(

  magick

  "$INPUT_FILE"

  -background
  "$BACKGROUND"

  -fuzz
  "$FUZZ"

  -trim

)


#
# Выполнить +repage,
# если это запрошено.
#
if [[ "$REPAGE" == true ]]
then

  COMMAND+=(

    +repage

  )

fi


#
# Добавить выходной файл.
#
COMMAND+=(

  "$OUTPUT_FILE"

)


#
# Выполнить ImageMagick.
#
"${COMMAND[@]}"


echo
echo "========================================"
echo "Crop completed successfully"
echo "========================================"
echo