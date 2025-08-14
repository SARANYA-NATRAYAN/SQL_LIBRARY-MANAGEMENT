--Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
SELECT * FROM books;

--Task 2: Update an Existing Member's Address
UPDATE members
SET member_address = '101 Cresent Street'
WHERE member_id = 'C101';

--Task 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.

DELETE FROM issued_status
WHERE   issued_id =   'IS121';
-- here we cannot delete the issued_id which are linked with other table, ex: IS120 is linked with other table as foreign ke so it will not be deleted

--Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.

SELECT * FROM issued_status
WHERE issued_emp_id = 'E101'

--Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.

SELECT issued_emp_id,COUNT(*)
FROM issued_status
GROUP BY 1
HAVING COUNT(*) > 1

--CTAS (Create Table As Select)
--Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**

CREATE TABLE book_issued_count
AS
SELECT b.isbn, b.book_title,count(ist.issued_id) as No_of_issued
FROM books as b
JOIN issued_status as ist
ON b.isbn = ist.issued_book_isbn
GROUP BY b.isbn,b.book_title;

select * from book_issued_count;

--Task 7. Retrieve All Books in a Specific Category:

select * from books
where category='Fantasy';

--Task 8: Find Total Rental Income by Category:
select b.category, sum(b.rental_price), count(*) as No_of_times from books as b
join  issued_status as ist
on b.isbn= ist.issued_book_isbn
group by  b.category;

--Task9:List Members Who Registered in the Last 180 Days:
select * from members
where reg_date >= current_date - interval '180 day';

insert into members(member_id,member_name,member_address,reg_date)
values('C117','Vinoth','101 Aljunied Cresent','2025-06-08'),
('C112','Saranya','M47 Periyar Nagar','2025-06-20')

--Task10: List Employees with Their Branch Manager's Name and their branch details:
select e1.*, b.manager_id,e2.emp_name as manager  from employees as e1
join branch as b
on b.branch_id= e1.branch_id
join employees as e2
on b.manager_id = e2.emp_id

--Task11: Create a Table of Books with Rental Price Above a Certain Threshold:
create table booksPriceAbv7
as
select * from books
where rental_price>7;

select * from booksPriceAbv7;

--Task 12: Retrieve the List of Books Not Yet Returned
select * from issued_status as i
left join return_status as r
on i.issued_id= r.issued_id
where r.return_id is null;

-- INSERT INTO book_issued in last 30 days
-- SELECT * from employees;
-- SELECT * from books;
-- SELECT * from members;
-- SELECT * from issued_status


INSERT INTO issued_status(issued_id, issued_member_id, issued_book_name, issued_date, issued_book_isbn, issued_emp_id)
VALUES
('IS151', 'C118', 'The Catcher in the Rye', CURRENT_DATE - INTERVAL '24 days',  '978-0-553-29698-2', 'E108'),
('IS152', 'C119', 'The Catcher in the Rye', CURRENT_DATE - INTERVAL '13 days',  '978-0-553-29698-2', 'E109'),
('IS153', 'C106', 'Pride and Prejudice', CURRENT_DATE - INTERVAL '7 days',  '978-0-14-143951-8', 'E107'),
('IS154', 'C105', 'The Road', CURRENT_DATE - INTERVAL '32 days',  '978-0-375-50167-0', 'E101');

-- Adding new column in return_status

ALTER TABLE return_status
ADD Column book_quality VARCHAR(15) DEFAULT('Good');

UPDATE return_status
SET book_quality = 'Damaged'
WHERE issued_id 
    IN ('IS112', 'IS117', 'IS118');
SELECT * FROM return_status;

--Day 2

SELECT * from return_status;

/*Task 13: Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period). 
Display the member's_id, member's name, book title, issue date, and days overdue.
*/
-- issued_status==members==books==return_status
--book return status
--overdue 30 days return period

select 
i.issued_member_id,
m.member_name,
b.book_title,
i.issued_date,
r.return_date,
current_date - i.issued_date as overdue_days
from issued_status as i
join members as m
on m.member_id = i.issued_member_id
join books as b
on b.isbn= i.issued_book_isbn
left join return_status as r
on r.issued_id= i.issued_id
where r.return_date is null 
and (current_date - i.issued_date)>30
order by i.issued_member_id

/*
Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).
*/

create or replace procedure add_return_status(p_return_id varchar(10), p_issued_id varchar(10), p_book_quality varchar(15))
language plpgsql
as
$$

declare
v_isbn varchar(20);
v_book_name varchar(70);

begin
-- all your logic and code
-- inserting into returns based on users input

insert into return_status(return_id,issued_id,return_date,book_quality)
values(p_return_id, p_issued_id,current_date,p_book_quality);

select issued_book_isbn, issued_book_name
into v_isbn,v_book_name
from issued_status
where issued_id= p_issued_id;

