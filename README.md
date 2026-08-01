# EMSApp - ASP.NET Core MVC front-end for your EMSDB database

This app is built to match the **exact schema** of the `EMSDB` database you
already created and populated with `EMSDB_Full.sql` in SSMS - same table
names, same column names, same data types. It does **not** run migrations
and does **not** seed any data on startup: it just connects to the database
you already built and reads/writes it directly, so there's zero conflict
with the ~95,000 rows already in there.

## How to run

1. Make sure `EMSDB` already exists (you ran `EMSDB_Full.sql` in SSMS).
2. Open this folder in Visual Studio / VS Code.
3. Check `appsettings.json` - the connection string points to
   `(localdb)\mssqllocaldb` / database `EMSDB`. Change the server name only
   if you're using a different SQL Server instance than LocalDB.
4. `dotnet restore`
5. `dotnet run`
6. Open the URL shown in the console.

No `dotnet ef migrations` step needed this time - the database already exists.

## What's included (matches your project description)

- **Employees**: full CRUD, search by name/code/CNIC, filter by department
  and status, pagination (built for the 500-employee dataset), a Details
  page showing personal info, allowances, deductions, and full payroll
  history per employee.
- **Departments / Designations**: CRUD with live employee counts.
- **Payroll module**: a real calculation engine.
  - `Payroll > Generate` picks a month/year and computes, for every Active
    employee: `Gross = Basic + All Allowances`, `Net = Gross - All
    Deductions` - matching the formula in your project description exactly.
  - `Payroll > Index` lists that month's payroll with totals, and lets you
    Approve a Draft payroll.
  - `Payroll > Slip` is a printable salary slip per employee/month - use
    the browser's Print button and "Save as PDF" as the destination to get
    a PDF export without needing an extra library.
- **Reports**: Employee List, Department Wise Employees, Salary Register,
  Monthly Payroll Report, Net Salary Report, Employee Joining Report -
  covering most of the Reports module from your description directly from
  the database.

## Not yet built (say the word and I'll add these next)

- Excel export (would use a library like ClosedXML)
- Allowance/Deduction management screens (currently these are seeded via
  SQL and read-only in the app; add/edit UI for them is a natural next step)
- Login/authentication using the `Users`/`Roles` tables (currently the app
  has no login screen - anyone can access all pages)
- Attendance and Leave management screens (data exists and is seeded, just
  no CRUD UI for it yet)

## A note on two known SQL Server quirks these models work around

- `AllowanceType` and `DeductionType` tables each have a column with the
  *same name as the table*. In C#, the model classes rename that specific
  property to `Mode` (e.g. `AllowanceType.Mode`) and map it back to the
  real column with `[Column("AllowanceType")]` - this avoids a confusing
  C# class-name/property-name collision while still matching your database
  exactly.
- The `Leaves` table is mapped to a C# class called `LeaveRequest` (via
  `[Table("Leaves")]`), since naming a class `Leave` reads awkwardly next
  to LINQ query keywords in C#.
