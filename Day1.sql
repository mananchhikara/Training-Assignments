--usd function
alter function GetAllProducts()
returns int
as
begin
return (select count (*) from production.products)
end

print dbo.GetAllProducts()

--Question 1
alter proc getcustomersbyproduct
@productid int
as
begin
select 
c.customer_id, 
c.first_name, 
o.order_date as purchasedate
from sales.customers c
inner join sales.orders o on c.customer_id = o.customer_id
inner join sales.order_items oi on o.order_id = oi.order_id
where oi.product_id = @productid;
end 

getcustomersbyproduct 20

--Question 2
create table department(
id int primary key,
name varchar(50)
)
create table employee (
id int primary key,
name varchar(50),
gender varchar(10),
dob date,
deptid int,
foreign key (deptid) references department(id)
)

insert into department values
(1,'Technical'),
(2,'HR'),
(3,'Sales')
select * from department

insert into employee values
(1,'Manik','Male','2002-10-04',2),
(2,'Rohan','Male','2002-11-06',1),
(3,'Kritika','Female','2002-08-05',3)
--a
create proc updateEmployeeDetails(@employeeid int,@name varchar(50),@gender varchar(10),@dob date)
as
begin
update employee
set name=@name,gender=@gender,dob=@dob
where id=@employeeid
end

exec updateEmployeeDetails 1,'Manav','Male','2003-09-08'

select * from employee

--b
create proc GetEmployeeInfo 
@empid int
as
begin
select id,name from employee
where id=@empid
end 

GetEmployeeInfo 1

--c
create proc GetEmployeeCount
@gender varchar(10)
as
begin
select count(*) as countemp
from employee
where gender=@gender
end

GetEmployeeCount 'Male'

--question 3
create function calculateprice(@productid int,@quantity int)
returns decimal(10,2)
as
begin
declare @amount decimal(10,2)
select @amount=list_price * quantity
from sales.order_items
where product_id=@productid 
return @amount
end

select dbo.calculateprice(4,1) as amount

--question 4
alter function GetOrders(@customerid int)
returns @temptable table (order_id int, order_date date,amount decimal)
as 
begin
insert into @temptable
select o.order_id,o.order_date,sum(oi.list_price * oi.quantity) as amount
from sales.orders o
inner join sales.order_items oi on o.order_id=oi.order_id
where customer_id=@customerid
group by o.order_id,o.order_date
return
end

select * from GetOrders(3)
select * from sales.order_items

--question 5
alter function sale()
returns @salestable table (productid int,totalsales decimal(10,2)
)
as
begin
insert into @salestable(productid,totalsales)
select 
oi.product_id,
sum(oi.quantity*(oi.list_price-oi.discount)) as totalsales
from sales.order_items oi
group by
oi.product_id
return
end

select * from sale()






--question 6
create function amountSpent()
returns @custamount table( customerid int, amountspent decimal(10,2))
as
begin
insert into @custamount(customerid,amountspent)
select
c.customer_id,
sum(oi.quantity*(oi.list_price-oi.Discount)) as amountspent
from 
sales.customers c
left join
sales.orders o on c.customer_id=o.customer_id
left join
sales.order_items oi on o.order_id=oi.order_id
group by
c.customer_id
return
end 

select * from amountSpent()


