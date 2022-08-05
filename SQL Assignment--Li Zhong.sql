/* 1.	List of Persons full name, all their fax and phone numbers, as well as the phone number and fax of the company they are working for (if any). */

select Application.People.FullName,
       Application.People.FaxNumber,
       Application.People.PhoneNumber,
       Purchasing.Suppliers.SupplierName,
       Purchasing.Suppliers.FaxNumber,
       Purchasing.Suppliers.PhoneNumber,
       sales.Customers.CustomerName,
       sales.customers.FaxNumber,
       sales.Customers.PhoneNumber

from Application.People
         left join Purchasing.Suppliers on (Application.People.PersonID = Purchasing.Suppliers.PrimaryContactPersonID or
                                            Application.People.PersonID = Purchasing.Suppliers.AlternateContactPersonID)
         left join sales.customers on (application.people.personID = sales.customers.PrimaryContactPersonID or
                                       application.people.personID = sales.customers.AlternateContactPersonID)


/* 2.	If the customer's primary contact person has the same phone number as the customer�s phone number, list the customer companies.  */

select sales.Customers.CustomerName
from application.people
         inner join sales.customers on application.people.PersonID = sales.Customers.PrimaryContactPersonID
where application.people.PhoneNumber = sales.customers.PhoneNumber
		and sales.Customers.BuyingGroupID is not null;

/*3.	List of customers to whom we made a sale prior to 2016 but no sale since 2016-01-01.*/

select distinct(sales.customers.CustomerName)
from sales.orders
         inner join sales.customers on sales.orders.CustomerID = sales.customers.CustomerID
where sales.orders.orderdate < '2016-01-01'
  and sales.orders.CustomerID not in
      (
          select sales.orders.CustomerID
          from sales.orders
          where sales.orders.orderdate > '2016-01-01'
      );

/*before 2016-01-01: 657 records, after 2016-01-01: 663 records, therefore no result.*/

/*4.	List of Stock Items and total quantity for each stock item in Purchase Orders in Year 2013.*/

select warehouse.StockItems.StockItemName, sum(Purchasing.PurchaseOrderLines.OrderedOuters) as total
from Purchasing.PurchaseOrderLines
         inner join Purchasing.PurchaseOrders
                    on Purchasing.PurchaseOrders.PurchaseOrderID = Purchasing.PurchaseOrderLines.PurchaseOrderID
         inner join warehouse.StockItems on Purchasing.PurchaseOrderLines.StockItemID = warehouse.StockItems.StockItemID
where PurchaseOrders.OrderDate between '2013-01-01' and '2013-12-31'
group by warehouse.StockItems.StockItemName;

/*5.	List of stock items that have at least 10 characters in description.*/
select distinct (warehouse.StockItems.StockItemName)
from warehouse.StockItems
         inner join sales.OrderLines on sales.OrderLines.StockItemID = warehouse.StockItems.StockItemID
where len(sales.OrderLines.Description) >= 10;

/*6.	List of stock items that are not sold to the state of Alabama and Georgia in 2014.*/
select distinct (Warehouse.StockItems.StockItemName)
from Warehouse.StockItems
         inner join sales.OrderLines on sales.OrderLines.StockItemID = Warehouse.StockItems.StockItemID
         inner join sales.Orders on sales.Orders.OrderID = sales.OrderLines.OrderID
         inner join sales.Customers on sales.customers.CustomerID = sales.orders.CustomerID
         inner join Application.cities on Application.cities.cityid = sales.customers.DeliveryCityID
         inner join Application.StateProvinces
                    on Application.StateProvinces.StateProvinceID = Application.cities.StateProvinceID
where Application.StateProvinces.StateProvinceName != 'Alabama'
  and application.StateProvinces.StateProvinceName != 'Georgia'
  and sales.orders.OrderDate between '2014-01-01' and '2014-12-31';

/*7.	List of States and Avg dates for processing (confirmed delivery date � order date).*/
select asp.StateProvinceName, avg(datediff(day, so.OrderDate, si.ConfirmedDeliveryTime)) as 'average days'
from Application.StateProvinces as asp
         inner join Application.Cities as ac on asp.StateProvinceID = ac.StateProvinceID
         inner join sales.Customers as sc on sc.DeliveryCityID = ac.CityID
         inner join sales.Orders as so on so.CustomerID = sc.CustomerID
         inner join sales.Invoices as si on si.OrderID = so.OrderID
