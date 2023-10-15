/*1. How does the revenue generated from document registration vary 
across districts in Telangana? List down the top 5 districts that showed 
the highest document registration revenue growth between FY 2019 
and 2022*/

select j.district, sum(j.documents_registered_cnt) as total_registered, sum(j.documents_registered_rev) as total_revenue 
 from 
(SELECT dd.district, fs.documents_registered_cnt, fs.documents_registered_rev, fs.month FROM fact_stamps as fs
join dim_districts as dd on fs.dist_code = dd.dist_code) as j
group by j.district;

select j.district, sum(j.documents_registered_rev) as total_revenue 
 from 
(SELECT dd.district, fs.documents_registered_cnt, fs.documents_registered_rev, fs.month FROM fact_stamps as fs
join dim_districts as dd on fs.dist_code = dd.dist_code) as j
group by j.district
order by total_revenue desc limit 5
;


/*2. How does the revenue generated from document registration compare 
to the revenue generated from e-stamp challans across districts? List 
down the top 5 districts where e-stamps revenue contributes 
significantly more to the revenue than the documents in FY 2022?*/

select r.total_revenue_docs, r.total_estamps_revenune, r.dist_code
from
	(select sum(documents_registered_rev) as total_revenue_docs, 
	sum(estamps_challans_rev) as total_estamps_revenune, dist_code
		from fact_stamps
where year(month) = 2022
group by dist_code
) as r
where r.total_revenue_docs < r.total_estamps_revenune 
group by dist_code
order by r.total_estamps_revenune desc limit 5;



with revenue as (
select 	sum(documents_registered_rev) as total_revenue_docs, 
		sum(estamps_challans_rev) as total_estamps_revenune, 
			dist_code
		from fact_stamps
where year(month) = 2022
group by dist_code
)
select total_revenue_docs, total_estamps_revenune, dist_code from revenue
where total_revenue_docs < total_estamps_revenune 
group by dist_code
order by total_estamps_revenune desc limit 5

/*3.Is there any alteration of e-Stamp challan count and document 
registration count pattern since the implementation of e-Stamp 
challan? If so, what suggestions would you propose to the 
government?*/;

select dd.district, (sum(fs.estamps_challans_cnt)-sum(fs.documents_registered_cnt))  as alteration  from fact_stamps as fs
join dim_districts as dd on dd.dist_code = fs.dist_code
where month >= '2020-12-01' and month < '2023-03-01'
group by dd.district
order by alteration asc; 


select t.district, greatest(t.challans_cnt,t.documents_cnt ),
case when  greatest(t.challans_cnt,t.documents_cnt ) = t.challans_cnt then 'challans_cnt'
when greatest(t.challans_cnt,t.documents_cnt ) = t.documents_cnt then 'documents_cnt'
end as cnt
from (
select dj.district, sum(dj.estamps_challans_cnt) as challans_cnt, sum(dj.documents_registered_cnt) as documents_cnt
 from
(select dd.district, fs.documents_registered_cnt, fs.documents_registered_rev, fs.estamps_challans_cnt, fs.estamps_challans_rev
from dim_districts as dd
join fact_stamps as fs on dd.dist_code = fs.dist_code
where month >= '2020-12-01' and month < '2023-03-01') as dj
group by  dj.district) as t;
 
/*5.Investigate whether there is any correlation between vehicle sales and 
specific months or seasons in different districts. Are there any months 
or seasons that consistently show higher or lower sales rate, and if yes, 
what could be the driving factors? (Consider Fuel-Type category only)*/; 


select *
from (
select ft.month, dd.Mmm, dd.quarter, sum(fuel_type_diesel+fuel_type_electric+fuel_type_petrol)  as t
from dim_date as dd
right join fact_transport  as ft on dd.month = ft.month
group by ft.month, dd.Mmm, dd.quarter
order by t desc ) as c;

/*6.How does the distribution of vehicles vary by vehicle class 
MotorCycle, MotorCar, AutoRickshaw, Agriculture across different 
districts? Are there any districts with a predominant preference for a 
specific vehicle class? Consider FY 2022 for analysis*/;

select dist_code, greatest(total_motorcar,total_AutoRickshaw,total_Agriculture,total_cycle) as v,
case when greatest(total_motorcar,total_AutoRickshaw,total_Agriculture,total_cycle) = total_motorcar then 'total_motorcar'
when greatest(total_motorcar,total_AutoRickshaw,total_Agriculture, total_cycle ) = total_AutoRickshaw then 'total_AutoRickshaw'
when greatest(total_motorcar,total_AutoRickshaw,total_Agriculture, total_cycle) = total_Agriculture then 'total_Agriculture'
when greatest(total_motorcar,total_AutoRickshaw,total_Agriculture, total_cycle) = total_cycle then 'total_cycle'
end  as  vehlice_type
from
(select dist_code,
	sum(vehicleClass_MotorCycle) as total_cycle,
	sum(vehicleClass_MotorCar) as total_motorcar, 
	sum(vehicleClass_AutoRickshaw) as total_AutoRickshaw, 	
	sum(vehicleClass_Agriculture) as total_Agriculture
	from fact_transport
    where year(month) = 2022
    group by dist_code) as v;
    
    
