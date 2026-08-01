/* =====================================================================
   EMSDB - Full schema + large realistic dataset
   Run this ENTIRE script in SSMS (F5). It creates the database, all
   15 tables, and generates ~95,000+ rows using set-based SQL
   (not thousands of hand-typed INSERT lines).

   SAFE TO RE-RUN: switches to master first, so it can drop and rebuild
   EMSDB even if your session was previously pointed at it.
   ===================================================================== */

USE master;
GO

IF DB_ID('EMSDB') IS NOT NULL
BEGIN
    ALTER DATABASE EMSDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE EMSDB;
END
GO

CREATE DATABASE EMSDB;
GO
USE EMSDB;
GO

/* ============================ TABLES ============================ */

CREATE TABLE Departments (
    DepartmentID INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentName NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(300),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE()
);

CREATE TABLE Designations (
    DesignationID INT IDENTITY(1,1) PRIMARY KEY,
    DesignationName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(300),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE()
);

CREATE TABLE Roles (
    RoleID INT IDENTITY(1,1) PRIMARY KEY,
    RoleName NVARCHAR(50) NOT NULL UNIQUE,
    Description NVARCHAR(200)
);

CREATE TABLE Users (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    Username NVARCHAR(50) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(300) NOT NULL,
    Email NVARCHAR(100),
    RoleID INT,
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Users_Roles FOREIGN KEY (RoleID) REFERENCES Roles(RoleID)
);

CREATE TABLE Employees (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeCode NVARCHAR(20) UNIQUE NOT NULL,
    FullName NVARCHAR(100) NOT NULL,
    FatherName NVARCHAR(100),
    CNIC NVARCHAR(20) UNIQUE,
    Gender NVARCHAR(20),
    DateOfBirth DATE,
    MaritalStatus NVARCHAR(20),
    MobileNumber NVARCHAR(20),
    Email NVARCHAR(100),
    Address NVARCHAR(300),
    City NVARCHAR(100),
    DepartmentID INT,
    DesignationID INT,
    DateOfJoining DATE,
    EmploymentType NVARCHAR(50),
    Shift NVARCHAR(50),
    BankName NVARCHAR(100),
    BankAccountNumber NVARCHAR(50),
    BasicSalary DECIMAL(18,2),
    EmploymentStatus NVARCHAR(50),
    ProfilePicture NVARCHAR(300),
    CreatedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Employee_Department FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID),
    CONSTRAINT FK_Employee_Designation FOREIGN KEY (DesignationID) REFERENCES Designations(DesignationID)
);

CREATE TABLE EmployeeDocuments (
    DocumentID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT,
    DocumentName NVARCHAR(100),
    FilePath NVARCHAR(300),
    UploadDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Documents_Employee FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
);

CREATE TABLE SalaryStructures (
    SalaryStructureID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT,
    BasicSalary DECIMAL(18,2),
    GrossSalary DECIMAL(18,2),
    NetSalary DECIMAL(18,2),
    EffectiveDate DATE,
    CONSTRAINT FK_Salary_Employee FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
);

CREATE TABLE AllowanceTypes (
    AllowanceTypeID INT IDENTITY(1,1) PRIMARY KEY,
    AllowanceName NVARCHAR(100),
    AllowanceType NVARCHAR(20),      -- 'Fixed' or 'Percentage'
    DefaultValue DECIMAL(18,2)
);

CREATE TABLE EmployeeAllowances (
    EmployeeAllowanceID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT,
    AllowanceTypeID INT,
    Amount DECIMAL(18,2),
    EffectiveDate DATE,
    CONSTRAINT FK_EmployeeAllowance_Employee FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID),
    CONSTRAINT FK_EmployeeAllowance_Type FOREIGN KEY (AllowanceTypeID) REFERENCES AllowanceTypes(AllowanceTypeID)
);

CREATE TABLE DeductionTypes (
    DeductionTypeID INT IDENTITY(1,1) PRIMARY KEY,
    DeductionName NVARCHAR(100),
    DeductionType NVARCHAR(20),      -- 'Fixed' or 'Percentage'
    DefaultValue DECIMAL(18,2)
);

