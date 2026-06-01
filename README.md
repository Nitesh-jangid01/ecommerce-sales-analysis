# Ecommerce Sales Analysis
### Tools: MySQL · Excel · Power BI

## Project overview
End-to-end analysis of 3,000+ ecommerce orders across 10 Indian cities, 
covering revenue trends, customer segmentation, cohort retention, 
and 3-month revenue forecasting.

## Key findings
- Electronics was the highest-revenue category (₹85,19,210.70), contributing 
  39.32% of total revenue
- RFM segmentation identified 92 Champions customers generating 28.48% of revenue
- 3-month moving average forecast projects 5,23,299.73 revenue for next quarter

## Files in this repository
| File | Description |
|------|-------------|
| data/customers.csv | 500 customer records |
| data/orders.csv | 3,000 orders (Jan 2022 – Dec 2023) |
| data/order_items.csv | 7,400+ line items |
| sql/ecommerce_sql_analysis.sql | 13 SQL scripts (KPIs, RFM, cohort, CLV) |
| excel/Ecommerce_Sales_Analysis.xlsx | 8-sheet Excel workbook |
| screenshots/ | Power BI dashboard screenshots |

## Dashboard screenshots
![Overview](<img width="1435" height="806" alt="Overview_dashboard" src="https://github.com/user-attachments/assets/b1a90f5a-4ee9-47d9-a17d-bdb440bfa3b0" />
)
![RFM Segmentation](<img width="745" height="695" alt="RFM_segmentation" src="https://github.com/user-attachments/assets/9c1df33e-4c20-4ff2-b711-09052ac17302" />
)
![Cohort Analysis](<img width="1583" height="756" alt="Cohort_heatmap" src="https://github.com/user-attachments/assets/557b71ff-1837-4a5a-b826-dbbfe4329fb4" />
)
![Revenue Forecast](<img width="1432" height="797" alt="Revenue_forcasting" src="https://github.com/user-attachments/assets/a7279436-07ca-4164-ac3d-bd99960146b5" />
)

## SQL techniques used
- CTEs, Window Functions (RANK, LAG, NTILE)
- Subqueries and JOINs across 4 tables
- RFM scoring with NTILE(5) segmentation
- Cohort analysis using PERIOD_DIFF
- Customer Lifetime Value calculation

## How to run
1. Import the 4 CSV files into MySQL using Table Data Import Wizard
2. Run scripts in ecommerce_sql_analysis.sql in order.
3. Connect Power BI to the Excel file for interactive dashboards