update books
set status='yes'
where isbn= v_isbn;

raise notice 'Thank you for returning the book %', v_book_name;
end;
$$

-- Testing FUNCTION add_return_records

SELECT * FROM books
WHERE isbn = '978-0-7432-7357-1';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-7432-7357-1';

SELECT * FROM return_status
WHERE issued_id = 'IS136';

--calling function
call add_return_status ('RS119','IS135','Good');
call add_return_status ('RS120','IS136','Damaged');

/*Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, 
showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.
*/

create table branch_performance_report
as
select 
b.branch_id,
b.manager_id,
count(i.issued_id) as no_of_books_issued,
count(r.return_id) as no_of_books_returned,
sum(bs.rental_price) as total_revenue
from issued_status as i
join employees as e 
on i.issued_emp_id = e.emp_id
join branch as b 
on b.branch_id=e.branch_id
join return_status as r
on r.issued_id = i.issued_id
join books as bs
on bs.isbn= i.issued_book_isbn
group by b.branch_id,b.manager_id;

select * from branch_performance_report;

/*Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued 
at least one book in the last 2 months.
*/
create table active_members
as
select * from members
where member_id  in (select distinct(issued_member_id) from issued_status
where issued_date >= current_date - interval '2 month');

select * from active_members;

/*Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues. 
Display the employee name, number of books processed, and their branch.*/

select e.emp_id, e.emp_name,
count(i.issued_id) as no_of_book_issued,
b.branch_id
from issued_status as i
join employees as e
on i.issued_emp_id = e.emp_id
join branch as b
on b.branch_id= e.branch_id
group by e.emp_id, b.branch_id
order by count(i.issued_id) desc
limit 3;

/*
Task 19: Stored Procedure Objective: 
Create a stored procedure to manage the status of books in a library system. 
Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 
The procedure should function as follows: The stored procedure should take the book_id as an input parameter. 
The procedure should first check if the book is available (status = 'yes'). 
If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.
*/
select * from issued_status
select * from books
create or replace procedure manage_book_status(p_issued_id varchar(10), p_issued_member_id varchar(10),p_issued_book_isbn varchar(30)
,p_issued_emp_id varchar(10))
language plpgsql
as
$$
declare
	v_status varchar(10);
	v_book_name varchar(70);
begin
	select status, book_title
	into v_status, v_book_name
	from books
	where isbn = p_issued_book_isbn;

	
	
	if v_status='yes' then
	insert into issued_status(issued_id, issued_member_id, issued_book_name, issued_date,issued_book_isbn, issued_emp_id)
	values(p_issued_id,p_issued_member_id,v_book_name, current_date, p_issued_book_isbn, p_issued_emp_id);

	update books
	set status ='no'
	where isbn = p_issued_book_isbn;
	
	raise notice 'Book added successfully in the record: %', v_book_name;
	
	else
	
	raise notice 'Book is cuurently unavailable: %', v_book_name;
	
	end if;
end;
$$

call manage_book_status('IS155','C106','978-0-330-25864-8','E101')
call manage_book_status('IS156','C107','978-0-330-25864-8','E108')
call manage_book_status('IS157','C105','978-0-7432-7356-4','E106')


/*Task 20: Create Table As Select (CTAS) Objective: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.
Description: 
Write a CTAS query to create a new table that lists each member and the books they have issued but not returned within 30 days. 
The table should include: The number of overdue books. The total fines, with each day's fine calculated at $0.50. 
The number of books issued by each member. The resulting table should show: Member ID Number of overdue books Total fines*/
create table overdue_books_fines as 
select m.member_id,
count(*) as over_due,
SUM(
        CASE 
            WHEN CURRENT_DATE > i.issued_date + INTERVAL '30 days'
            THEN EXTRACT(DAY FROM CURRENT_DATE - (i.issued_date + INTERVAL '30 days')) * 0.50
            ELSE 0
        END
    ) AS total_fine
--SUM((CURRENT_DATE - i.issued_date - 30) * 0.50)
from issued_status as i
join members as m
on m.member_id= i.issued_member_id
left join return_status as r
on r.issued_id= i.issued_id
where 
r.return_date is null and 
i.issued_date <= current_date - interval'30 day'
group by m.member_id;

select * from overdue_books_fines;

/*Task 18: Identify Members Issuing High-Risk Books
Write a query to identify members who have issued books more than twice with the status "damaged" in the books table. 
Display the member name, book title, and the number of times they've issued damaged books.*/

select m.member_name, b.book_title, count(r.book_quality) as no_of_time_returned_damaged from issued_status as i
join members as m
on i.issued_member_id = m.member_id
join books as b
on b.isbn= i.issued_book_isbn
join return_status as r
on r.issued_id = i.issued_id
where book_quality='Damaged'
group by m.member_name,b.book_title
having count(r.book_quality)>2;