group by asp.StateProvinceName;

/*8.	List of States and Avg dates for processing (confirmed delivery date � order date) by month.*/
select asp.StateProvinceName,
    month (so.orderdate) as 'month',
    avg (datediff(day, so.OrderDate, si.ConfirmedDeliveryTime)) as 'average days'
from Application.StateProvinces as asp
    inner join Application.Cities as ac
on asp.StateProvinceID = ac.StateProvinceID
    inner join sales.Customers as sc on sc.DeliveryCityID = ac.CityID
    inner join sales.Orders as so on so.CustomerID = sc.CustomerID
    inner join sales.Invoices as si on si.OrderID = so.OrderID
group by asp.StateProvinceName, month (so.orderdate)
order by asp.StateProvinceName, month (so.orderdate);

/*9.	List of StockItems that the company purchased more than sold in the year of 2015.*/

select ws.StockItemName,
       sum(so.pickedquantity) as 'sold', sum(pol.receivedouters) as 'purchase'

from Warehouse.StockItems as ws
         inner join sales.OrderLines as so on so.StockItemID = ws.StockItemID
         inner join sales.Invoices as si on si.OrderID = so.OrderID
         inner join Purchasing.PurchaseOrderLines as pol on ws.StockItemID = pol.StockItemID
         inner join Purchasing.PurchaseOrders as po on po.PurchaseOrderID = pol.PurchaseOrderID

where po.orderdate between '2015-01-01' and '2015-12-31'
  and si.InvoiceDate between '2015-01-01' and '2015-12-31'
group by ws.StockItemName
having sum(pol.receivedouters) > sum(so.pickedquantity);

/*10.	List of Customers and their phone number, together with the primary contact person�s name, to whom we did not sell more than 10 mugs (search by name) in the year 2016.*/

select sc.CustomerName, sc.PhoneNumber, ap.FullName as 'primary contact person', sum(sol.pickedquantity) as 'sold'
from application.People as ap
         inner join sales.Customers as sc on ap.PersonID = sc.PrimaryContactPersonID
         inner join sales.Orders as so on so.CustomerID = sc.CustomerID
         inner join sales.orderlines as sol on sol.OrderID = so.OrderID

where sol.Description like '%mug%'
  and so.OrderDate between '2016-01-01' and '2016-12-31'
group by sc.CustomerName, sc.PhoneNumber, ap.FullName
having sum(sol.pickedquantity) < 10;

/*11.	List all the cities that were updated after 2015-01-01.*/

select ac.CityName
from Application.Cities as ac
where ac.ValidFrom > '2015-01-01';

/*12.	List all the Order Detail (Stock Item name, delivery address, delivery state, city, country, customer name, customer contact person name, customer phone, quantity) for the date of 2014-07-01. Info should be relevant to that date.*/

select sol.Description,
       sol.PickedQuantity,
       sc.DeliveryAddressLine1,
       sc.DeliveryAddressLine2,
       ac.CityName,
       asp.StateProvinceName,
       acou.CountryName,
       sc.CustomerName,
       ap.fullname as 'Contact Person', ap.PhoneNumber as 'Contact Person Phone'


from sales.orders as so
         inner join sales.orderlines as sol on so.orderID = sol.OrderID
         inner join sales.customers as sc on sc.customerID = so.customerID
         inner join application.cities as ac on sc.DeliveryCityID = ac.CityID
         inner join application.StateProvinces as asp on asp.StateProvinceID = ac.StateProvinceID
         inner join application.Countries as acou on acou.CountryID = asp.CountryID
         inner join application.People as ap on ap.PersonID = so.ContactPersonID
where so.OrderDate = '2014-07-01';

/*13.	List of stock item groups and total quantity purchased, total quantity sold, and the remaining stock quantity (quantity purchased � quantity sold)*/

select wsg.StockGroupID,
       wsg.StockGroupName,
       sum(cast(pol.receivedouters as bigint)) as 'Purchased', sum(cast(so.pickedquantity as bigint)) as 'Sold', sum(cast(pol.receivedouters as bigint)) - sum(cast(so.pickedquantity as bigint)) as 'Remining Stock'

