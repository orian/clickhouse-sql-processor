-- Create the database
CREATE DATABASE IF NOT EXISTS movie_rentals;

-- Use the database
USE movie_rentals;

-- Create the customers table
CREATE TABLE IF NOT EXISTS customers (
    customer_id UUID     DEFAULT generateUUIDv4() PRIMARY KEY,
    first_name  String,
    last_name   String,
    email       String,
    phone       String,
    created_at  DateTime DEFAULT now()
) ENGINE = MergeTree()
      ORDER BY (customer_id);

-- Create the movies table
CREATE TABLE IF NOT EXISTS movies (
    movie_id         UUID DEFAULT generateUUIDv4() PRIMARY KEY,
    title            String,
    genre            String,
    release_year     UInt16,
    rental_rate      Decimal(10, 2),
    available_copies UInt16
) ENGINE = MergeTree()
      ORDER BY (movie_id);

-- Create the rentals table
CREATE TABLE IF NOT EXISTS rentals (
    rental_id   UUID     DEFAULT generateUUIDv4() PRIMARY KEY,
    customer_id UUID,
    movie_id    UUID,
    rental_date DateTime DEFAULT now(),
    return_date DateTime,
    FOREIGN     KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN     KEY (movie_id) REFERENCES movies(movie_id)
) ENGINE = MergeTree()
      ORDER BY (rental_id);

-- Insert some sample data into customers
INSERT INTO customers (first_name, last_name, email, phone)
VALUES ('John', 'Doe', 'john.doe@example.com', '555-123-4567'),
       ('Jane', 'Smith', 'jane.smith@example.com', '555-987-6543'),
       ('Peter', 'Jones', 'peter.jones@example.com', '555-111-2222');

-- Insert some sample data into movies
INSERT INTO movies (title, genre, release_year, rental_rate, available_copies)
VALUES ('The Matrix', 'Sci-Fi', 1999, 3.99, 5),
       ('Inception', 'Sci-Fi', 2010, 4.99, 3),
       ('The Shawshank Redemption', 'Drama', 1994, 2.99, 2),
       ('Pulp Fiction', 'Crime', 1994, 3.99, 4);

-- Insert some sample data into rentals
INSERT INTO rentals (customer_id, movie_id, return_date)
VALUES ((SELECT customer_id FROM movie_rentals.customers WHERE first_name = 'John'),
        (SELECT movie_id FROM movie_rentals.movies WHERE title = 'The Matrix'), '2024-01-20 10:00:00'),
       ((SELECT customer_id FROM movie_rentals.customers WHERE first_name = 'Jane'),
        (SELECT movie_id FROM movie_rentals.movies WHERE title = 'Inception'), '2024-01-22 12:00:00');