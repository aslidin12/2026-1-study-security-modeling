# generate_all_reports.jl - Генерация форматов из литературных файлов

using DrWatson
@quickactivate "project"

using Literate
using Dates

println("="^60)
println("ГЕНЕРАЦИЯ ФОРМАТОВ ИЗ ЛИТЕРАТУРНОГО КОДА")
println("="^60)
println("Дата и время: ", now())
println()

# Список всех литературных файлов
literate_files = [
    "src/literate_attack_graph.jl",
    "scripts/literate_ag_run_experiment.jl",
    "scripts/literate_ag_analyze.jl",
    "scripts/literate_ag_convergence.jl",
    "scripts/literate_parameter_sweep.jl",
]

# Проверяем, какие файлы существуют
existing_files = []
for file in literate_files
    if isfile(file)
        push!(existing_files, file)
        println("Найден: $file")
    else
        println("Не найден: $file")
    end
end

println("\n" * "="^60)
println("Найдено файлов: $(length(existing_files)) из $(length(literate_files))")
println("="^60)

if isempty(existing_files)
    println("Нет файлов для обработки! Сначала создайте литературные файлы.")
    exit()
end

# Создаём папку для результатов
output_dir = projectdir("literate_output")
mkpath(output_dir)

println("\n Результаты будут сохранены в: $output_dir\n")

# Обрабатываем каждый файл
for source_file in existing_files
    println(" Обработка: $source_file")
    
    # Получаем имя файла без расширения
    base_name = splitext(basename(source_file))[1]
    
    # Определяем подпапку в зависимости от исходной папки
    if startswith(source_file, "src/")
        subfolder = "src"
    else
        subfolder = "scripts"
    end
    
    # --- 1. Генерация чистого кода ---
    clean_dir = joinpath(output_dir, subfolder, "clean")
    mkpath(clean_dir)
    Literate.script(source_file, clean_dir; credit=false, name=base_name)
    println(" Чистый код: $clean_dir/$base_name.jl")
    
    # --- 2. Генерация Jupyter Notebook ---
    notebook_dir = joinpath(output_dir, "notebooks", base_name)
    mkpath(notebook_dir)
    Literate.notebook(source_file, notebook_dir; credit=false, name=base_name, execute=false)
    println(" Jupyter Notebook: $notebook_dir/$base_name.ipynb")
    
    # --- 3. Генерация Quarto документа ---
    quarto_dir = joinpath(output_dir, "markdown", base_name)
    mkpath(quarto_dir)
    Literate.markdown(source_file, quarto_dir; flavor=Literate.QuartoFlavor(), name=base_name, credit=false)
    println(" Quarto документ: $quarto_dir/$base_name.qmd")
    
    println()
end

println("="^60)
println("ГЕНЕРАЦИЯ ЗАВЕРШЕНА!")
println("="^60)
println("\n Результаты находятся в папке: $output_dir")
println("\nСтруктура:")
println("  literate_output/")
println("  ├── src/clean/           - чистый код модуля")
println("  ├── scripts/clean/       - чистый код скриптов")
println("  ├── notebooks/           - Jupyter notebooks (открыть в браузере)")
println("  └── markdown/            - Quarto документы (для отчёта)")