from Warehouse.StockItems as ws
         inner join sales.OrderLines as so on so.StockItemID = ws.StockItemID
         inner join sales.Invoices as si on si.OrderID = so.OrderID
         inner join Purchasing.PurchaseOrderLines as pol on ws.StockItemID = pol.StockItemID
         inner join warehouse.StockItemHoldings as wsh on wsh.StockItemID = ws.StockItemID
         inner join warehouse.StockItemStockGroups as wssg on wssg.StockItemID = wsh.StockItemID
         inner join Warehouse.StockGroups as wsg on wsg.StockGroupID = wssg.StockGroupID
group by wsg.StockGroupID, wsg.StockGroupName;

/*14.	List of Cities in the US and the stock item that the city got the most deliveries in 2016. If the city did not purchase any stock items in 2016, print �No Sales�.*/

with cte (cityID, cityname, orderdate, description, total) as
         (select ac.CityID,
                 ac.CityName,
                 so.OrderDate,
                 sol.description,
                 case
                     when sum(sol.pickedquantity) is null then 0
                     when so.OrderDate not between '2016-01-01' and '2016-12-31' then 0
                     else sum(sol.pickedquantity)
                     end as total

          from application.Cities as ac
                   left join sales.customers as sc on sc.DeliveryCityID = ac.CityID
                   left join sales.orders as so on sc.CustomerID = so.CustomerID
                   left join sales.OrderLines as sol on sol.OrderID = so.OrderID

          group by ac.CityID, ac.CityName, sol.description, so.OrderDate),

     cte2 (cityID, max_total) as
         (select cityID, max(total) as max_total
          from cte
          group by cityID)

select cte.cityID,
       max(cte.cityname) as city,
       case
           when max(cte.total) = 0 then 'No sales'
           else max(cte.description)
           end           as item
from cte
where cte.total = (select cte2.max_total from cte2 where cte2.cityID = cte.cityID)
group by cte.cityID
order by cte.cityID;

/*15.	List any orders that had more than one delivery attempt (located in invoice table).*/

/*select
sales.Invoices.*,
A.*
from sales.Invoices
cross apply (
    select * from openjson (sales.invoices.returneddeliverydata)
             with (
                     Event varchar(200)         '$.Events[0].Event',
                     Time datetime              '$.Events[0].EventTime',
                     Note  varchar(200)         '$.Events[0].ConNote',
                     Attempt varchar(200)       '$.Events[1].Event',
                     DeliveryTime datetime      '$.Events[1].EventTime',
                     DeliveryNote varchar(200)  '$.Events[1].ConNote',
                     DriverID  int              '$.Events[1].DriverID',
                     Latitude  varchar(200)     '$.Events[1].Latitude',
                     Longitude varchar(200)     '$.Events[1].Longitude',
                     Status    varchar(200)     '$.Events[1].Status',
                     DeliveryComplete datetime  '$.DeliveredWhen',
                     ReceivedBy varchar(200)    '$.ReceivedBy'
                   )
                )A
 */

select (len(ReturnedDeliveryData) - len(replace(ReturnedDeliveryData, 'DeliveryAttempt', ''))) /
       len('DeliveryAttempt') as DeliveryAttempTimes
from sales.Invoices
where (len(ReturnedDeliveryData) - len(replace(ReturnedDeliveryData, 'DeliveryAttempt', ''))) / len('DeliveryAttempt') > 1;

/* 16.	List all stock items that are manufactured in China. (Country of Manufacture)*/

select ws.StockItemName

from Warehouse.StockItems as ws

where json_value(ws.CustomFields, '$.CountryOfManufacture') = 'China';

/*17.	Total quantity of stock items sold in 2015, group by country of manufacturing.*/

select json_value(Warehouse.StockItems.CustomFields, '$.CountryOfManufacture') as Country,
       sum(sales.OrderLines.PickedQuantity)                                    as Total_quantity

from Warehouse.StockItems
         inner join sales.orderlines on sales.orderlines.StockItemID = Warehouse.StockItems.StockItemID
         inner join sales.orders on sales.orders.orderID = sales.orderlines.OrderID
where sales.orders.OrderDate between '2015-01-01' and '2015-12-31'
group by json_value(Warehouse.StockItems.CustomFields, '$.CountryOfManufacture');
go

