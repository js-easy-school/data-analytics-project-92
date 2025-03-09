-- Подсчёт общего количества покупателей в таблице customers
SELECT COUNT(*) AS customers_count
FROM customers;

-- Отчет 1: Топ-10 продавцов по суммарной выручке
SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS seller, -- Шаг 4: Выбираем полное имя продавца
    COUNT(s.sales_id) AS operations, -- Шаг 4: Выбираем количество сделок
    ROUND(SUM(p.price * s.quantity)) AS income -- Шаг 4: Выбираем общую выручку
FROM sales s -- Шаг 1: Основная таблица продаж
JOIN employees e ON s.sales_person_id = e.employee_id -- Шаг 1: Соединяем с таблицей сотрудников
JOIN products p ON s.product_id = p.product_id -- Шаг 1: Соединяем с таблицей товаров
GROUP BY e.first_name, e.last_name -- Шаг 2: Группируем по продавцам
ORDER BY income DESC -- Шаг 3: Сортируем по выручке (от большего к меньшему)
LIMIT 10; -- Шаг 5: Ограничиваем результат 10 записями

-- Отчет 2: Продавцы со средней выручкой ниже общей средней
WITH overall_avg AS ( -- Шаг 1: Создаем временную таблицу с общей средней выручкой
    SELECT AVG(p.price * s.quantity) AS avg_income
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
)
SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS seller, -- Шаг 4: Выбираем полное имя продавца
    ROUND(AVG(p.price * s.quantity)) AS average_income -- Шаг 4: Выбираем среднюю выручку
FROM sales s -- Шаг 2: Основная таблица продаж
JOIN employees e ON s.sales_person_id = e.employee_id -- Шаг 2: Соединяем с таблицей сотрудников
JOIN products p ON s.product_id = p.product_id -- Шаг 2: Соединяем с таблицей товаров
GROUP BY e.first_name, e.last_name -- Шаг 3: Группируем по продавцам
HAVING AVG(p.price * s.quantity) < (SELECT avg_income FROM overall_avg) -- Шаг 5: Фильтруем по средней выручке
ORDER BY average_income ASC; -- Шаг 6: Сортируем по средней выручке (по возрастанию)

-- Отчет 3: Выручка по дням недели для каждого продавца
SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS seller, -- Шаг 4: Выбираем полное имя продавца
    LOWER(TRIM(TO_CHAR(s.sale_date, 'Day'))) AS day_of_week, -- Шаг 4: Выбираем день недели
    ROUND(SUM(p.price * s.quantity)) AS income -- Шаг 4: Выбираем выручку
FROM sales s -- Шаг 1: Основная таблица продаж
JOIN employees e ON s.sales_person_id = e.employee_id -- Шаг 1: Соединяем с таблицей сотрудников
JOIN products p ON s.product_id = p.product_id -- Шаг 1: Соединяем с таблицей товаров
GROUP BY 
    e.first_name, -- Шаг 2: Группируем по имени продавца
    e.last_name, -- Шаг 2: Группируем по фамилии продавца
    LOWER(TRIM(TO_CHAR(s.sale_date, 'Day'))), -- Шаг 2: Группируем по дню недели
    EXTRACT(ISODOW FROM s.sale_date) -- Шаг 2: Группируем по порядковому номеру дня недели
ORDER BY EXTRACT(ISODOW FROM s.sale_date), seller; -- Шаг 3: Сортируем по дню недели и продавцу

-- Отчет 1: Количество покупателей в разных возрастных группах
SELECT 
    CASE 
        WHEN c.age BETWEEN 16 AND 25 THEN '16-25'
        WHEN c.age BETWEEN 26 AND 40 THEN '26-40'
        ELSE '40+'
    END AS age_category,
    COUNT(DISTINCT c.customer_id) AS age_count
FROM customers c
GROUP BY age_category
ORDER BY age_category;

-- Отчет 2: Количество покупателей и выручка по месяцам
SELECT 
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    ROUND(SUM(p.price * s.quantity)) AS income
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY selling_month
ORDER BY selling_month;

-- Отчет 3: Покупатели, первая покупка которых была акционной (цена = 0)
WITH first_purchases AS (
    SELECT 
        s.customer_id,
        MIN(s.sale_date) AS first_sale_date
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    WHERE p.price = 0
    GROUP BY s.customer_id
)
SELECT 
    CONCAT(c.first_name, ' ', c.last_name) AS customer,
    fp.first_sale_date AS sale_date,
    CONCAT(e.first_name, ' ', e.last_name) AS seller
FROM first_purchases fp
JOIN sales s ON fp.customer_id = s.customer_id AND fp.first_sale_date = s.sale_date
JOIN customers c ON fp.customer_id = c.customer_id
JOIN employees e ON s.sales_person_id = e.employee_id
ORDER BY c.customer_id;
