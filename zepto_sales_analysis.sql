-- creating a table --
create table zepto(
sku_id serial primary key,
category varchar(150),
name varchar(150) not null,
mrp decimal(8, 2),
discount_percentage decimal(5,2),
available_quantity int,
discounted_selling_price decimal(8,2),
weight_grams int,
out_of_stock boolean,
quantity int );
 
-- select * from zepto; 
 
-- ========================================================= --
--                    DATA EXPLORATION
-- ========================================================= --
-- Checking null values --
select * from zepto where category is null or
name is null or 
mrp is null or
discount_percentage is null or
available_quantity is null or
discounted_selling_price is null or
weight_grams is null or
out_of_stock is null or
quantity is null;

-- number of category in table --
-- this shows total unique categories and total number of products that falls under each category --
select  distinct category,
count(*) as Total_products from zepto 
group by category
order by category;

-- checking which are in stock and out of stock --
select out_of_stock, count(sku_id) from zepto
group by out_of_stock;

-- selecting all the products which occurs more than once and its count -- 
select name, count(sku_id) as "Number of Products" from zepto
group by name having count(sku_id) > 1
order by count(sku_id) desc;
 
 -- ========================================================= --
 --                    DATA CLEANING
 -- ========================================================= --
 
-- products with price as 0 --
select * from zepto where mrp = 0 or discounted_selling_price = 0;
-- delete from zepto where mrp = 0 or discounted_selling_price = 0;

-- setting all the product price from 2500 to 25.00 rupees -- 
update zepto 
set mrp = mrp/100.0,
discounted_selling_price = discounted_selling_price/100.0 ;


-- displaying products with top 10 discount percentage --
SELECT distinct name, discount_percentage from zepto order by discount_percentage desc 
limit 10;

-- displaying top 10 products which had the highest price reduction --
select distinct name , mrp, discount_percentage, discounted_selling_price, (mrp - discounted_selling_price) as 'Price reduction' 
from zepto
order by (mrp - discounted_selling_price) desc
limit 10;


-- displaying products with high price but out of stock --
select distinct name, mrp, out_of_stock from zepto where 
out_of_stock = "TRUE" and mrp > 400;

-- displaying categories' total estimated revenue --
select category, sum(discounted_selling_price * available_quantity) as Total_Revenue
from zepto 
group by category 
order by Total_revenue desc;

-- displaying products with mrp more than 500 and discount is less than 10% and sorting them with highest SP with lowest Discount--
select distinct name, mrp, discount_percentage, discounted_selling_price from zepto
where mrp > 500 and discount_percentage < 10 
order by discount_percentage, discounted_selling_price desc;

-- displaying top 10 categories of product with highest avg discounts offered and highest Price redutction --
select category, avg(discount_percentage) as avg_discount, sum(mrp - discounted_selling_price) as Total_Discounts from zepto
group by category
order by avg(discount_percentage) desc, sum(mrp - discounted_selling_price) desc
 limit 10;

-- display the price per gram for products above 100g and sort by best value --
select distinct 
name, weight_grams, discounted_selling_price, round(discounted_selling_price / weight_grams , 2 ) as value_per_gram from zepto
where weight_grams >= 100
order by round(discounted_selling_price / weight_grams, 2 ) ;

-- categorizing products with their weight --
select distinct 
name, discounted_selling_price, weight_grams,
case when weight_grams < 100 then "LOW"
when weight_grams >= 100 AND weight_grams < 500 THEN 'MEDIUM'
else "BULK" end
as weight_category 
from zepto
order by weight_category desc;

-- displaying total inventory weight by category --
select category, sum(weight_grams * available_quantity) as Total_weight from zepto 
group by category
order by sum(weight_grams * available_quantity) desc;

-- ========================================================= --
--                CREATING ANOTHER TABLE
-- ========================================================= --
create table sales(
sale_id serial primary key,
sku_id varchar(150),
customer_id int,
selling_price int,
discount_amount int,
total_amount int,
payment_method varchar(50),
delivery_status varchar(50),
customer_rating decimal(2,1));

-- adding extra column --
alter table sales add column quantity_sold int after customer_id;
select * from sales;


-- select * from sales;

-- ========================================================= --
--                    DATA EXPLORATION 
-- ========================================================= --

-- finding datas where the selling price and discount amount does not add up to total amount --
select * from sales where 
(selling_price * quantity_sold) - discount_amount <> total_amount; 