CREATE TABLE EmployeeDeductions (
    EmployeeDeductionID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT,
    DeductionTypeID INT,
    Amount DECIMAL(18,2),
    EffectiveDate DATE,
    CONSTRAINT FK_EmployeeDeduction_Employee FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID),
    CONSTRAINT FK_EmployeeDeduction_Type FOREIGN KEY (DeductionTypeID) REFERENCES DeductionTypes(DeductionTypeID)
);

CREATE TABLE Attendance (
    AttendanceID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT,
    AttendanceDate DATE,
    CheckIn TIME,
    CheckOut TIME,
    Status NVARCHAR(20),
    CONSTRAINT FK_Attendance_Employee FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
);

CREATE TABLE Leaves (
    LeaveID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT,
    LeaveType NVARCHAR(50),
    FromDate DATE,
    ToDate DATE,
    TotalDays INT,
    Reason NVARCHAR(300),
    Status NVARCHAR(30),
    CONSTRAINT FK_Leave_Employee FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
);

CREATE TABLE Payrolls (
    PayrollID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT,
    PayrollMonth INT,
    PayrollYear INT,
    BasicSalary DECIMAL(18,2),
    GrossSalary DECIMAL(18,2),
    TotalAllowance DECIMAL(18,2),
    TotalDeduction DECIMAL(18,2),
    NetSalary DECIMAL(18,2),
    PayrollStatus NVARCHAR(30),
    GeneratedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Payroll_Employee FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
);

CREATE TABLE PayrollDetails (
    PayrollDetailID INT IDENTITY(1,1) PRIMARY KEY,
    PayrollID INT,
    ComponentName NVARCHAR(100),
    ComponentType NVARCHAR(20),      -- 'Allowance' or 'Deduction'
    Amount DECIMAL(18,2),
    CONSTRAINT FK_PayrollDetails_Payroll FOREIGN KEY (PayrollID) REFERENCES Payrolls(PayrollID)
);
GO

PRINT 'Tables created.';
GO

/* ========= SAFETY NET: wipe all data before re-seeding =========
   Makes this script safe to re-run no matter how it's executed
   (whole script, or just re-running a later section) - clears
   every table in FK-safe order and resets identities back to 0,
   so EMS-0001 etc. never collides with leftover rows. */

DELETE FROM PayrollDetails;
DELETE FROM Payrolls;
DELETE FROM Attendance;
DELETE FROM Leaves;
DELETE FROM EmployeeDeductions;
DELETE FROM EmployeeAllowances;
DELETE FROM SalaryStructures;
DELETE FROM EmployeeDocuments;
DELETE FROM Employees;
DELETE FROM Users;
DELETE FROM Designations;
DELETE FROM Departments;
DELETE FROM DeductionTypes;
DELETE FROM AllowanceTypes;
DELETE FROM Roles;

DBCC CHECKIDENT ('PayrollDetails', RESEED, 0);
DBCC CHECKIDENT ('Payrolls', RESEED, 0);
DBCC CHECKIDENT ('Attendance', RESEED, 0);
DBCC CHECKIDENT ('Leaves', RESEED, 0);
DBCC CHECKIDENT ('EmployeeDeductions', RESEED, 0);
DBCC CHECKIDENT ('EmployeeAllowances', RESEED, 0);
DBCC CHECKIDENT ('SalaryStructures', RESEED, 0);
DBCC CHECKIDENT ('EmployeeDocuments', RESEED, 0);
DBCC CHECKIDENT ('Employees', RESEED, 0);
DBCC CHECKIDENT ('Users', RESEED, 0);
DBCC CHECKIDENT ('Designations', RESEED, 0);
DBCC CHECKIDENT ('Departments', RESEED, 0);
DBCC CHECKIDENT ('DeductionTypes', RESEED, 0);
DBCC CHECKIDENT ('AllowanceTypes', RESEED, 0);
DBCC CHECKIDENT ('Roles', RESEED, 0);

PRINT 'All tables cleared and identities reset - starting from a guaranteed clean slate.';
GO

/* ============================ HELPER NAME POOLS ============================ */

