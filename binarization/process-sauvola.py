#!/usr/bin/env python3

import argparse
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image
from skimage.filters import threshold_sauvola


def parse_arguments() -> argparse.Namespace:
    """
    Разобрать аргументы командной строки.

    Возвращает объект argparse.Namespace,
    содержащий значения всех параметров.
    """

    parser = argparse.ArgumentParser(
        description=(
            "Выполнить бинаризацию изображения "
            "методом Sauvola."
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
    # Размер локального окна.
    #
    parser.add_argument(
        "--window",
        type=int,
        required=True,
        help="Размер локального окна.",
    )

    #
    # Обязательный аргумент.
    #
    # Коэффициент чувствительности.
    #
    parser.add_argument(
        "--k",
        type=float,
        required=True,
        help="Коэффициент чувствительности алгоритма.",
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
        window: int,
        k: float,
) -> Any:
    """
    Выполнить бинаризацию
    методом Sauvola.

    В отличие от метода Otsu,
    алгоритм Sauvola вычисляет
    локальный порог яркости
    отдельно для каждого пикселя.

    Благодаря этому метод хорошо
    работает на документах
    с неравномерным освещением,
    тенями и пожелтевшей бумагой.

    Аргументы:

        window
            Размер локального окна
            в пикселях.

            Чем больше окно,
            тем сильнее учитывается
            окружающая область.

        k
            Коэффициент
            чувствительности алгоритма.

            Чем больше значение k,
            тем агрессивнее
            выполняется бинаризация.
    """

    #
    # Вычислить локальный порог
    # для каждого пикселя.
    #
    threshold = threshold_sauvola(
        image,
        window_size=window,
        k=k,
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
        image=image,
        window=args.window,
        k=args.k,
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