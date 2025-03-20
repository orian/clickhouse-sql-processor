SELECT
    toDate(toTimeZone(events.timestamp, 'Europe/Warsaw'), 'Europe/Warsaw') AS timestamp,
    count()
FROM
    events
WHERE
    and(equals(events.team_id, 2), ifNull(greaterOrEquals(timestamp, addDays(today(), -10)), 0))
GROUP BY
    timestamp
LIMIT 100 SETTINGS readonly=2, max_execution_time=600, allow_experimental_object_type=1, format_csv_allow_double_quotes=0, max_ast_elements=1000000, max_expanded_ast_elements=1000000, max_query_size=524288