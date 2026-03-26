-- =====================================================
-- Small-Scale Library System
-- Clean PostgreSQL SQL script
-- =====================================================

-- Optional cleanup (safe order because of foreign keys)
DROP TABLE IF EXISTS loans CASCADE;
DROP TABLE IF EXISTS book_copy CASCADE;
DROP TABLE IF EXISTS book_authors CASCADE;
DROP TABLE IF EXISTS patrons CASCADE;
DROP TABLE IF EXISTS authors CASCADE;
DROP TABLE IF EXISTS books CASCADE;
DROP TABLE IF EXISTS category CASCADE;

-- =====================================================
-- 1. CATEGORY
-- =====================================================
CREATE TABLE category (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

-- =====================================================
-- 2. BOOKS
-- =====================================================
CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    isbn VARCHAR(20) UNIQUE,
    publication_year INT,
    publisher VARCHAR(150),
    category_id INT,
    CONSTRAINT fk_books_category
        FOREIGN KEY (category_id)
        REFERENCES category(category_id)
        ON DELETE SET NULL
);

-- =====================================================
-- 3. AUTHORS
-- =====================================================
CREATE TABLE authors (
    author_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE
);

-- =====================================================
-- 4. PATRONS
-- =====================================================
CREATE TABLE patrons (
    patron_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE,
    phone VARCHAR(30)
);

