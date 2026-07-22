#!/usr/bin/env python3

import argparse
from pathlib import Path

import cv2
import numpy as np


def parse_arguments() -> argparse.Namespace:
    """
    Разобрать аргументы
    командной строки.

    Возвращает объект argparse.Namespace,
    содержащий значения всех параметров.
    """

    parser = argparse.ArgumentParser(
        description=(
            "Выполнить нормализацию "
            "фона изображения средствами OpenCV."
        )
    )

    #
    # Входной файл.
    #
    parser.add_argument(
        "--input-file",
        type=Path,
        required=True,
        help="Входное изображение.",
    )

    #
    # Выходной файл.
    #
    parser.add_argument(
        "--output-file",
        type=Path,
        required=True,
        help="Выходное изображение.",
    )

    #
    # Метод обработки.
    #
    parser.add_argument(
        "--method",
        choices=[
            "normalize",
            "equalize-hist",
            "clahe",
            "illumination",
        ],
        default="illumination",
        help=(
            "Метод нормализации "
            "(по умолчанию: illumination)."
        ),
    )

    #
    # Clip Limit для CLAHE.
    #
    parser.add_argument(
        "--clip-limit",
        type=float,
        default=2.0,
        help=(
            "Параметр clipLimit "
            "для CLAHE."
        ),
    )

    #
    # Размер сетки CLAHE.
    #
    parser.add_argument(
        "--tile-grid-size",
        default="8x8",
        help=(
            "Размер сетки CLAHE "
            "в формате WIDTHxHEIGHT."
        ),
    )

    #
    # Размер структурного элемента,
    # используемого для оценки
    # фона изображения.
    #
    parser.add_argument(
        "--kernel-size",
        default="31x31",
        help=(
            "Размер ядра морфологической "
            "операции в формате "
            "WIDTHxHEIGHT."
        ),
    )

    return parser.parse_args()

def parse_kernel_size(
        value: str,
) -> tuple[int, int]:
    """
    Разобрать строку

        WIDTHxHEIGHT

    в кортеж целых чисел.
    """

    try:

        width, height = value.lower().split("x")

        width = int(width)
        height = int(height)

    except Exception as exc:

        raise argparse.ArgumentTypeError(
            "Invalid kernel-size. "
            "Expected WIDTHxHEIGHT."
        ) from exc

    if width < 1 or height < 1:

        raise argparse.ArgumentTypeError(
            "Kernel dimensions "
            "must be positive."
        )

    #
    # Для морфологии обычно
    # используются нечетные размеры.
    #
    if width % 2 == 0 or height % 2 == 0:

        raise argparse.ArgumentTypeError(
            "Kernel dimensions "
            "must be odd."
        )

    return (
        width,
        height,
    )

def load_image(
        filename: Path,
) -> np.ndarray:
    """
    Загрузить изображение.

    Независимо от исходного формата
    изображение преобразуется
    в 8-битное изображение
    в оттенках серого.
    """

    image = cv2.imread(
        str(filename),
        cv2.IMREAD_GRAYSCALE,
    )

    if image is None:
        raise RuntimeError(
            f"Cannot open image: {filename}"
        )

    return image


def save_image(
        image: np.ndarray,
        filename: Path,
) -> None:
    """
    Сохранить изображение.

    При необходимости автоматически
    создать каталог назначения.
    """

    filename.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    if not cv2.imwrite(
            str(filename),
            image,
    ):
        raise RuntimeError(
            f"Cannot save image: {filename}"
        )


def parse_tile_grid_size(
        value: str,
) -> tuple[int, int]:
    """
    Разобрать строку

        WIDTHxHEIGHT

    в кортеж целых чисел.
    """

    try:

        width, height = value.lower().split("x")

        return (
            int(width),
            int(height),
        )

    except Exception as exc:

        raise argparse.ArgumentTypeError(
            "Invalid tile-grid-size. "
            "Expected WIDTHxHEIGHT."
        ) from exc


def process_image(
        image: np.ndarray,
        method: str,
        clip_limit: float,
        tile_grid_size: str,
        kernel_size: str,
) -> np.ndarray:
    """
    Выполнить нормализацию
    изображения выбранным методом.
    """

    if method == "normalize":

        return cv2.normalize(
            image,
            None,
            alpha=0,
            beta=255,
            norm_type=cv2.NORM_MINMAX,
        )

    if method == "equalize-hist":

        return cv2.equalizeHist(
            image
        )

    if method == "clahe":

        grid = parse_tile_grid_size(
            tile_grid_size
        )

        clahe = cv2.createCLAHE(
            clipLimit=clip_limit,
            tileGridSize=grid,
        )

        return clahe.apply(
            image
        )

    if method == "illumination":

        kernel = cv2.getStructuringElement(
            cv2.MORPH_RECT,
            parse_kernel_size(kernel_size),
        )

        #
        # Оценить фон документа.
        #
        # Используем морфологическое
        # открытие большим ядром.
        #
        background = cv2.morphologyEx(
            image,
            cv2.MORPH_CLOSE,
            kernel,
        )

        #
        # Перейти к float,
        # чтобы избежать переполнения
        # и обеспечить корректное деление.
        #
        image_f = image.astype(
            np.float32
        )

        background_f = background.astype(
            np.float32
        )

        #
        # Защититься от деления на ноль.
        #
        background_f[
            background_f < 1.0
            ] = 1.0

        #
        # Flat-field correction.
        #
        corrected = cv2.divide(
            image_f,
            background_f,
        )

        #
        # Вернуть диапазон
        # к 8-битному изображению.
        #
        corrected = cv2.normalize(
            corrected,
            None,
            alpha=0,
            beta=255,
            norm_type=cv2.NORM_MINMAX,
            dtype=cv2.CV_8U,
        )

        return corrected

    raise RuntimeError(
        f"Unsupported method: {method}"
    )


def main() -> None:
    """
    Точка входа программы.
    """

    #
    # Разобрать аргументы.
    #
    args = parse_arguments()

    #
    # Загрузить изображение.
    #
    image = load_image(
        args.input_file
    )

    #
    # Выполнить обработку.
    #
    result = process_image(
        image=image,
        method=args.method,
        clip_limit=args.clip_limit,
        tile_grid_size=args.tile_grid_size,
        kernel_size=args.kernel_size,
    )

    #
    # Сохранить результат.
    #
    save_image(
        result,
        args.output_file,
    )

    print("Done.")


#
# Точка входа.
#
if __name__ == "__main__":
    main()