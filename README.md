# OCR Preprocess

Набор независимых утилит для предварительной обработки изображений документов перед OCR.

Каждая операция реализована как отдельный wrapper (`*-file.sh`), который самостоятельно читает свой INI-файл, извлекает необходимые параметры и вызывает соответствующую реализацию алгоритма.

Все wrapper имеют одинаковый API.

---

# Общая идея

Каждая операция обработки является полностью самостоятельной.

Wrapper:

* принимает путь ко входному изображению;
* принимает путь к выходному изображению;
* принимает путь к собственному INI-файлу;
* самостоятельно читает настройки;
* самостоятельно вызывает внутреннюю реализацию алгоритма.

Внешнему коду не требуется знать внутренние параметры отдельных алгоритмов.

Единственная обязанность внешнего кода — выбрать нужный INI-файл и вызвать соответствующий wrapper.

---

# Единый API всех wrapper

Все wrapper используют одинаковый интерфейс командной строки.

```
--input-file FILE

--output-file FILE

--settings-file FILE
```

где

* `--input-file` — входное изображение;
* `--output-file` — выходное изображение;
* `--settings-file` — INI-файл с параметрами конкретной операции.

---

# Соответствие wrapper и INI-файлов

| Операция | Wrapper | Конфигурация |
|----------|---------|--------------|
| Orientation | `orient/orient-file.sh` | `config/orient-config.ini` |
| Deskew | `deskew/deskew-file.sh` | `config/deskew-config.ini` |
| Crop | `crop/crop-file.sh` | `config/crop-config.ini` |
| Background normalization | `background-normalization/background-normalize-file.sh` | `config/background-normalization-config.ini` |
| Binarization | `binarization/binarize-file.sh` | `config/binarization-config.ini` |
| Despeckle | `despeckle/despeckle-file.sh` | `config/despeckle-config.ini` |

---

# Структура проекта

```
orient/
deskew/
crop/
background-normalization/
binarization/
despeckle/

config/
```

Каждый каталог содержит реализацию только одной операции.

Каталог `config/` содержит соответствующие INI-файлы.

---

# Внутренняя структура операций

Каждая операция может использовать одну или несколько реализаций.

Например

```
crop/

    crop-file.sh

    process-imagemagick.sh

    process-unpaper.sh
```

или

```
despeckle/

    despeckle-file.sh

    process-opencv.py
```

Wrapper самостоятельно выбирает реализацию согласно

```
[general]

algorithm = ...
```

в соответствующем INI-файле.

Внешний код не должен знать, какие внутренние реализации существуют.

---

# Примеры запуска

## Orientation

```bash
orient/orient-file.sh \
    --input-file input.png \
    --output-file output.png \
    --settings-file config/orient-config.ini
```

---

## Deskew

```bash
deskew/deskew-file.sh \
    --input-file input.png \
    --output-file output.png \
    --settings-file config/deskew-config.ini
```

---

## Crop

```bash
crop/crop-file.sh \
    --input-file input.png \
    --output-file output.png \
    --settings-file config/crop-config.ini
```

---

## Background normalization

```bash
background-normalization/background-normalize-file.sh \
    --input-file input.png \
    --output-file output.png \
    --settings-file config/background-normalization-config.ini
```

---

## Binarization

```bash
binarization/binarize-file.sh \
    --input-file input.png \
    --output-file output.png \
    --settings-file config/binarization-config.ini
```

---

## Despeckle

```bash
despeckle/despeckle-file.sh \
    --input-file input.png \
    --output-file output.png \
    --settings-file config/despeckle-config.ini
```

---

# Архитектурное правило

Wrapper являются публичным API проекта.

Файлы

```
process-*.py
process-*.sh
```

являются внутренними реализациями.

Внешние программы не должны вызывать их напрямую.

Все вызовы должны выполняться исключительно через соответствующие wrapper.

---

На текущий момент каждая операция реализована как независимый модуль с единым внешним API.