/*percentage of contribution for overall revenue*/

select temp.dist_code, 100*temp.total_rev/sum(temp.total_rev) over() as t from

(SELECT dd.dist_code, sum(fs.documents_registered_rev) as total_rev FROM fact_stamps as fs
inner join dim_districts as dd on fs.dist_code= dd.dist_code
group by dd.dist_code) as temp
order by  t desc limit 3


/*7.List down the top 3 and bottom 3 districts that have shown the highest 
and lowest vehicle sales growth during FY 2022 compared to FY 
? (Consider and compare categories: Petrol, Diesel and Electric)*/;


select dd.district, ft.dist_code,
(sum(case when year(month) = 2022 then fuel_type_petrol+fuel_type_diesel+fuel_type_electric else 0 end) - 
sum( case when year(month) = 2021 then fuel_type_petrol++fuel_type_diesel+fuel_type_electric else 0 end )) as sale_growth
from fact_transport as ft
join dim_districts as dd on dd.dist_code = ft.dist_code
group by ft.dist_code, dd.district
order by sale_growth desc limit 3;

/*8.List down the top 5 sectors that have witnessed the most significant 
investments in FY 2022.*/;

select sector, round(sum(investment_in_cr),2) as investments from fact_ts_ipass
where month >= '01-04-2022' and month <= '01-12-2022'
group by sector
order by investments desc limit 5;

/*9.List down the top 3 districts that have attracted the most significant 
sector investments during FY 2019 to 2022? What factors could have 
led to the substantial investments in these particular districts?*/
 
 select dist_code, sector, total_investment  from (
select dist_code, sector, total_investment,  
 row_number() over(partition by dist_code order by  total_investment desc) as venky
 from 
(SELECT dist_code, sector, round(sum(investment_in_cr),2) AS total_investment
FROM  fact_ts_ipass
WHERe year(str_to_date(month, '%d-%m-%y') ) BETWEEN '2019' AND '2022'
GROUP BY
    dist_code, sector
ORDER BY
    total_investment DESC
) as t ) as r
where r.venky<= 3;
 
 

/*10.Is there any relationship between district investments, vehicles
 sales and stamps revenue within the same district between FY 2021
 and 2022*/
 
with cte  as 
(select dist_code, month, sum(investment_in_cr) from fact_ts_ipass
group by 1,2)
 select cte.*, ft.dist_code, fs.estamps_challans_rev, ft.month, ft.fuel_type_diesel, ft.fuel_type_electric, ft.fuel_type_petrol 
 from fact_transport as ft
 join fact_stamps  as fs on fs.dist_code = ft.dist_code and fs.month = ft.month 
join cte on ft.dist_code = cte.dist_code and  ft.month = str_to_date(cte.month, '%d-%m-%Y');



/*11. Are there any particular sectors that have shown substantial 
 investment in multiple districts between FY 2021 and 2022?*/

select sector from
(
select sector, count(dist_code) as c from(
SELECT sector, dist_code FROM telanagana.fact_ts_ipass
group by  dist_code, sector) as t
group by sector) as t2
where t2.c >3;

select sector from
(
select sector, count(dist_code) as c from(
SELECT sector, dist_code FROM telanagana.fact_ts_ipass
where month >= '01-01-2021' and month <= '01-12-2022'
group by  dist_code, sector
) as t
group by sector) as t2
where t2.c >3;

    










/* top 3 districts with highest revenue for documents */

select dist_code, sum(documents_registered_rev) as docs_revenue from fact_stamps
group by dist_code
order by docs_revenue desc limit 3;

/* top 3 districts with highest revenue for challans */

select dist_code,  sum(estamps_challans_rev) as challans_revenue from fact_stamps
group by dist_code
order by challans_revenue desc limit 3;

/* top 3 districts which generated highest investments  */

select dist_code, round(sum(investment_in_cr),2) as investments from fact_ts_ipass
group by dist_code
order by  investments desc limit 3;

/* top 3 districts which generated highest empolyment  */

select dist_code, sum(number_of_employees) as investments from fact_ts_ipass
group by dist_code
order by  investments desc limit 3;

/* top 3 sector which generated highest investments  */


select sector, sum(investment_in_cr) as investments  from fact_ts_ipass
group by sector
order by  investments desc limit 3;

/* top 3 sector which generated highest empolyment  */

select sector, sum(number_of_employees) as total_employees from fact_ts_ipass
group by sector
order by  total_employees desc limit 3;





/* top 3 districts where highest numbers vehicles sold */

select dist_code, (sum(fuel_type_petrol+ fuel_type_diesel + fuel_type_electric + fuel_type_others)) as total_vehicles
from fact_transport
group by dist_code
order by total_vehicles desc limit 3;

/* top 3 districts where highest numbers bikes sold */

select dist_code,sum(vehicleClass_MotorCycle) as total_bikes
from fact_transport
group by dist_code
order by total_bikes desc limit 3;

/* top 3 districts where highest numbers cars sold */

select dist_code,sum(vehicleClass_MotorCar) as total_cars
from fact_transport
group by dist_code
order by total_cars desc limit 3