/*18.	Create a view that shows the total quantity of stock items of each stock group sold (in orders) by year 2013-2017. [Stock Group Name, 2013, 2014, 2015, 2016, 2017]*/

create view Stockgroup_sale as

select StockGroupName as Stockgroupname,
        [2013], [2014], [2015], [2016], [2017]
        from (select wsg.StockGroupName, year (so.OrderDate) as year1, sol.PickedQuantity
        from sales.orders as so
        inner join sales.orderlines as sol on sol.orderID = so.OrderID
        inner join Warehouse.StockItemStockGroups as wssg on wssg.StockItemID = sol.StockItemID
        inner join Warehouse.StockItems as ws on ws.StockItemID = wssg.StockItemID
        inner join Warehouse.StockGroups as wsg on wsg.StockGroupID = wssg.StockGroupID
        where so.OrderDate between '2013-01-01' and '2017-12-31') as sourcetable pivot
        (sum (PickedQuantity)
        for
        year1 in ([2013], [2014], [2015], [2016], [2017])) as pivottable;
go

/*19.	Create a view that shows the total quantity of stock items of each stock group sold (in orders) by year 2013-2017. [Year, Stock Group Name1, Stock Group Name2, Stock Group Name3, � , Stock Group Name10] */

create view Stockgroup_sale2 as

select year1 as Year_sold,
        [T-Shirts],
        [USB Novelties],
        [Packaging Materials],
        [Clothing],
        [Novelty Items],
        [Furry Footwear],
        [Mugs],
        [Computing Novelties],
        [Toys]
        from (select wsg.StockGroupName as groups, year (so.OrderDate) as year1, sol.PickedQuantity
        from sales.orders as so
        inner join sales.orderlines as sol on sol.orderID = so.OrderID
        inner join Warehouse.StockItemStockGroups as wssg on wssg.StockItemID = sol.StockItemID
        inner join Warehouse.StockItems as ws on ws.StockItemID = wssg.StockItemID
        inner join Warehouse.StockGroups as wsg on wsg.StockGroupID = wssg.StockGroupID
        where so.OrderDate between '2013-01-01' and '2017-12-31') as sourcetable pivot
        (sum (PickedQuantity)
        for
        groups in ([T-Shirts], [USB Novelties], [Packaging Materials], [Clothing], [Novelty Items], [Furry Footwear], [Mugs], [Computing Novelties], [Toys])) as pivottable;
go

  /*20.	Create a function, input: order id; return: total of that order. List invoices and use that function to attach the order total to the other fields of invoices.*/

create function cal(@orderid int)
    returns float as
begin declare
@total float;
select @total = sum((UnitPrice * PickedQuantity) * (1 + TaxRate / 100))
from sales.OrderLines
where OrderID = @orderid return @total;
end;
go

select *
from sales.invoices
         inner join
     (select sales.orderlines.orderID, dbo.cal(sales.OrderLines.OrderID) as total_price
      from sales.OrderLines) a
     on sales.invoices.orderID = a.OrderID;

/*21.	Create a new table called ods.Orders. Create a stored procedure, with proper error handling and transactions, that input is a date;
      when executed, it would find orders of that day, calculate order total, and save the information (order id, order date, order total, customer id) into the new table.
      If a given date is already existing in the new table, throw an error and roll back. Execute the stored procedure 5 times using different dates. */

IF
NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'ods')
BEGIN
EXEC('CREATE SCHEMA ods')
END
go

create
proc date_orders @date datetime
		as
Begin set
nocount on;
begin
transaction;
begin try

select *
into ods.orders
from (
         select sol.orderID,
                so.OrderDate,
                so.CustomerID,
                sum((sol.UnitPrice * sol.PickedQuantity) * (1 + sol.TaxRate / 100)) as total
         from sales.Orders as so
                  inner join sales.orderlines as sol
                             on so.OrderID = sol.OrderID
         where so.OrderDate = @date
         group by sol.orderID, so.OrderDate, so.CustomerID) as yy;

commit transaction;
end try

begin catch
select ERROR_NUMBER()    AS ErrorNumber
     , ERROR_SEVERITY()  AS ErrorSeverity
     , ERROR_STATE()     AS ErrorState
     , ERROR_PROCEDURE() AS ErrorProcedure
     , ERROR_LINE()      AS ErrorLine
     , ERROR_MESSAGE()   AS ErrorMessage;
