#!/usr/bin/env python3

import argparse
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image
from skimage.filters import threshold_otsu


def parse_arguments() -> argparse.Namespace:
    """
    Разобрать аргументы командной строки.

    Возвращает объект argparse.Namespace,
    содержащий значения всех параметров.
    """

    parser = argparse.ArgumentParser(
        description=(
            "Выполнить бинаризацию изображения "
            "методом Otsu."
        )
    )

    #
    # Обязательный аргумент.
    #
    # Имя входного изображения.
    #
    parser.add_argument(
        "--input-file",
        type=Path,
        required=True,
        help="Входной файл изображения.",
    )

    #
    # Обязательный аргумент.
    #
    # Имя выходного изображения.
    #
    parser.add_argument(
        "--output-file",
        type=Path,
        required=True,
        help="Выходной файл изображения.",
    )

    return parser.parse_args()


def load_image(
        filename: Path,
) -> np.ndarray:
    """
    Загрузить изображение
    и преобразовать его
    в массив NumPy.

    Независимо от исходного формата,
    изображение преобразуется
    в 8-битное изображение
    в оттенках серого.
    """

    return np.array(
        Image.open(filename).convert("L")
    )


def save_image(
        image: np.ndarray,
        filename: Path,
) -> None:
    """
    Сохранить бинарное изображение.

    Перед сохранением автоматически
    создается каталог назначения,
    если он еще не существует.
    """

    #
    # Создать каталог назначения.
    #
    filename.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    #
    # Сохранить изображение.
    #
    Image.fromarray(image).save(
        filename
    )


def process_image(
        image: np.ndarray,
) -> Any:
    """
    Выполнить бинаризацию
    методом Otsu.

    Метод Otsu вычисляет
    один глобальный порог яркости
    для всего изображения.

    Хорошо работает тогда,
    когда фон документа
    достаточно однороден.

    На документах
    с сильной неравномерностью
    освещения обычно уступает
    адаптивным алгоритмам,
    например Sauvola.
    """

    #
    # Вычислить глобальный
    # порог яркости.
    #
    threshold = threshold_otsu(
        image
    )

    #
    # Получить логическую маску.
    #
    # True  -> белый пиксель.
    # False -> черный пиксель.
    #
    binary = image > threshold

    #
    # Преобразовать логическую маску
    # в обычное 8-битное изображение.
    #
    # False ->   0
    # True  -> 255
    #
    return (
            binary.astype(np.uint8)
            * 255
    )


def main() -> None:
    """
    Точка входа программы.
    """

    #
    # Разобрать аргументы
    # командной строки.
    #
    args = parse_arguments()

    #
    # Загрузить изображение.
    #
    image = load_image(
        args.input_file
    )

    #
    # Выполнить бинаризацию.
    #
    binary = process_image(
        image
    )

    #
    # Сохранить результат.
    #
    save_image(
        binary,
        args.output_file,
    )

    print("Done.")


#
# Если файл запущен
# как самостоятельная программа,
# выполнить функцию main().
#
# Если файл импортирован
# как модуль,
# main() автоматически
# вызвана не будет.
#
if __name__ == "__main__":
    main()