--7 Create a trigger to updates the Stock (quantity) table whenever new order placed in orders tables
CREATE TRIGGER tr_update_stock
ON sales.order_items
AFTER INSERT
AS
BEGIN
    UPDATE s
    SET s.quantity = s.quantity - i.quantity
    FROM production.stocks s
    JOIN inserted i 
        ON s.store_id = (SELECT store_id FROM sales.orders WHERE order_id = i.order_id)
       AND s.product_id = i.product_id
    WHERE s.quantity >= i.quantity;
    
    IF EXISTS (
        SELECT 1 
        FROM production.stocks s
        JOIN inserted i 
            ON s.store_id = (SELECT store_id FROM sales.orders WHERE order_id = i.order_id)
           AND s.product_id = i.product_id
        WHERE s.quantity < 0
    )
    BEGIN
        RAISERROR ('Insufficient stock for one or more products.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END






--8) Create a trigger to that prevents deletion of a customer if they have existing orders.
CREATE TRIGGER tr_customer_deletion
ON sales.customers
INSTEAD OF DELETE
AS
BEGIN
IF EXISTS (
SELECT 1
FROM sales.orders o
JOIN deleted d ON o.customer_id = d.customer_id
)
BEGIN
RAISERROR ('Cannot delete customer with existing orders.', 16, 1);
ROLLBACK TRANSACTION;
END
ELSE
BEGIN
DELETE FROM sales.customers
WHERE customer_id IN (SELECT customer_id FROM deleted);
END
END


-- 9) Create Employee,Employee_Audit  insert some test data
--	b) Create a Trigger that logs changes to the Employee Table into an Employee_Audit Table

CREATE TABLE Employee (
    EmployeeID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    Salary DECIMAL(18, 2) NOT NULL,
    HireDate DATETIME NOT NULL,
    LastModified DATETIME DEFAULT GETDATE()
)

CREATE TABLE Employee_Audit (
    AuditID INT PRIMARY KEY IDENTITY(1,1),
    EmployeeID INT NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    Salary DECIMAL(18, 2) NOT NULL,
    ModifiedDate DATETIME DEFAULT GETDATE(),
    Operation NVARCHAR(10) NOT NULL -- to track operation type (INSERT/UPDATE/DELETE)
)

INSERT INTO Employee (FirstName, LastName, Email, Salary, HireDate)
VALUES 
('rohan', 'Dalal', 'rohan@example.com', 60000.00, '2022-01-15'),
('roy', 'Singh', 'roy@example.com', 65000.00, '2023-03-20'),
('mandeep', 'patel', 'mandeep@example.com', 55000.00, '2021-07-25');




UPDATE Employee
SET Salary = 70000
WHERE EmployeeID = 1 


CREATE TRIGGER trg_AuditEmployee1
ON Employee
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Insert records into the Employee_Audit table for INSERT operation
    INSERT INTO Employee_Audit (EmployeeID, FirstName, LastName, Email, Salary, ModifiedDate, Operation)
    SELECT 
        i.EmployeeID,
        i.FirstName,
        i.LastName,
        i.Email,
        i.Salary,
        GETDATE(),
        'INSERT'
    FROM inserted i;

    -- Insert records into the Employee_Audit table for UPDATE operation
    INSERT INTO Employee_Audit (EmployeeID, FirstName, LastName, Email, Salary, ModifiedDate, Operation)
    SELECT 
        u.EmployeeID,
        u.FirstName,
        u.LastName,
        u.Email,
        u.Salary,
        GETDATE(),
        'UPDATE'
    FROM inserted u
    INNER JOIN deleted d ON u.EmployeeID = d.EmployeeID;

    -- Insert records into the Employee_Audit table for DELETE operation
    INSERT INTO Employee_Audit (EmployeeID, FirstName, LastName, Email, Salary, ModifiedDate, Operation)
    SELECT 
        d.EmployeeID,
        d.FirstName,
        d.LastName,
        d.Email,
        d.Salary,
        GETDATE(),
        'DELETE'
    FROM deleted d;
END;


DELETE FROM Employee
WHERE EmployeeID = 2; 

SELECT * FROM Employee_Audit;


--10)
--create Room Table with below columns
--RoomID,RoomType,Availability
--create Bookins Table with below columns
--BookingID,RoomID,CustomerName,CheckInDate,CheckInDate
 
--Insert some test data with both  the tables
--Ensure both the tables are having Entity relationship
--Write a transaction that books a room for a customer, ensuring the room is marked as unavailable.

CREATE TABLE Room (
    RoomID INT PRIMARY KEY IDENTITY(1,1),
    RoomType NVARCHAR(50) NOT NULL,
    Availability BIT NOT NULL DEFAULT 1 -- 1 for available, 0 for unavailable
);

CREATE TABLE Bookings (
    BookingID INT PRIMARY KEY IDENTITY(1,1),
    RoomID INT NOT NULL,
    CustomerName NVARCHAR(100) NOT NULL,
    CheckInDate DATETIME NOT NULL,
    CheckOutDate DATETIME NOT NULL,
    FOREIGN KEY (RoomID) REFERENCES Room(RoomID) ON DELETE CASCADE
);

-- Insert test data into Room table
INSERT INTO Room (RoomType, Availability)
VALUES 
('Single', 1),
('Double', 1),
('Suite', 1),
('Deluxe', 1);

-- Insert initial test data into Bookings table (if needed)
INSERT INTO Bookings (RoomID, CustomerName, CheckInDate, CheckOutDate)
VALUES 
(1, 'Manan', '2024-11-01', '2024-11-05'),
(2, 'Rohan', '2024-11-03', '2024-11-06');


BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @RoomID INT = 1; 
    DECLARE @CustomerName NVARCHAR(100) = 'John Doe';
    DECLARE @CheckInDate DATETIME = '2024-11-10';
    DECLARE @CheckOutDate DATETIME = '2024-11-15';

    DECLARE @Availability BIT;
    SELECT @Availability = Availability FROM Room WHERE RoomID = @RoomID;

    IF @Availability = 0
    BEGIN
        PRINT 'Room is not available for booking.';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    INSERT INTO Bookings (RoomID, CustomerName, CheckInDate, CheckOutDate)
    VALUES (@RoomID, @CustomerName, @CheckInDate, @CheckOutDate);

    UPDATE Room
    SET Availability = 0 -- Mark as unavailable
    WHERE RoomID = @RoomID;

    COMMIT TRANSACTION;
    PRINT 'Room booked successfully!';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT 'Error occurred: ' + ERROR_MESSAGE();
END CATCH;







