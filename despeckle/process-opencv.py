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
            "Выполнить удаление "
            "шума бинарного изображения "
            "средствами OpenCV."
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
    # Метод удаления шума.
    #
    parser.add_argument(
        "--method",
        choices=[
            "morphology",
            "connected-components",
        ],
        default="connected-components",
        help=(
            "Метод удаления шума "
            "(по умолчанию: "
            "connected-components)."
        ),
    )

    #
    # Морфологическая операция.
    #
    parser.add_argument(
        "--operation",
        choices=[
            "opening",
            "closing",
            "erosion",
            "dilation",
        ],
        default="opening",
        help=(
            "Тип морфологической "
            "операции."
        ),
    )

    #
    # Размер ядра.
    #
    parser.add_argument(
        "--kernel-size",
        default="3x3",
        help=(
            "Размер ядра "
            "в формате "
            "WIDTHxHEIGHT."
        ),
    )

    #
    # Количество итераций.
    #
    parser.add_argument(
        "--iterations",
        type=int,
        default=1,
        help=(
            "Количество итераций "
            "морфологической "
            "операции."
        ),
    )

    #
    # Минимальная площадь
    # компоненты.
    #
    parser.add_argument(
        "--min-area",
        type=int,
        default=8,
        help=(
            "Минимальная площадь "
            "связной компоненты."
        ),
    )

    args = parser.parse_args()

    if args.iterations < 1:

        parser.error(
            "--iterations "
            "must be positive."
        )

    if args.min_area < 1:

        parser.error(
            "--min-area "
            "must be positive."
        )

    return args


def parse_kernel_size(
        value: str,
) -> tuple[int, int]:
    """
    Разобрать строку

        WIDTHxHEIGHT

    в кортеж целых чисел.
    """

    try:

        width, height = (
            value.lower().split("x")
        )

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
            f"Cannot open image: "
            f"{filename}"
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
            f"Cannot save image: "
            f"{filename}"
        )

def process_morphology(
        image: np.ndarray,
        operation: str,
        kernel_size: str,
        iterations: int,
) -> np.ndarray:
    """
    Удалить шум посредством
    морфологических операций.
    """

    kernel = cv2.getStructuringElement(
        cv2.MORPH_RECT,
        parse_kernel_size(kernel_size),
    )

    operation_map = {
        "opening": cv2.MORPH_OPEN,
        "closing": cv2.MORPH_CLOSE,
        "erosion": cv2.MORPH_ERODE,
        "dilation": cv2.MORPH_DILATE,
    }

    if operation in (
            "erosion",
            "dilation",
    ):

        if operation == "erosion":

            return cv2.erode(
                image,
                kernel,
                iterations=iterations,
            )

        return cv2.dilate(
            image,
            kernel,
            iterations=iterations,
        )

    return cv2.morphologyEx(
        image,
        operation_map[operation],
        kernel,
        iterations=iterations,
    )

def process_connected_components(
        image: np.ndarray,
        min_area: int,
) -> np.ndarray:
    """
    Удалить мелкие компоненты
    связности.

    Предполагается, что

        фон = 255
        текст = 0
    """

    #
    # connectedComponentsWithStats()
    # рассматривает ненулевые пиксели
    # как объекты.
    #
    # Поэтому инвертируем изображение,
    # чтобы текст стал белым.
    #
    inverted = cv2.bitwise_not(
        image
    )

    (
        _,
        labels,
        stats,
        _,
    ) = cv2.connectedComponentsWithStats(
        inverted,
        connectivity=8,
        ltype=cv2.CV_32S,
    )

    result = np.zeros_like(
        inverted
    )

    #
    # Метка 0 — фон.
    #
    for label in range(
            1,
            stats.shape[0],
    ):

        area = stats[
            label,
            cv2.CC_STAT_AREA,
        ]

        if area >= min_area:

            result[
                labels == label
                ] = 255

    #
    # Вернуть исходную полярность:
    #
    # фон = белый,
    # текст = черный.
    #
    return cv2.bitwise_not(
        result
    )

def process_image(
        image: np.ndarray,
        method: str,
        operation: str,
        kernel_size: str,
        iterations: int,
        min_area: int,
) -> np.ndarray:
    """
    Выполнить удаление шума
    выбранным методом.
    """

    if method == "morphology":

        return process_morphology(
            image=image,
            operation=operation,
            kernel_size=kernel_size,
            iterations=iterations,
        )

    if method == (
            "connected-components"
    ):

        return process_connected_components(
            image=image,
            min_area=min_area,
        )

    raise RuntimeError(
        f"Unsupported method: "
        f"{method}"
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
        operation=args.operation,
        kernel_size=args.kernel_size,
        iterations=args.iterations,
        min_area=args.min_area,
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

