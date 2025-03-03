-- MEMILIH PRIMARY KEY --
ALTER TABLE kimia_farma.kf_product ADD PRIMARY KEY (product_id) NOT ENFORCED;
ALTER TABLE kimia_farma.kf_kantor_cabang ADD PRIMARY KEY (branch_id) NOT ENFORCED;
ALTER TABLE kimia_farma.kf_inventory ADD PRIMARY KEY (Inventory_ID) NOT ENFORCED;
ALTER TABLE kimia_farma.kf_final_transaction ADD PRIMARY KEY (transaction_id) NOT ENFORCED

-- MEMILIH FOREIGN KEY --
ALTER TABLE kimia_farma.kf_inventory ADD FOREIGN KEY (product_id) references kimia_farma.kf_product (product_id) NOT ENFORCED;
ALTER TABLE kimia_farma.kf_inventory ADD FOREIGN KEY (branch_id) references kimia_farma.kf_kantor_cabang (branch_id) NOT ENFORCED;
ALTER TABLE kimia_farma.kf_final_transaction ADD FOREIGN KEY (product_id) references kimia_farma.kf_product (product_id) NOT ENFORCED;
ALTER TABLE kimia_farma.kf_final_transaction ADD FOREIGN KEY (branch_id) references kimia_farma.kf_kantor_cabang (branch_id) NOT ENFORCED

-- MENAMBAHKAN KOLOM persentase_gross_laba --
ALTER TABLE kimia_farma.kf_product ADD COLUMN persentase_gross_laba FLOAT64

-- UPDATE CASE persentase_gross_laba --
UPDATE kimia_farma.kf_product
SET persentase_gross_laba =
  CASE
    WHEN price <= 50000 THEN 0.1
    WHEN price > 50000 AND price <= 100000 THEN 0.15
    WHEN price > 100000 AND price <= 300000 THEN 0.2
    WHEN price > 300000 AND price <= 500000 THEN 0.25
    WHEN price > 500000 THEN 0.3
  END
WHERE price IS NOT NULL;

-- MENAMBAHKAN KOLOM nett_sales --
ALTER TABLE kimia_farma.kf_final_transaction ADD COLUMN nett_sales INT64

-- UPDATE nett_sales --
UPDATE kimia_farma.kf_final_transaction  
SET nett_sales = CAST(price - price * COALESCE(discount_percentage, 0) AS INT64)  
WHERE price IS NOT NULL;

-- Analysis --

--- Perbandingan Pendapatan Kimia Farma dari Tahun ke Tahun ---
SELECT
  EXTRACT(YEAR FROM date) AS year,
  SUM(nett_sales) AS total_nett_sales,
  AVG(nett_sales) AS avg_nett_sales
FROM
  kimia_farma.kf_final_transaction
WHERE
  date IS NOT NULL
GROUP BY
  year
ORDER BY
  year;

--- Produk dan Kategori Top 1 Bulan Juli dan Desember ---
WITH sales_summary AS (
    SELECT 
        EXTRACT(YEAR FROM date) AS year,
        EXTRACT(MONTH FROM date) AS month,
        product_category,
        product_name,
        COUNT(product_id) AS total_sales,
        SUM(gross_laba) AS total_gross_profit
    FROM kimia_farma.kf_transaction_all
    WHERE EXTRACT(MONTH FROM date) IN (2, 12)
    GROUP BY year, month, product_category, product_name
),
ranked_categories AS (
    SELECT *,
        RANK() OVER (PARTITION BY year, month ORDER BY total_sales DESC) AS category_rank
    FROM sales_summary
),
top_products AS (
    SELECT *,
        RANK() OVER (PARTITION BY year, month, product_category ORDER BY total_sales DESC) AS product_rank
    FROM ranked_categories
    WHERE category_rank = 1
)
SELECT year, month, product_category, product_name, total_sales, total_gross_profit
FROM top_products
WHERE product_rank = 1
ORDER BY year ASC, month ASC;

--- Rata-Rata Persentase Diskon Tiap Bulan ---
SELECT 
    EXTRACT(YEAR FROM date) AS year,
    EXTRACT(MONTH FROM date) AS month,
    AVG(discount_percentage) AS avg_discount
FROM kimia_farma.kf_transaction_all
GROUP BY year, month
ORDER BY year ASC, month ASC;