CREATE TABLE #FirstNames (Name NVARCHAR(50), Gender NVARCHAR(10));
INSERT INTO #FirstNames VALUES
('Ahmed','Male'),('Ali','Male'),('Bilal','Male'),('Danish','Male'),('Faisal','Male'),
('Hamza','Male'),('Imran','Male'),('Kashif','Male'),('Moiz','Male'),('Naveed','Male'),
('Osman','Male'),('Qasim','Male'),('Rashid','Male'),('Saad','Male'),('Tariq','Male'),
('Umar','Male'),('Waqas','Male'),('Yasir','Male'),('Zain','Male'),('Adeel','Male'),
('Amna','Female'),('Ayesha','Female'),('Bushra','Female'),('Fatima','Female'),('Hina','Female'),
('Iqra','Female'),('Javeria','Female'),('Kiran','Female'),('Mahnoor','Female'),('Nadia','Female'),
('Sana','Female'),('Sidra','Female'),('Tahira','Female'),('Uzma','Female'),('Warda','Female'),
('Zainab','Female'),('Rabia','Female'),('Saba','Female'),('Mehwish','Female'),('Anum','Female');

CREATE TABLE #LastNames (Name NVARCHAR(50));
INSERT INTO #LastNames VALUES
('Khan'),('Malik'),('Butt'),('Sheikh'),('Chaudhary'),('Raza'),('Hussain'),('Iqbal'),
('Farooq'),('Siddiqui'),('Awan'),('Qureshi'),('Abbasi'),('Baig'),('Cheema'),('Gill'),
('Javed'),('Latif'),('Mahmood'),('Rizvi');

CREATE TABLE #Cities (Name NVARCHAR(50));
INSERT INTO #Cities VALUES
('Rawalpindi'),('Islamabad'),('Lahore'),('Karachi'),('Faisalabad'),
('Multan'),('Peshawar'),('Quetta'),('Sialkot'),('Gujranwala');

CREATE TABLE #Banks (Name NVARCHAR(50));
INSERT INTO #Banks VALUES
('HBL'),('UBL'),('MCB'),('Meezan Bank'),('Allied Bank'),('Bank Alfalah'),('Standard Chartered');

