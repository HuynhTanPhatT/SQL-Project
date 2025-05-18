/*UPDATE [SaleDataProject].[dbo].[Worksheet$]
SET [Sales] = TRY_CAST([Sales] AS float);
ALTER TABLE [SaleDataProject].[dbo].[Worksheet$]
ALTER COLUMN [Sales] float;

UPDATE [SaleDataProject].[dbo].[Worksheet$]
SET [Price Each] = TRY_CAST([Price Each] AS float);
ALTER TABLE [SaleDataProject].[dbo].[Worksheet$]
ALTER COLUMN [Price Each] float;*/

select * 
from dbo.Worksheet;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*a) Với tháng có doanh số cao nhất, bạn hãy tìm ra các khung giờ có tổng số đơn hàng cao hơn số lượng đơn hàng trung bình theo giờ của tháng đó. 
b) Với mỗi Product line, đều có 2 loại khách hàng (Customer Type) mua hàng là Normal, Member. Bạn hãy tìm các Product line có loại khách hàng mua ít đơn hàng nhưng lại có doanh số cao hơn loại khách hàng còn lại.
c) Bạn hãy xây dựng đoạn truy vấn tìm ra tổng doanh số, tổng số đơn hàng theo tháng, tổng doanh số và tổng số đơn hàng của các tháng về trước.*/
WITH MonthlySales AS (
    SELECT
        DATENAME(MONTH, OrderDate) AS Month_Name,
        DATEPART(MONTH, OrderDate) AS Month_Number,
        SUM(Sales) AS TotalSales,
        COUNT(OrderID) AS TotalOrders,
        row_number() OVER ( ORDER BY SUM(Sales) DESC) AS TopMonth
    FROM dbo.WorkSheet
    GROUP BY DATENAME(MONTH, OrderDate), DATEPART(MONTH, OrderDate)
),HighestMonth as (
select	MONTH_Name,Month_Number,TotalSales,TotalOrders
from MonthlySales
where TopMonth = 1
group by MONTH_Name,Month_Number,TotalSales,TotalOrders
)
select	hm.Month_Name,
		hm.Month_Number,
		sum(ws.Sales) as TotalSales,
		count(ws.OrderID) as TotalOrders,
		sum(ws.QuantityOrdered)/count(ws.QuantityOrdered)  as AverageQuantityOrdered,
		ws.hour
from dbo.Worksheet ws
INNER JOIN HighestMonth hm
	ON hm.Month_Name  = DATENAME(MONTH, ws.OrderDate)
group by hm.Month_Name,hm.Month_Number,ws.hour
order by hour asc;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
													--SalesTrendsOverTime

--Month-Over-Month(MoM Percentage)/City
With Monthly_Sales as (
select	trim(City) as city,
		DATENAME(month,ws.OrderDate) as Month_Name,
		DATEPART(month,ws.OrderDate) as Month_Number,
		DATEPART(year,ws.OrderDate) as Years,
		sum(ws.Sales) AS "ThisMonthSales"
from dbo.Worksheet ws
group by DATENAME(month,ws.OrderDate), DATEPART(month,ws.OrderDate),DATEPART(year,ws.OrderDate),city
),Pre_Month as (
select	city,
		Month_Name,
		Month_Number,
		Years,
		ThisMonthSales as ThisMonthSales,
		lag(ThisMonthSales,1,ThisMonthSales) over(partition by city order by Years,Month_number asc) as PreSalesMonths
from Monthly_Sales
)
select	*,
		pm.ThisMonthSales - pm.PreSalesMonths as Diff,
		(pm.ThisMonthSales  - pm.PreSalesMonths) / (pm.PreSalesMonths * 100) as MoM_Growth
from Pre_Month pm;

---Estimated Product Cost 
with TotalProductCost as (
select	trim(city) as city,
		DATENAME(month,OrderDate) as OrderDate,
		DATEPART(month,OrderDate) as Month_Number,
        DATEPART(YEAR,OrderDate) as Year,
		sum(sales) as Revenue,
		(sum(Sales) * 0.15) as "Estimated Product Cost",
	(sum(Sales) - (sum(Sales) * 0.15)) / sum(Sales) as EstimatedProfitMargin
from dbo.Worksheet
group by City,DATENAME(month,OrderDate),DATEPART(month,OrderDate),DATEPART(YEAR,OrderDate)
)
select	city,OrderDate, Month_Number, Year,
		revenue, "Estimated Product Cost",
		Revenue - [Estimated Product Cost] as NetProfit, 
		((Revenue - [Estimated Product Cost]) / Revenue)*100 as "GrossProfitMargin"
from TotalProductCost
order by year,Month_Number,city asc

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Sales In each Month Per city in 2019/2020
With SalesInTwoYears as (
select	trim(city) as city,
		datepart(month,OrderDate) as Month,
		datepart(year,OrderDate) as year,
		sum(Sales) as TotalSales
from dbo.Worksheet
group by trim(City),datepart(month,OrderDate),datepart(year,OrderDate)
)
select *
from SalesInTwoYears
order by Year,city,Month 

----------------------------------------------------------------------------------------------------------------------------------------------------------------------


With Y2019 as (
select	*
from dbo.Worksheet
where year(OrderDate) = 2019
)
--select * from Y2019
, t1 as (
select	OrderID, OrderDate, PurchaseAddress, Sales,format(OrderDate,'yyyy-MM-01') OrderMonth
from Y2019
)
--select *from t1
, t2 as (
select	PurchaseAddress, FORMAT(MIN(OrderDate), 'yyyy-MM-01') Cohort_month
from Y2019 
group by PurchaseAddress
)
--select *from t2
,t3 as (
select	t1.*,
		t2.Cohort_month, 
		datediff( MONTH,cast(t2.Cohort_month as date), cast(t1.OrderMonth as date)) +1 as Cohort_Index
from t1
Join t2
	on t1.PurchaseAddress = t2.PurchaseAddress
)
--select * from t3
,t4 as (
select	Cohort_month, OrderDate, Cohort_Index, count(distinct OrderID) countOrderID
from t3
group by Cohort_month, OrderDate, Cohort_Index
)
--select * from t4
,t5 as (
select	*
from (
		select Cohort_Month, Cohort_Index, countOrderID
		from t4
	) p
	PIVOT (
		SUM(countOrderID)
		FOR Cohort_Index IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])) piv
)
--select * from t5
select	Cohort_month,
	round(1.0 * [1]/[1],2 ) as [1],
	round(1.0 * [2]/[1],2 ) as [2],
	round(1.0 * [3]/[1],2 ) as [3],
	round(1.0 * [4]/[1],2 ) as [4],
	round(1.0 * [5]/[1],2 ) as [5],
	round(1.0 * [6]/[1],2 ) as [6],
	round(1.0 * [7]/[1],2 ) as [7],
	round(1.0 * [8]/[1],2 ) as [8],
	round(1.0 * [9]/[1],2 ) as [9],
	round(1.0 * [10]/[1],2 ) as [10],
	round(1.0 * [11]/[1],2 ) as [11],
	round(1.0 * [12]/[1],2 ) as [12]
from t5
order by Cohort_month asc;