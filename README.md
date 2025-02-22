# ClickHouse SQL processor

 * Parses
 * Transforms
 * Prints

# 

processing order
1. FROM - allow to get a tables and fields, this is a great start
2. SELECT - this is where we have all directly selected columns and expressions that may be used in WHERE clause,
   the columns referenced in WHERE are first searched in SELECT,
   just then in FROM.
3. WHERE - expression evaluated for each and every row
4. GROUP BY - it makes a difference, because... it narrows the number of columns