END CATCH

if @date in (select orderdate from sales.Orders )
rollback transaction;
end;

exec date_orders @date= '2013-01-01'
go

  /*22.	Create a new table called ods.StockItem. It has following columns: [StockItemID], [StockItemName] ,[SupplierID] ,[ColorID] ,[UnitPackageID] ,[OuterPackageID] ,[Brand] ,
  [Size] ,[LeadTimeDays] ,[QuantityPerOuter] ,[IsChillerStock] ,[Barcode] ,[TaxRate]  ,[UnitPrice],[RecommendedRetailPrice] ,[TypicalWeightPerUnit] ,[MarketingComments],
  [InternalComments], [CountryOfManufacture], [Range], [Shelflife]. Migrate all the data in the original stock item table.*/

select StockItemID,
       StockItemName,
       SupplierID,
       ColorID,
       UnitPackageID,
       OuterPackageID,
       Brand,
    Size,
    LeadTimeDays,
    QuantityPerOuter,
    IsChillerStock,
    Barcode,
    TaxRate,
    UnitPrice,
    RecommendedRetailPrice,
    TypicalWeightPerUnit,
    MarketingComments,
    InternalComments,
    json_value(Warehouse.StockItems.CustomFields, '$.CountryOfManufacture') as CountryOfManufacture,
    json_value(Warehouse.StockItems.CustomFields, '$.ShelfLife') as Shelflife,
    json_value(Warehouse.StockItems.CustomFields, '$.Range') as 'Range'
into ods.StockItem
from Warehouse.StockItems;

/* 24. Migrate these data into Stock Item, Purchase Order and Purchase Order Lines tables. Of course, save the script.*/

declare
@json nvarchar(max) = N'{
   
   "PurchaseOrders":[
      {
         "StockItemName":"Panzer Video Game",
         "Supplier":"7",
         "UnitPackageId":"1",
         "OuterPackageId":[
            6,
            7
         ],
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-01",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"WWI2308"
      },
      {
         "StockItemName":"Panzer Video Game 2",
         "Supplier":"5",
         "UnitPackageId":"1",
         "OuterPackageId":"7",
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-025",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"269622390"
      }
   ]
}'

select tt.*
into gg
from (
         select *
         from openjson(@json, '$.PurchaseOrders[0]')
             with (
             StockItemName nvarchar (100) '$.StockItemName',
             SupplierID int '$.Supplier',
             UnitPackageID int '$.UnitPackageId',
             OuterPackageID nvarchar (max) '$.OuterPackageId' as json,
             Brand varchar (50) '$.Brand',
             LeadTimeDays int '$.LeadTimeDays',
             QuantityPerOuter int '$.QuantityPerOuter',
             TaxRate decimal (18, 3) '$.TaxRate',
             UnitPrice decimal (18, 2) '$.UnitPrice',
             RecommendedRetailPrice decimal (18, 2) '$.RecommendedRetailPrice',
             TypicalWeightPerUnit decimal (18, 3) '$.TypicalWeightPerUnit',
             CountryOfManufacture varchar (100) '$.CountryOfManufacture',
             Ranges varchar (100) '$.Range',
             OrderDate datetime '$.OrderDate',
             DeliveryMethod varchar (100) '$.DeliveryMethod',
             ExpectedDeliveryDate datetime '$.ExpectedDeliveryDate',
             SupplierReference varchar (100) '$.SupplierReference'
     )
union
select *
from
    openjson(@json, '$.PurchaseOrders[1]')
        with (
    StockItemName nvarchar (100) '$.StockItemName',
    SupplierID int '$.Supplier',
    UnitPackageID int '$.UnitPackageId',
    OuterPackageID nvarchar (max) '$.OuterPackageId',
    Brand varchar (50) '$.Brand',
    LeadTimeDays int '$.LeadTimeDays',
    QuantityPerOuter int '$.QuantityPerOuter',
    TaxRate decimal (18, 3) '$.TaxRate',
    UnitPrice decimal (18, 2) '$.UnitPrice',
    RecommendedRetailPrice decimal (18, 2) '$.RecommendedRetailPrice',
    TypicalWeightPerUnit decimal (18, 3) '$.TypicalWeightPerUnit',
    CountryOfManufacture varchar (100) '$.CountryOfManufacture',
    Ranges varchar (100) '$.Range',
    OrderDate datetime '$.OrderDate',
    DeliveryMethod varchar (100) '$.DeliveryMethod',
    ExpectedDeliveryDate datetime '$.ExpectedDeliveryDate',
    SupplierReference varchar (100) '$.SupplierReference'
    )) as tt


