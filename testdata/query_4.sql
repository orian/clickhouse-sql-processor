select 1, (select 70) as `power`, number
from numbers(plus(ifNull((SELECT 1 AS bin_count), 1), 1))