-- couting overall ratings into bad, good, and best --
select case 
when customer_rating <= 3 then "BAD"
when customer_rating <= 4.5 then "GOOD"
when customer_rating > 4.5 then "BEST"
end as rating_category, 
count(*) as Total_ratings
from sales
group by rating_category
order by total_ratings desc;

-- ========================================================= --
--                         JOINS 
-- ========================================================= --

-- checking both tables match if there is any extra ids in sales but missing in zepto --
select distinct 
s.sku_id from sales s left join 
zepto z on s.sku_id = z.sku_id 
where z.sku_id is null;

-- select * from sales where sku_id = 3730 or sku_id = 3731;
-- select * from zepto where sku_id = 3730 or sku_id = 3731;
-- delete from sales where sku_id = 3730 or sku_id = 3731;
-- describe zepto ;
-- describe sales;

-- changing the data type of sku_id to match the original --
alter table sales modify column sku_id bigint unsigned not null;

-- creating foreign key --
alter table sales 
add constraint fk_sku_id
foreign key (sku_id)
references zepto(sku_id);

-- testing join --
select z.sku_id, z.name, s.sale_id, s.total_amount 
from zepto z 
inner join sales s on
z.sku_id = s.sku_id;

-- testing join --
select distinct
z.name, z.sku_id, s.sale_id, s.total_amount 
from zepto z join sales s on 
z.sku_id = s.sku_id;

-- ========================================================= --
--                        AGGREGATION
-- ========================================================= --

-- finding total number of quanitity sold in each product --
select z.name, sum(quantity_sold) as total_quantity
from zepto z join sales s on 
z.sku_id = s.sku_id
group by z.sku_id, z.name
order by total_quantity desc;

-- finding total revenue for each category --
select z.category, sum(s.total_amount) as total_sales 
from zepto z join sales s
on z.sku_id = s.sku_id
group by z.category
order by total_sales desc;

-- ========================================================= --
--                     INVENTORY ANALYSIS
-- ========================================================= --

-- checking of any product with high sales is low in stock --
select z.name, z.category, z.available_quantity, sum(s.quantity_sold) as total_sales from zepto z join sales s
on z.sku_id= s.sku_id 
group by z.sku_id, z.name, z.category, z.available_quantity
having z.available_quantity <20 and sum(s.quantity_sold) > 20
order by total_sales desc;

-- products which have never been sold --
select z.sku_id, z.name, z.category, z.available_quantity 
from zepto z left join sales s 
on z.sku_id = s.sku_id 
where s.quantity_sold is null;

-- ========================================================= --
--                    ADVANCED ANALYSIS
-- ========================================================= --
--             USING WINDOW FUNCTIONS AND CTEs
-- ========================================================= --

-- Highest-selling product in each category --
with product_sales as (
select z.sku_id, z.name, z.category, sum(s.quantity_sold) as total_sales
from zepto z join sales s on z.sku_id = s.sku_id
group by z.sku_id, z.name, z.category
), 
ranked_products as (
select *, rank() over(partition by category order by total_sales desc) as category_rank
from product_sales)
select * from ranked_products
where category_rank = 1;

-- compare Sales vs Inventory value --
with sales_summary as 
(select sku_id, sum(total_amount)as total_sales 
from sales 
group by sku_id)

select 
z.category, 
sum(z.discounted_selling_price * z.available_quantity) as inventory_value,
sum(coalesce(ss.total_sales, 0)) as sales_revenue
from zepto z left join sales_summary ss
on z.sku_id = ss.sku_id
group by category
order by inventory_value desc;


-- finding which products have more Sales than inventory value --
with product_sales as 
(select sku_id, sum(total_amount) as total_sales from sales
group by sku_id)

select z.name,  (z.discounted_selling_price * z.available_quantity) as inventory_value, ps.total_sales
from zepto z join product_sales ps
on z.sku_id = ps.sku_id
where ps.total_sales > z.discounted_selling_price * z.available_quantity
order by ps.total_sales desc;

-- finding overstocked products --
select z.name, z.category, z.available_quantity, sum(coalesce(s.quantity_sold, 0)) as total_sales
from zepto z left join sales s
on z.sku_id= s.sku_id
group by z.name, z.category, z.available_quantity
having z.available_quantity > 50 and sum(coalesce(s.quantity_sold, 0)) < 10
order by total_sales;