/* A generic tally / numbers table, big enough for our largest loop (50,000+) */
CREATE TABLE #Tally (N INT PRIMARY KEY);
INSERT INTO #Tally (N)
SELECT TOP (60000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
FROM sys.all_objects a CROSS JOIN sys.all_objects b;

PRINT 'Helper name pools and tally table ready.';
GO

/* ============================ LOOKUP DATA ============================ */

INSERT INTO Departments (DepartmentName, Description) VALUES
('Human Resources','HR operations and recruitment'),
('Finance','Accounts and financial planning'),
('Information Technology','Software and infrastructure'),
('Sales','Client acquisition and revenue'),
('Marketing','Branding and campaigns'),
('Operations','Day to day business operations'),
('Customer Support','Post-sale customer service'),
('Administration','General admin and facilities'),
('Research and Development','Product research'),
('Legal','Compliance and contracts'),
('Procurement','Purchasing and vendor management'),
('Quality Assurance','Testing and quality control'),
('Logistics','Supply chain and delivery'),
('Training and Development','Employee training programs'),
('Public Relations','External communications'),
('Business Development','Partnerships and growth'),
('Data Analytics','Business intelligence'),
('Security','Physical and information security'),
('Facilities Management','Office and building management'),
('Internal Audit','Internal controls and audit');

INSERT INTO Designations (DesignationName, Description) VALUES
('Intern','Entry level trainee'),('Junior Executive','Entry level'),('Executive','Mid level'),
('Senior Executive','Mid level'),('Team Lead','Mid level lead'),('Assistant Manager','Senior level'),
('Manager','Senior level'),('Senior Manager','Senior level'),('Associate Director','Lead level'),
('Director','Lead level'),('Officer','Entry level'),('Senior Officer','Mid level'),
('Coordinator','Entry level'),('Senior Coordinator','Mid level'),('Analyst','Mid level'),
('Senior Analyst','Senior level'),('Specialist','Mid level'),('Senior Specialist','Senior level'),
('Supervisor','Mid level'),('Senior Supervisor','Senior level'),('Consultant','Senior level'),
('Senior Consultant','Lead level'),('Vice President','Lead level'),('Head of Department','Lead level'),
('Chief Officer','Lead level'),('Trainee','Entry level'),('Administrator','Entry level'),
('Senior Administrator','Mid level'),('Engineer','Mid level'),('Senior Engineer','Senior level'),
('Accountant','Mid level'),('Senior Accountant','Senior level'),('Auditor','Mid level'),
('Recruiter','Mid level'),('HR Business Partner','Senior level'),('Sales Representative','Entry level'),
('Sales Manager','Senior level'),('Marketing Executive','Mid level'),('Support Agent','Entry level'),
('Support Lead','Mid level'),('Operations Manager','Senior level');

INSERT INTO Roles (RoleName, Description) VALUES
('Admin','Full system access'),
('HR Manager','Manages employee records and HR operations'),
('Finance Manager','Manages payroll and financial data'),
('Employee','Self-service access only'),
('Auditor','Read-only access to reports');

-- Password hashes below are placeholder SHA256-style strings for demo only -
-- never store real plaintext or reversible passwords in a real system.
-- RoleID is looked up by name (not hardcoded) so this can never drift out
-- of sync with whatever identity values Roles actually ended up with.
INSERT INTO Users (FullName, Username, PasswordHash, Email, RoleID) VALUES
('System Admin','admin','$2a$11$demoHashPlaceholder0000000000000000000000000000000001','admin@company.com',(SELECT RoleID FROM Roles WHERE RoleName='Admin')),
('Sara Ahmed','sara.hr','$2a$11$demoHashPlaceholder0000000000000000000000000000000002','sara.hr@company.com',(SELECT RoleID FROM Roles WHERE RoleName='HR Manager')),
('Bilal Iqbal','bilal.finance','$2a$11$demoHashPlaceholder0000000000000000000000000000000003','bilal.finance@company.com',(SELECT RoleID FROM Roles WHERE RoleName='Finance Manager')),
('Ayesha Malik','ayesha.hr','$2a$11$demoHashPlaceholder0000000000000000000000000000000004','ayesha.hr@company.com',(SELECT RoleID FROM Roles WHERE RoleName='HR Manager')),
('Omar Farooq','omar.finance','$2a$11$demoHashPlaceholder0000000000000000000000000000000005','omar.finance@company.com',(SELECT RoleID FROM Roles WHERE RoleName='Finance Manager')),
('Hina Sheikh','hina.audit','$2a$11$demoHashPlaceholder0000000000000000000000000000000006','hina.audit@company.com',(SELECT RoleID FROM Roles WHERE RoleName='Auditor')),
('Zain Raza','zain.emp','$2a$11$demoHashPlaceholder0000000000000000000000000000000007','zain.emp@company.com',(SELECT RoleID FROM Roles WHERE RoleName='Employee')),
('Nadia Khan','nadia.emp','$2a$11$demoHashPlaceholder0000000000000000000000000000000008','nadia.emp@company.com',(SELECT RoleID FROM Roles WHERE RoleName='Employee')),
('Faisal Butt','faisal.admin','$2a$11$demoHashPlaceholder0000000000000000000000000000000009','faisal.admin@company.com',(SELECT RoleID FROM Roles WHERE RoleName='Admin')),
('Kiran Awan','kiran.hr','$2a$11$demoHashPlaceholder0000000000000000000000000000000010','kiran.hr@company.com',(SELECT RoleID FROM Roles WHERE RoleName='HR Manager'));

INSERT INTO AllowanceTypes (AllowanceName, AllowanceType, DefaultValue) VALUES
('House Rent Allowance','Percentage',45),
('Medical Allowance','Percentage',10),
('Conveyance Allowance','Fixed',8000),
('Fuel Allowance','Fixed',10000),
('Utility Allowance','Fixed',3000),
('Mobile Allowance','Fixed',2000),
('Internet Allowance','Fixed',2500),
('Overtime','Fixed',5000),
('Special Allowance','Fixed',4000),
('Bonus','Fixed',0),
('Other Allowances','Fixed',0);

INSERT INTO DeductionTypes (DeductionName, DeductionType, DefaultValue) VALUES
('Income Tax','Percentage',5),
('EOBI','Fixed',370),
('Provident Fund','Percentage',8.33),
('Loan Recovery','Fixed',0),
('Advance Salary','Fixed',0),
('Late Attendance','Fixed',0),
('Leave Deduction','Fixed',0),
('Absent Deduction','Fixed',0),
('Insurance','Fixed',1500),
('Other Deductions','Fixed',0);

PRINT 'Lookup data inserted: 20 Departments, 40 Designations, 5 Roles, 10 Users, 11 AllowanceTypes, 10 DeductionTypes.';
GO

/* ============================ 500 EMPLOYEES ============================ */
/* Set-based generation: each row independently randomized via NEWID().     */

;WITH GeneratedEmployees AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL))                                       AS RowNum,
        fn.Name + ' ' + ln.Name                                                          AS FullName,
        ffn.Name + ' ' + ln.Name                                                         AS FatherName,
        CAST(ABS(CHECKSUM(NEWID())) % 90000 + 10000 AS VARCHAR(5)) + '-' +
            CAST(ABS(CHECKSUM(NEWID())) % 9000000 + 1000000 AS VARCHAR(7)) + '-' +
            CAST(ABS(CHECKSUM(NEWID())) % 9 + 1 AS VARCHAR(1))                           AS CNIC,
        fn.Gender                                                                        AS Gender,
        DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 12045 + 8030), CAST(GETDATE() AS DATE))  AS DateOfBirth,
        CASE ABS(CHECKSUM(NEWID())) % 4
            WHEN 0 THEN 'Single' WHEN 1 THEN 'Married' WHEN 2 THEN 'Divorced' ELSE 'Widowed' END AS MaritalStatus,
        '03' + CAST(ABS(CHECKSUM(NEWID())) % 10 AS VARCHAR(1)) +
            CAST(ABS(CHECKSUM(NEWID())) % 9000000 + 1000000 AS VARCHAR(7))               AS MobileNumber,
        fn.Name                                                                          AS FnRaw,
        ln.Name                                                                          AS LnRaw,
        'House ' + CAST(ABS(CHECKSUM(NEWID())) % 999 + 1 AS VARCHAR(4)) + ', Street ' +
            CAST(ABS(CHECKSUM(NEWID())) % 50 + 1 AS VARCHAR(3))                          AS Address,
        city.Name                                                                        AS City,
        dept.DepartmentID                                                                AS DepartmentID,
        desig.DesignationID                                                              AS DesignationID,
        DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 2190 + 30), CAST(GETDATE() AS DATE))     AS DateOfJoining,
        CASE ABS(CHECKSUM(NEWID())) % 4
            WHEN 0 THEN 'Full-Time' WHEN 1 THEN 'Part-Time' WHEN 2 THEN 'Contract' ELSE 'Internship' END AS EmploymentType,
        CASE ABS(CHECKSUM(NEWID())) % 4
            WHEN 0 THEN 'Morning' WHEN 1 THEN 'Evening' WHEN 2 THEN 'Night' ELSE 'General' END AS Shift,
        bank.Name                                                                        AS BankName,
        CAST(ABS(CHECKSUM(NEWID())) % 900000000 + 100000000 AS VARCHAR(9))               AS BankAccountNumber,
        CASE desig.Level
            WHEN 'Entry'  THEN (ABS(CHECKSUM(NEWID())) % 20 + 35) * 1000
            WHEN 'Mid'    THEN (ABS(CHECKSUM(NEWID())) % 50 + 60) * 1000
            WHEN 'Senior' THEN (ABS(CHECKSUM(NEWID())) % 100 + 120) * 1000
            ELSE                (ABS(CHECKSUM(NEWID())) % 150 + 250) * 1000
        END                                                                              AS BasicSalary,
        CASE WHEN ABS(CHECKSUM(NEWID())) % 100 < 88 THEN 'Active'
             WHEN ABS(CHECKSUM(NEWID())) % 100 < 93 THEN 'On Leave'
             WHEN ABS(CHECKSUM(NEWID())) % 100 < 97 THEN 'Resigned'
             ELSE 'Terminated' END                                                       AS EmploymentStatus
    FROM (SELECT TOP (500) N FROM #Tally ORDER BY N) t
    CROSS APPLY (SELECT TOP 1 Name, Gender FROM #FirstNames ORDER BY NEWID()) fn
    CROSS APPLY (SELECT TOP 1 Name FROM #FirstNames ORDER BY NEWID()) ffn
    CROSS APPLY (SELECT TOP 1 Name FROM #LastNames ORDER BY NEWID()) ln
    CROSS APPLY (SELECT TOP 1 Name FROM #Cities ORDER BY NEWID()) city
    CROSS APPLY (SELECT TOP 1 Name FROM #Banks ORDER BY NEWID()) bank
    CROSS APPLY (SELECT TOP 1 DepartmentID FROM Departments ORDER BY NEWID()) dept
    CROSS APPLY (SELECT TOP 1 DesignationID,
                        CASE WHEN DesignationID % 4 = 1 THEN 'Entry'
                             WHEN DesignationID % 4 = 2 THEN 'Mid'
                             WHEN DesignationID % 4 = 3 THEN 'Senior'
                             ELSE 'Lead' END AS Level
                 FROM Designations ORDER BY NEWID()) desig
)
INSERT INTO Employees
    (EmployeeCode, FullName, FatherName, CNIC, Gender, DateOfBirth, MaritalStatus,
     MobileNumber, Email, Address, City, DepartmentID, DesignationID, DateOfJoining,
     EmploymentType, Shift, BankName, BankAccountNumber, BasicSalary, EmploymentStatus)
SELECT
    'EMS-' + RIGHT('0000' + CAST(RowNum AS VARCHAR(4)), 4),
    FullName,
    FatherName,
    CNIC,
    Gender,
    DateOfBirth,
    MaritalStatus,
    MobileNumber,
    LOWER(FnRaw) + '.' + LOWER(LnRaw) + CAST(RowNum AS VARCHAR(4)) + '@company.com',
    Address,
    City,
    DepartmentID,
    DesignationID,
    DateOfJoining,
    EmploymentType,
    Shift,
    BankName,
    BankAccountNumber,
    BasicSalary,
    EmploymentStatus
FROM GeneratedEmployees;

PRINT 'Employees inserted: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows (target 500).';
GO

/* ============================ SALARY STRUCTURES (500) ============================ */

INSERT INTO SalaryStructures (EmployeeID, BasicSalary, GrossSalary, NetSalary, EffectiveDate)
SELECT EmployeeID, BasicSalary, BasicSalary, BasicSalary, DateOfJoining
FROM Employees;

PRINT 'SalaryStructures inserted: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows.';
GO

/* ============================ EMPLOYEE ALLOWANCES (~3000: 6 per employee) ============================ */

INSERT INTO EmployeeAllowances (EmployeeID, AllowanceTypeID, Amount, EffectiveDate)
SELECT e.EmployeeID, pick.AllowanceTypeID,
       CASE WHEN pick.AllowanceType = 'Percentage'
            THEN ROUND(e.BasicSalary * pick.DefaultValue / 100.0, 2)
            ELSE pick.DefaultValue END,
       e.DateOfJoining
FROM Employees e
CROSS APPLY (SELECT TOP 6 AllowanceTypeID, AllowanceType, DefaultValue
             FROM AllowanceTypes ORDER BY NEWID()) pick;

PRINT 'EmployeeAllowances inserted: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows (target ~3000).';
GO

/* ============================ EMPLOYEE DEDUCTIONS (~2500: 5 per employee) ============================ */

INSERT INTO EmployeeDeductions (EmployeeID, DeductionTypeID, Amount, EffectiveDate)
SELECT e.EmployeeID, pick.DeductionTypeID,
       CASE WHEN pick.DeductionType = 'Percentage'
            THEN ROUND(e.BasicSalary * pick.DefaultValue / 100.0, 2)
            WHEN pick.DeductionName = 'Loan Recovery'
            THEN (ABS(CHECKSUM(NEWID())) % 16 + 5) * 1000
            ELSE pick.DefaultValue END,
       e.DateOfJoining
FROM Employees e
CROSS APPLY (SELECT TOP 5 DeductionTypeID, DeductionType, DefaultValue, DeductionName
             FROM DeductionTypes ORDER BY NEWID()) pick;

PRINT 'EmployeeDeductions inserted: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows (target ~2500).';
GO

/* ============================ ATTENDANCE (~50,000: 100 working days x 500 employees) ============================ */

INSERT INTO Attendance (EmployeeID, AttendanceDate, CheckIn, CheckOut, Status)
SELECT e.EmployeeID,
       d.AttDate,
       CASE WHEN d.Roll < 88 THEN DATEADD(MINUTE, ABS(CHECKSUM(NEWID())) % 45, '09:00') ELSE NULL END,
       CASE WHEN d.Roll < 88 THEN DATEADD(MINUTE, ABS(CHECKSUM(NEWID())) % 45, '17:00') ELSE NULL END,
       CASE WHEN d.Roll < 78 THEN 'Present'
            WHEN d.Roll < 88 THEN 'Late'
            WHEN d.Roll < 94 THEN 'Leave'
            ELSE 'Absent' END
FROM Employees e
CROSS APPLY (
    SELECT TOP (100)
           DATEADD(DAY, -t.N, CAST(GETDATE() AS DATE)) AS AttDate,
           ABS(CHECKSUM(NEWID())) % 100 AS Roll
    FROM #Tally t
    WHERE DATEPART(WEEKDAY, DATEADD(DAY, -t.N, CAST(GETDATE() AS DATE))) NOT IN (1,7)  -- skip Sat/Sun
    ORDER BY t.N
) d;

PRINT 'Attendance inserted: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows (target ~50,000).';
GO

/* ============================ LEAVES (~1000) ============================ */

INSERT INTO Leaves (EmployeeID, LeaveType, FromDate, ToDate, TotalDays, Reason, Status)
SELECT emp.EmployeeID,
       CASE ABS(CHECKSUM(NEWID())) % 4 WHEN 0 THEN 'Casual' WHEN 1 THEN 'Sick' WHEN 2 THEN 'Annual' ELSE 'Unpaid' END,
       sd.startDate,
       DATEADD(DAY, dc.dayCount - 1, sd.startDate),
       dc.dayCount,
       'Personal reasons',
       CASE ABS(CHECKSUM(NEWID())) % 3 WHEN 0 THEN 'Pending' WHEN 1 THEN 'Approved' ELSE 'Rejected' END
FROM (SELECT TOP (1000) N FROM #Tally) t
CROSS APPLY (SELECT TOP 1 EmployeeID FROM Employees ORDER BY NEWID()) emp
CROSS APPLY (SELECT DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 300), CAST(GETDATE() AS DATE)) AS startDate) sd
CROSS APPLY (SELECT ABS(CHECKSUM(NEWID())) % 4 + 1 AS dayCount) dc;

PRINT 'Leaves inserted: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows (target 1000).';
GO

/* ============================ PAYROLLS (6000: 500 employees x 12 months) ============================ */

;WITH MonthTally AS (
    SELECT TOP (12) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS MonthsAgo
    FROM sys.all_objects
),
EmpTotals AS (
    SELECT e.EmployeeID, e.BasicSalary,
           ISNULL((SELECT SUM(Amount) FROM EmployeeAllowances WHERE EmployeeID = e.EmployeeID), 0) AS TotalAllowance,
           ISNULL((SELECT SUM(Amount) FROM EmployeeDeductions WHERE EmployeeID = e.EmployeeID), 0) AS TotalDeduction
    FROM Employees e
)
INSERT INTO Payrolls (EmployeeID, PayrollMonth, PayrollYear, BasicSalary, GrossSalary, TotalAllowance, TotalDeduction, NetSalary, PayrollStatus, GeneratedDate)
SELECT
    et.EmployeeID,
    MONTH(DATEADD(MONTH, -mt.MonthsAgo, GETDATE())),
    YEAR(DATEADD(MONTH, -mt.MonthsAgo, GETDATE())),
    et.BasicSalary,
    et.BasicSalary + et.TotalAllowance,
    et.TotalAllowance,
    et.TotalDeduction,
    (et.BasicSalary + et.TotalAllowance) - et.TotalDeduction,
    CASE WHEN mt.MonthsAgo = 0 THEN 'Draft' ELSE 'Paid' END,
    DATEADD(MONTH, -mt.MonthsAgo, GETDATE())
FROM EmpTotals et
CROSS JOIN MonthTally mt;

PRINT 'Payrolls inserted: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows (target 6000).';
GO

/* ============================ PAYROLL DETAILS (30,000+: line items per payroll) ============================ */

INSERT INTO PayrollDetails (PayrollID, ComponentName, ComponentType, Amount)
SELECT p.PayrollID, at.AllowanceName, 'Allowance', ea.Amount
FROM Payrolls p
JOIN EmployeeAllowances ea ON ea.EmployeeID = p.EmployeeID
JOIN AllowanceTypes at ON at.AllowanceTypeID = ea.AllowanceTypeID;

PRINT 'PayrollDetails (allowance lines) inserted: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows.';

INSERT INTO PayrollDetails (PayrollID, ComponentName, ComponentType, Amount)
SELECT p.PayrollID, dt.DeductionName, 'Deduction', ed.Amount
FROM Payrolls p
JOIN EmployeeDeductions ed ON ed.EmployeeID = p.EmployeeID
JOIN DeductionTypes dt ON dt.DeductionTypeID = ed.DeductionTypeID;

PRINT 'PayrollDetails (deduction lines) inserted: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows total should now exceed 30,000.';
GO

/* ============================ EMPLOYEE DOCUMENTS (1000: 2 per employee) ============================ */

INSERT INTO EmployeeDocuments (EmployeeID, DocumentName, FilePath, UploadDate)
SELECT e.EmployeeID, docType.DocName,
       '/uploads/employees/' + CAST(e.EmployeeID AS VARCHAR) + '/' + LOWER(REPLACE(docType.DocName,' ','_')) + '.pdf',
       e.DateOfJoining
FROM Employees e
CROSS APPLY (VALUES ('CNIC Copy'), ('Resume')) docType(DocName);

PRINT 'EmployeeDocuments inserted: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows (target 1000).';
GO

/* ============================ CLEANUP ============================ */
DROP TABLE #FirstNames;
DROP TABLE #LastNames;
DROP TABLE #Cities;
DROP TABLE #Banks;
DROP TABLE #Tally;
GO

/* ============================ VERIFY ============================ */

SELECT 'Departments' AS TableName, COUNT(*) AS Rows FROM Departments
UNION ALL SELECT 'Designations', COUNT(*) FROM Designations
UNION ALL SELECT 'Roles', COUNT(*) FROM Roles
UNION ALL SELECT 'Users', COUNT(*) FROM Users
UNION ALL SELECT 'Employees', COUNT(*) FROM Employees
UNION ALL SELECT 'EmployeeDocuments', COUNT(*) FROM EmployeeDocuments
UNION ALL SELECT 'SalaryStructures', COUNT(*) FROM SalaryStructures
UNION ALL SELECT 'AllowanceTypes', COUNT(*) FROM AllowanceTypes
UNION ALL SELECT 'EmployeeAllowances', COUNT(*) FROM EmployeeAllowances
UNION ALL SELECT 'DeductionTypes', COUNT(*) FROM DeductionTypes
UNION ALL SELECT 'EmployeeDeductions', COUNT(*) FROM EmployeeDeductions
UNION ALL SELECT 'Attendance', COUNT(*) FROM Attendance
UNION ALL SELECT 'Leaves', COUNT(*) FROM Leaves
UNION ALL SELECT 'Payrolls', COUNT(*) FROM Payrolls
UNION ALL SELECT 'PayrollDetails', COUNT(*) FROM PayrollDetails
ORDER BY TableName;
GO

PRINT '=====================================================';
PRINT 'EMSDB setup complete. Check the row counts above.';
PRINT '=====================================================';
select * from employees ;
select * from Departments;

USE EMSDB;
GO

-- 1. What columns does Employees ACTUALLY have right now?
SELECT COLUMN_NAME, DATA_TYPE, ORDINAL_POSITION
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Employees'
ORDER BY ORDINAL_POSITION;

-- 2. How many rows does it have?
SELECT COUNT(*) AS EmployeeRowCount FROM Employees;

-- 3. What do the first 5 rows actually look like?
SELECT TOP 5 * FROM Employees;
GO