select *
from gg;

go

 /*1*/
insert into warehouse.stockitems ( [StockItemName]
                                 , [SupplierID]
                                 , [ColorID]
                                 , [UnitPackageID]
                                 , [OuterPackageID]
                                 , [Brand]
                                 , [Size]
                                 , [LeadTimeDays]
                                 , [QuantityPerOuter]
                                 , [IsChillerStock]
                                 , [Barcode]
                                 , [TaxRate]
                                 , [UnitPrice]
                                 , [RecommendedRetailPrice]
                                 , [TypicalWeightPerUnit]
                                 , [MarketingComments]
                                 , [InternalComments]
                                 , [Photo]
                                 , [CustomFields]
                                 , [LastEditedBy])
select StockItemName,
       SupplierID,
       null,
       UnitPackageID,
       7,
       Brand,
       null,
       LeadTimeDays,
       QuantityPerOuter,
       0,
       null,
       TaxRate,
       UnitPrice,
       RecommendedRetailPrice,
       TypicalWeightPerUnit,
       null,
       null,
       null,
       null,
       2

from gg;

/*2*/

INSERT INTO [Purchasing].[PurchaseOrders]
([     SupplierID]
    , [OrderDate]
    , [DeliveryMethodID]
    ,  ContactPersonID
    , [ExpectedDeliveryDate]
    , [SupplierReference],
       IsOrderFinalized,
       LastEditedBy)
select SupplierID,
       orderDate,
       1,
       2,
       ExpectedDeliveryDate,
       SupplierReference,
       1,
       10

from gg;
go

   /* 25.	Revisit your answer in (19). Convert the result in JSON string and save it to the server using TSQL FOR JSON PATH.*/

create table json_table
(
    ID        int identity(1,1) primary key,
    json_file nvarchar( max)
)

declare
@store nvarchar(max)= (
	select * from Stockgroup_sale2
	for json path)

insert into json_table
select @store

select *
from json_table

/*26.	Revisit your answer in (19). Convert the result into an XML string and save it to the server using TSQL FOR XML PATH.*/

declare
@xmlStock as xml = (
  select Year_sold as [Year], 'T-Shirts' as [T-Shirts], 'USB Novelties' as [USB_Novelties], 'Packaging Materials' as [Packaging_Materials], Clothing as [Chlothing],
 'Novelty Items' as [Novelty_Items], 'Furry Footwear' as [Furry_Footwear], Mugs as [Mugs], 'Computing Novelties' as [Computing_Novelties],
 Toys as [Toys] 

 from (

 select year1 as Year_sold, [T-Shirts], [USB Novelties], [Packaging Materials], [Clothing], [Novelty Items], [Furry Footwear], [Mugs], [Computing Novelties], [Toys]
 from 

 (select wsg.StockGroupName as groups, year(so.OrderDate) as year1, sol.PickedQuantity 
 from sales.orders as so
 inner join sales.orderlines as sol on sol.orderID = so.OrderID
 inner join Warehouse.StockItemStockGroups as wssg on wssg.StockItemID = sol.StockItemID
 inner join Warehouse.StockItems as ws on ws.StockItemID = wssg.StockItemID
 inner join Warehouse.StockGroups as wsg on wsg.StockGroupID = wssg.StockGroupID
 where so.OrderDate between '2013-01-01' and '2017-12-31') as sourcetable
 pivot
 (sum(PickedQuantity)
  for 
  groups in ([T-Shirts], [USB Novelties], [Packaging Materials], [Clothing], [Novelty Items], [Furry Footwear], [Mugs], [Computing Novelties], [Toys])) as pivottable) as nn

  for XML path
  )

declare
@xmlStockChar as varchar(max) = cast (@xmlStock as varchar(max));

select @xmlStockChar