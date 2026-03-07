---
## Front matter
title: "Методы математического моделирования в кибербезопасности"
subtitle: "Отчёт по лабораторной работе №1"
author: "Ахлиддинзода Аслиддин"

## Generic otions
lang: ru-RU
toc-title: "Содержание"

## Bibliography
bibliography: bib/cite.bib
csl: pandoc/csl/gost-r-7-0-5-2008-numeric.csl

## Pdf output format
toc: true # Table of contents
toc-depth: 2
lof: true # List of figures
lot: true # List of tables
fontsize: 12pt
linestretch: 1.5
papersize: a4
documentclass: scrreprt
## I18n polyglossia
polyglossia-lang:
  name: russian
  options:
  - spelling=modern
  - babelshorthands=true
polyglossia-otherlangs:
  name: english
## I18n babel
babel-lang: russian
babel-otherlangs: english
## Fonts
mainfont: PT Serif
romanfont: PT Serif
sansfont: PT Sans
monofont: PT Mono
mainfontoptions: Ligatures=TeX
romanfontoptions: Ligatures=TeX
sansfontoptions: Ligatures=TeX,Scale=MatchLowercase
monofontoptions: Scale=MatchLowercase,Scale=0.9
## Biblatex
biblatex: true
biblio-style: "gost-numeric"
biblatexoptions:
  - parentracker=true
  - backend=biber
  - hyperref=auto
  - language=auto
  - autolang=other*
  - citestyle=gost-numeric
## Pandoc-crossref LaTeX customization
figureTitle: "Рис."
tableTitle: "Таблица"
listingTitle: "Листинг"
lolTitle: "Листинги"
## Misc options
indent: true
header-includes:
  - \usepackage{indentfirst}
  - \usepackage{float} # keep figures where there are in the text
  - \floatplacement{figure}{H} # keep figures where there are in the text
---
# Цель работы

Основная цель работы — подготовить рабочее пространство и инструментарий для
работы с языком программирования Julia. Научиться формализировать, выбирать метод решения, алгоритмы, реализация на компьютере и анализ полученных результатов.

# Выполнение лабораторной работы

## Реализация экспоненциального роста

Экспоненциальный рост - идеализированная модель. В реальности он не может продолжаться бесконечно из-за ограниченности ресурсов. После некоторого времени рост обычно замедляется и переходи в логистический рост.
![Пример](image_1.PNG)

## Литературная реализация экспоненциального роста

Литературное программирование - это подход, приоритизирующий понятность программы для человека, а не ее исполнение компьютером. В экосистеме Julia он реализуется через несколько инструментов.
![Пример](image_2.PNG)

## Реализация модели с параметрами

Исследование не ограничивается одним значением параметров. Изменим программу так, чтобы она принимала набор параметров

# Вывод

Подготовил рабочее пространство и инструментарий для
работы с языком программирования Julia. Научился формализировать, выбирать метод решения, алгоритмы, реализация на компьютере и анализ полученных результатов.