-- =====================================================
-- 5. BOOK_AUTHORS
-- Many-to-many relationship between books and authors
-- =====================================================
CREATE TABLE book_authors (
    book_id INT NOT NULL,
    author_id INT NOT NULL,
    PRIMARY KEY (book_id, author_id),
    CONSTRAINT fk_book_authors_book
        FOREIGN KEY (book_id)
        REFERENCES books(book_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_book_authors_author
        FOREIGN KEY (author_id)
        REFERENCES authors(author_id)
        ON DELETE CASCADE
);

-- =====================================================
-- 6. BOOK_COPY
-- Each row represents one physical copy of a book
-- =====================================================
CREATE TABLE book_copy (
    copy_id SERIAL PRIMARY KEY,
    book_id INT NOT NULL,
    barcode VARCHAR(50) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'available',
    location VARCHAR(100),
    acquisition_date DATE,
    CONSTRAINT fk_book_copy_book
        FOREIGN KEY (book_id)
        REFERENCES books(book_id)
        ON DELETE CASCADE,
    CONSTRAINT chk_book_copy_status
        CHECK (status IN ('available', 'loaned', 'reserved', 'lost', 'damaged'))
);

-- =====================================================
-- 7. LOANS
-- Loans are linked to a specific physical copy
-- =====================================================
CREATE TABLE loans (
    loan_id SERIAL PRIMARY KEY,
    copy_id INT NOT NULL,
    patron_id INT NOT NULL,
    loan_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE,
    CONSTRAINT fk_loans_copy
        FOREIGN KEY (copy_id)
        REFERENCES book_copy(copy_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_loans_patron
        FOREIGN KEY (patron_id)
        REFERENCES patrons(patron_id)
        ON DELETE RESTRICT,
    CONSTRAINT chk_loan_dates
        CHECK (due_date >= loan_date),
    CONSTRAINT chk_return_date
        CHECK (return_date IS NULL OR return_date >= loan_date)
);

-- =====================================================
-- SAMPLE DATA
-- At least 5 rows in each main table
-- =====================================================

-- CATEGORY
INSERT INTO category (name) VALUES
('Fantaasia'),
('Ulme'),
('Ajalugu'),
('Lastekirjandus'),
('Teadus');

-- AUTHORS
INSERT INTO authors (first_name, last_name, date_of_birth) VALUES
('J.K.', 'Rowling', '1965-07-31'),
('J.R.R.', 'Tolkien', '1892-01-03'),
('Andrus', 'Kivirähk', '1970-08-17'),
('Isaac', 'Asimov', '1920-01-02'),
('Tiit', 'Hennoste', '1953-02-07');

-- BOOKS
INSERT INTO books (title, isbn, publication_year, publisher, category_id) VALUES
('Harry Potter ja tarkade kivi', '9780747532699', 1997, 'Bloomsbury', 1),
('Kääbik', '9780261102217', 1937, 'Allen & Unwin', 1),
('Rehepapp', '9789985313022', 2000, 'Varrak', 4),
('Asumi sari', '9780553293357', 1951, 'Gnome Press', 2),
('Eesti kirjanduse ajalugu', '9789985223450', 2001, 'Tartu Ülikool', 3);

-- BOOK_AUTHORS
INSERT INTO book_authors (book_id, author_id) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5);

-- PATRONS
INSERT INTO patrons (first_name, last_name, email, phone) VALUES
('Mari', 'Tamm', 'mari.tamm@email.com', '5551111'),
('Jaan', 'Kask', 'jaan.kask@email.com', '5552222'),
('Liis', 'Saar', 'liis.saar@email.com', '5553333'),
('Karl', 'Mets', 'karl.mets@email.com', '5554444'),
('Anna', 'Põld', 'anna.pold@email.com', '5555555');

-- BOOK COPIES
INSERT INTO book_copy (book_id, barcode, status, location, acquisition_date) VALUES
(1, 'BC1001', 'available', 'Riiul A1', '2023-01-10'),
(1, 'BC1002', 'loaned', 'Riiul A1', '2023-01-10'),
(2, 'BC2001', 'available', 'Riiul B2', '2022-05-15'),
(3, 'BC3001', 'available', 'Riiul C3', '2021-09-20'),
(4, 'BC4001', 'loaned', 'Riiul D4', '2020-03-12'),
(5, 'BC5001', 'available', 'Riiul E5', '2024-02-01');

-- LOANS
INSERT INTO loans (copy_id, patron_id, loan_date, due_date, return_date) VALUES
(2, 1, '2026-03-01', '2026-03-15', NULL),
(4, 2, '2026-02-20', '2026-03-05', NULL),
(3, 3, '2026-01-10', '2026-01-24', '2026-01-20'),
(1, 4, '2026-02-01', '2026-02-14', '2026-02-10'),
(5, 5, '2026-03-10', '2026-03-24', NULL);

-- =====================================================
-- TASK 4 QUERIES
-- =====================================================

-- 1. List all books by a specified author
SELECT 
    b.book_id,
    b.title,
    b.publication_year,
    a.first_name,
    a.last_name
FROM books b
JOIN book_authors ba ON b.book_id = ba.book_id
JOIN authors a ON ba.author_id = a.author_id
WHERE a.first_name = 'J.K.'
  AND a.last_name = 'Rowling';

-- 2. Identify all patrons with overdue loans
SELECT DISTINCT
    p.patron_id,
    p.first_name,
    p.last_name,
    p.email,
    l.loan_id,
    l.loan_date,
    l.due_date
FROM patrons p
JOIN loans l ON p.patron_id = l.patron_id
WHERE l.return_date IS NULL
  AND l.due_date < CURRENT_DATE;

-- 3. List books that have never been borrowed
SELECT 
    b.book_id,
    b.title,
    b.publication_year,
    b.publisher
FROM books b
WHERE NOT EXISTS (
    SELECT 1
    FROM book_copy bc
    JOIN loans l ON bc.copy_id = l.copy_id
    WHERE bc.book_id = b.book_id
);

-- 4. Check whether a specific book is available in the library
SELECT 
    b.title,
    COUNT(bc.copy_id) AS total_copies,
    SUM(CASE WHEN bc.status = 'available' THEN 1 ELSE 0 END) AS available_copies
FROM books b
LEFT JOIN book_copy bc ON b.book_id = bc.book_id
WHERE b.title ILIKE '%harry potter%'
GROUP BY b.title;
