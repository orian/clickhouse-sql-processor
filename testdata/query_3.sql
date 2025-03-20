/* user_id:0 request:_snapshot_ */
SELECT fill.bin_from_seconds AS bin_from_seconds,
       results.person_count AS person_count,

       (SELECT histogram_params.average_conversion_time AS average_conversion_time
        FROM
            (SELECT ifNull(floor(min(step_runs.step_1_average_conversion_time_inner)), 0) AS from_seconds,
                    ifNull(ceil(max(step_runs.step_1_average_conversion_time_inner)), 1) AS to_seconds,
                    round(avg(step_runs.step_1_average_conversion_time_inner), 2) AS average_conversion_time,
                    count() AS sample_count,
                    least(60, greatest(1, ceil(cbrt(ifNull(sample_count, 0))))) AS bin_count,
                    ceil(divide(minus(to_seconds, from_seconds), bin_count)) AS bin_width_seconds_raw,
                    if(ifNull(greater(bin_width_seconds_raw, 0), 0), bin_width_seconds_raw, 60) AS bin_width_seconds
             FROM
                 (SELECT aggregation_target AS aggregation_target,
                         steps AS steps,
                         avg(step_1_conversion_time) AS step_1_average_conversion_time_inner,
                         avg(step_2_conversion_time) AS step_2_average_conversion_time_inner,
                         median(step_1_conversion_time) AS step_1_median_conversion_time_inner,
                         median(step_2_conversion_time) AS step_2_median_conversion_time_inner
                  FROM
                      (SELECT aggregation_target AS aggregation_target,
                              steps AS steps,
                              max(steps) OVER (PARTITION BY aggregation_target) AS max_steps,
                               step_1_conversion_time AS step_1_conversion_time,
                              step_2_conversion_time AS step_2_conversion_time
                       FROM
                           (SELECT aggregation_target AS aggregation_target,
                                timestamp AS timestamp,
                                step_0 AS step_0,
                                latest_0 AS latest_0,
                                step_1 AS step_1,
                                latest_1 AS latest_1,
                                step_2 AS step_2,
                                latest_2 AS latest_2,
                                if(and(ifNull(lessOrEquals(latest_0, latest_1), 0), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0), ifNull(lessOrEquals(latest_1, latest_2), 0), ifNull(lessOrEquals(latest_2, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), 3, if(and(ifNull(lessOrEquals(latest_0, latest_1), 0), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), 2, 1)) AS steps,
                                if(and(isNotNull(latest_1), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), dateDiff('second', latest_0, latest_1), NULL) AS step_1_conversion_time,
                                if(and(isNotNull(latest_2), ifNull(lessOrEquals(latest_2, plus(toTimeZone(latest_1, 'UTC'), toIntervalDay(14))), 0)), dateDiff('second', latest_1, latest_2), NULL) AS step_2_conversion_time
                            FROM
                                (SELECT aggregation_target AS aggregation_target,
                                timestamp AS timestamp,
                                step_0 AS step_0,
                                latest_0 AS latest_0,
                                step_1 AS step_1,
                                latest_1 AS latest_1,
                                step_2 AS step_2,
                                min(latest_2) OVER (PARTITION BY aggregation_target
                                ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_2
                                FROM
                                (SELECT aggregation_target AS aggregation_target,
                                timestamp AS timestamp,
                                step_0 AS step_0,
                                latest_0 AS latest_0,
                                step_1 AS step_1,
                                latest_1 AS latest_1,
                                step_2 AS step_2,
                                if(ifNull(less(latest_2, latest_1), 0), NULL, latest_2) AS latest_2
                                FROM
                                (SELECT aggregation_target AS aggregation_target,
                                timestamp AS timestamp,
                                step_0 AS step_0,
                                latest_0 AS latest_0,
                                step_1 AS step_1,
                                min(latest_1) OVER (PARTITION BY aggregation_target
                                ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_1,
                                step_2 AS step_2,
                                min(latest_2) OVER (PARTITION BY aggregation_target
                                ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_2
                                FROM
                                (SELECT toTimeZone(e.timestamp, 'UTC') AS timestamp,
                                if(not(empty(e__override.distinct_id)), e__override.person_id, e.person_id) AS aggregation_target,
                                if(equals(e.event, 'step one'), 1, 0) AS step_0,
                                if(ifNull(equals(step_0, 1), 0), timestamp, NULL) AS latest_0,
                                if(equals(e.event, 'step two'), 1, 0) AS step_1,
                                if(ifNull(equals(step_1, 1), 0), timestamp, NULL) AS latest_1,
                                if(equals(e.event, 'step three'), 1, 0) AS step_2,
                                if(ifNull(equals(step_2, 1), 0), timestamp, NULL) AS latest_2
                                FROM events AS e
                                LEFT OUTER JOIN
                                (SELECT argMax(person_distinct_id_overrides.person_id, person_distinct_id_overrides.version) AS person_id,
                                person_distinct_id_overrides.distinct_id AS distinct_id
                                FROM person_distinct_id_overrides
                                WHERE equals(person_distinct_id_overrides.team_id, 99999)
                                GROUP BY person_distinct_id_overrides.distinct_id
                                HAVING ifNull(equals(argMax(person_distinct_id_overrides.is_deleted, person_distinct_id_overrides.version), 0), 0) SETTINGS optimize_aggregation_in_order=1) AS e__override ON equals(e.distinct_id, e__override.distinct_id)
                                WHERE and(equals(e.team_id, 99999), and(and(greaterOrEquals(toTimeZone(e.timestamp, 'UTC'), toDateTime64('explicit_redacted_timestamp.000000', 6, 'UTC')), lessOrEquals(toTimeZone(e.timestamp, 'UTC'), toDateTime64('explicit_redacted_timestamp.999999', 6, 'UTC'))), in(e.event, tuple('step one', 'step three', 'step two'))), or(ifNull(equals(step_0, 1), 0), ifNull(equals(step_1, 1), 0), ifNull(equals(step_2, 1), 0)))))))
                            WHERE ifNull(equals(step_0, 1), 0)))
                  GROUP BY aggregation_target,
                           steps
                  HAVING ifNull(equals(steps, max(max_steps)), isNull(steps)
                      and isNull(max(max_steps)))) AS step_runs
             WHERE isNotNull(step_runs.step_1_average_conversion_time_inner)) AS histogram_params) AS average_conversion_time
FROM
    (SELECT plus(
                    (SELECT histogram_params.from_seconds AS from_seconds
                     FROM
                         (SELECT ifNull(floor(min(step_runs.step_1_average_conversion_time_inner)), 0) AS from_seconds, ifNull(ceil(max(step_runs.step_1_average_conversion_time_inner)), 1) AS to_seconds, round(avg(step_runs.step_1_average_conversion_time_inner), 2) AS average_conversion_time, count() AS sample_count, least(60, greatest(1, ceil(cbrt(ifNull(sample_count, 0))))) AS bin_count, ceil(divide(minus(to_seconds, from_seconds), bin_count)) AS bin_width_seconds_raw, if(ifNull(greater(bin_width_seconds_raw, 0), 0), bin_width_seconds_raw, 60) AS bin_width_seconds
                          FROM
                              (SELECT aggregation_target AS aggregation_target, steps AS steps, avg(step_1_conversion_time) AS step_1_average_conversion_time_inner, avg(step_2_conversion_time) AS step_2_average_conversion_time_inner, median(step_1_conversion_time) AS step_1_median_conversion_time_inner, median(step_2_conversion_time) AS step_2_median_conversion_time_inner
                               FROM
                                   (SELECT aggregation_target AS aggregation_target, steps AS steps, max(steps) OVER (PARTITION BY aggregation_target) AS max_steps, step_1_conversion_time AS step_1_conversion_time, step_2_conversion_time AS step_2_conversion_time
                                    FROM
                                        (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, latest_1 AS latest_1, step_2 AS step_2, latest_2 AS latest_2, if(and(ifNull(lessOrEquals(latest_0, latest_1), 0), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0), ifNull(lessOrEquals(latest_1, latest_2), 0), ifNull(lessOrEquals(latest_2, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), 3, if(and(ifNull(lessOrEquals(latest_0, latest_1), 0), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), 2, 1)) AS steps, if(and(isNotNull(latest_1), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), dateDiff('second', latest_0, latest_1), NULL) AS step_1_conversion_time, if(and(isNotNull(latest_2), ifNull(lessOrEquals(latest_2, plus(toTimeZone(latest_1, 'UTC'), toIntervalDay(14))), 0)), dateDiff('second', latest_1, latest_2), NULL) AS step_2_conversion_time
                                         FROM
                                             (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, latest_1 AS latest_1, step_2 AS step_2, min(latest_2) OVER (PARTITION BY aggregation_target
                                             ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_2
                                             FROM
                                             (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, latest_1 AS latest_1, step_2 AS step_2, if(ifNull(less(latest_2, latest_1), 0), NULL, latest_2) AS latest_2
                                             FROM
                                             (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, min(latest_1) OVER (PARTITION BY aggregation_target
                                             ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_1, step_2 AS step_2, min(latest_2) OVER (PARTITION BY aggregation_target
                                             ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_2
                                             FROM
                                             (SELECT toTimeZone(e.timestamp, 'UTC') AS timestamp, if(not(empty(e__override.distinct_id)), e__override.person_id, e.person_id) AS aggregation_target, if(equals(e.event, 'step one'), 1, 0) AS step_0, if(ifNull(equals(step_0, 1), 0), timestamp, NULL) AS latest_0, if(equals(e.event, 'step two'), 1, 0) AS step_1, if(ifNull(equals(step_1, 1), 0), timestamp, NULL) AS latest_1, if(equals(e.event, 'step three'), 1, 0) AS step_2, if(ifNull(equals(step_2, 1), 0), timestamp, NULL) AS latest_2
                                             FROM events AS e
                                             LEFT OUTER JOIN
                                             (SELECT argMax(person_distinct_id_overrides.person_id, person_distinct_id_overrides.version) AS person_id, person_distinct_id_overrides.distinct_id AS distinct_id
                                             FROM person_distinct_id_overrides
                                             WHERE equals(person_distinct_id_overrides.team_id, 99999)
                                             GROUP BY person_distinct_id_overrides.distinct_id
                                             HAVING ifNull(equals(argMax(person_distinct_id_overrides.is_deleted, person_distinct_id_overrides.version), 0), 0) SETTINGS optimize_aggregation_in_order=1) AS e__override ON equals(e.distinct_id, e__override.distinct_id)
                                             WHERE and(equals(e.team_id, 99999), and(and(greaterOrEquals(toTimeZone(e.timestamp, 'UTC'), toDateTime64('explicit_redacted_timestamp.000000', 6, 'UTC')), lessOrEquals(toTimeZone(e.timestamp, 'UTC'), toDateTime64('explicit_redacted_timestamp.999999', 6, 'UTC'))), in(e.event, tuple('step one', 'step three', 'step two'))), or(ifNull(equals(step_0, 1), 0), ifNull(equals(step_1, 1), 0), ifNull(equals(step_2, 1), 0)))))))
                                         WHERE ifNull(equals(step_0, 1), 0)))
                               GROUP BY aggregation_target, steps
                               HAVING ifNull(equals(steps, max(max_steps)), isNull(steps)
                                   and isNull(max(max_steps)))) AS step_runs
                          WHERE isNotNull(step_runs.step_1_average_conversion_time_inner)) AS histogram_params), multiply(floor(divide(minus(step_runs.step_1_average_conversion_time_inner,
                                                                                                                                             (SELECT histogram_params.from_seconds AS from_seconds
                                                                                                                                              FROM
                                                                                                                                                  (SELECT ifNull(floor(min(step_runs.step_1_average_conversion_time_inner)), 0) AS from_seconds, ifNull(ceil(max(step_runs.step_1_average_conversion_time_inner)), 1) AS to_seconds, round(avg(step_runs.step_1_average_conversion_time_inner), 2) AS average_conversion_time, count() AS sample_count, least(60, greatest(1, ceil(cbrt(ifNull(sample_count, 0))))) AS bin_count, ceil(divide(minus(to_seconds, from_seconds), bin_count)) AS bin_width_seconds_raw, if(ifNull(greater(bin_width_seconds_raw, 0), 0), bin_width_seconds_raw, 60) AS bin_width_seconds
                                                                                                                                                   FROM
                                                                                                                                                       (SELECT aggregation_target AS aggregation_target, steps AS steps, avg(step_1_conversion_time) AS step_1_average_conversion_time_inner, avg(step_2_conversion_time) AS step_2_average_conversion_time_inner, median(step_1_conversion_time) AS step_1_median_conversion_time_inner, median(step_2_conversion_time) AS step_2_median_conversion_time_inner
                                                                                                                                                        FROM
                                                                                                                                                            (SELECT aggregation_target AS aggregation_target, steps AS steps, max(steps) OVER (PARTITION BY aggregation_target) AS max_steps, step_1_conversion_time AS step_1_conversion_time, step_2_conversion_time AS step_2_conversion_time
                                                                                                                                                             FROM
                                                                                                                                                                 (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, latest_1 AS latest_1, step_2 AS step_2, latest_2 AS latest_2, if(and(ifNull(lessOrEquals(latest_0, latest_1), 0), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0), ifNull(lessOrEquals(latest_1, latest_2), 0), ifNull(lessOrEquals(latest_2, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), 3, if(and(ifNull(lessOrEquals(latest_0, latest_1), 0), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), 2, 1)) AS steps, if(and(isNotNull(latest_1), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), dateDiff('second', latest_0, latest_1), NULL) AS step_1_conversion_time, if(and(isNotNull(latest_2), ifNull(lessOrEquals(latest_2, plus(toTimeZone(latest_1, 'UTC'), toIntervalDay(14))), 0)), dateDiff('second', latest_1, latest_2), NULL) AS step_2_conversion_time
                                                                                                                                                                  FROM
                                                                                                                                                                      (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, latest_1 AS latest_1, step_2 AS step_2, min(latest_2) OVER (PARTITION BY aggregation_target
                                                                                                                                                                      ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_2
                                                                                                                                                                      FROM
                                                                                                                                                                      (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, latest_1 AS latest_1, step_2 AS step_2, if(ifNull(less(latest_2, latest_1), 0), NULL, latest_2) AS latest_2
                                                                                                                                                                      FROM
                                                                                                                                                                      (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, min(latest_1) OVER (PARTITION BY aggregation_target
                                                                                                                                                                      ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_1, step_2 AS step_2, min(latest_2) OVER (PARTITION BY aggregation_target
                                                                                                                                                                      ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_2
                                                                                                                                                                      FROM
                                                                                                                                                                      (SELECT toTimeZone(e.timestamp, 'UTC') AS timestamp, if(not(empty(e__override.distinct_id)), e__override.person_id, e.person_id) AS aggregation_target, if(equals(e.event, 'step one'), 1, 0) AS step_0, if(ifNull(equals(step_0, 1), 0), timestamp, NULL) AS latest_0, if(equals(e.event, 'step two'), 1, 0) AS step_1, if(ifNull(equals(step_1, 1), 0), timestamp, NULL) AS latest_1, if(equals(e.event, 'step three'), 1, 0) AS step_2, if(ifNull(equals(step_2, 1), 0), timestamp, NULL) AS latest_2
                                                                                                                                                                      FROM events AS e
                                                                                                                                                                      LEFT OUTER JOIN
                                                                                                                                                                      (SELECT argMax(person_distinct_id_overrides.person_id, person_distinct_id_overrides.version) AS person_id, person_distinct_id_overrides.distinct_id AS distinct_id
                                                                                                                                                                      FROM person_distinct_id_overrides
                                                                                                                                                                      WHERE equals(person_distinct_id_overrides.team_id, 99999)
                                                                                                                                                                      GROUP BY person_distinct_id_overrides.distinct_id
                                                                                                                                                                      HAVING ifNull(equals(argMax(person_distinct_id_overrides.is_deleted, person_distinct_id_overrides.version), 0), 0) SETTINGS optimize_aggregation_in_order=1) AS e__override ON equals(e.distinct_id, e__override.distinct_id)
                                                                                                                                                                      WHERE and(equals(e.team_id, 99999), and(and(greaterOrEquals(toTimeZone(e.timestamp, 'UTC'), toDateTime64('explicit_redacted_timestamp.000000', 6, 'UTC')), lessOrEquals(toTimeZone(e.timestamp, 'UTC'), toDateTime64('explicit_redacted_timestamp.999999', 6, 'UTC'))), in(e.event, tuple('step one', 'step three', 'step two'))), or(ifNull(equals(step_0, 1), 0), ifNull(equals(step_1, 1), 0), ifNull(equals(step_2, 1), 0)))))))
                                                                                                                                                                  WHERE ifNull(equals(step_0, 1), 0)))
                                                                                                                                                        GROUP BY aggregation_target, steps
                                                                                                                                                        HAVING ifNull(equals(steps, max(max_steps)), isNull(steps)
                                                                                                                                                            and isNull(max(max_steps)))) AS step_runs
                                                                                                                                                   WHERE isNotNull(step_runs.step_1_average_conversion_time_inner)) AS histogram_params)),
                                                                                                                                       (SELECT histogram_params.bin_width_seconds AS bin_width_seconds
                                                                                                                                        FROM
                                                                                                                                            (SELECT ifNull(floor(min(step_runs.step_1_average_conversion_time_inner)), 0) AS from_seconds, ifNull(ceil(max(step_runs.step_1_average_conversion_time_inner)), 1) AS to_seconds, round(avg(step_runs.step_1_average_conversion_time_inner), 2) AS average_conversion_time, count() AS sample_count, least(60, greatest(1, ceil(cbrt(ifNull(sample_count, 0))))) AS bin_count, ceil(divide(minus(to_seconds, from_seconds), bin_count)) AS bin_width_seconds_raw, if(ifNull(greater(bin_width_seconds_raw, 0), 0), bin_width_seconds_raw, 60) AS bin_width_seconds
                                                                                                                                             FROM
                                                                                                                                                 (SELECT aggregation_target AS aggregation_target, steps AS steps, avg(step_1_conversion_time) AS step_1_average_conversion_time_inner, avg(step_2_conversion_time) AS step_2_average_conversion_time_inner, median(step_1_conversion_time) AS step_1_median_conversion_time_inner, median(step_2_conversion_time) AS step_2_median_conversion_time_inner
                                                                                                                                                  FROM
                                                                                                                                                      (SELECT aggregation_target AS aggregation_target, steps AS steps, max(steps) OVER (PARTITION BY aggregation_target) AS max_steps, step_1_conversion_time AS step_1_conversion_time, step_2_conversion_time AS step_2_conversion_time
                                                                                                                                                       FROM
                                                                                                                                                           (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, latest_1 AS latest_1, step_2 AS step_2, latest_2 AS latest_2, if(and(ifNull(lessOrEquals(latest_0, latest_1), 0), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0), ifNull(lessOrEquals(latest_1, latest_2), 0), ifNull(lessOrEquals(latest_2, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), 3, if(and(ifNull(lessOrEquals(latest_0, latest_1), 0), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), 2, 1)) AS steps, if(and(isNotNull(latest_1), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), dateDiff('second', latest_0, latest_1), NULL) AS step_1_conversion_time, if(and(isNotNull(latest_2), ifNull(lessOrEquals(latest_2, plus(toTimeZone(latest_1, 'UTC'), toIntervalDay(14))), 0)), dateDiff('second', latest_1, latest_2), NULL) AS step_2_conversion_time
                                                                                                                                                            FROM
                                                                                                                                                                (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, latest_1 AS latest_1, step_2 AS step_2, min(latest_2) OVER (PARTITION BY aggregation_target
                                                                                                                                                                ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_2
                                                                                                                                                                FROM
                                                                                                                                                                (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, latest_1 AS latest_1, step_2 AS step_2, if(ifNull(less(latest_2, latest_1), 0), NULL, latest_2) AS latest_2
                                                                                                                                                                FROM
                                                                                                                                                                (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, min(latest_1) OVER (PARTITION BY aggregation_target
                                                                                                                                                                ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_1, step_2 AS step_2, min(latest_2) OVER (PARTITION BY aggregation_target
                                                                                                                                                                ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_2
                                                                                                                                                                FROM
                                                                                                                                                                (SELECT toTimeZone(e.timestamp, 'UTC') AS timestamp, if(not(empty(e__override.distinct_id)), e__override.person_id, e.person_id) AS aggregation_target, if(equals(e.event, 'step one'), 1, 0) AS step_0, if(ifNull(equals(step_0, 1), 0), timestamp, NULL) AS latest_0, if(equals(e.event, 'step two'), 1, 0) AS step_1, if(ifNull(equals(step_1, 1), 0), timestamp, NULL) AS latest_1, if(equals(e.event, 'step three'), 1, 0) AS step_2, if(ifNull(equals(step_2, 1), 0), timestamp, NULL) AS latest_2
                                                                                                                                                                FROM events AS e
                                                                                                                                                                LEFT OUTER JOIN
                                                                                                                                                                (SELECT argMax(person_distinct_id_overrides.person_id, person_distinct_id_overrides.version) AS person_id, person_distinct_id_overrides.distinct_id AS distinct_id
                                                                                                                                                                FROM person_distinct_id_overrides
                                                                                                                                                                WHERE equals(person_distinct_id_overrides.team_id, 99999)
                                                                                                                                                                GROUP BY person_distinct_id_overrides.distinct_id
                                                                                                                                                                HAVING ifNull(equals(argMax(person_distinct_id_overrides.is_deleted, person_distinct_id_overrides.version), 0), 0) SETTINGS optimize_aggregation_in_order=1) AS e__override ON equals(e.distinct_id, e__override.distinct_id)
                                                                                                                                                                WHERE and(equals(e.team_id, 99999), and(and(greaterOrEquals(toTimeZone(e.timestamp, 'UTC'), toDateTime64('explicit_redacted_timestamp.000000', 6, 'UTC')), lessOrEquals(toTimeZone(e.timestamp, 'UTC'), toDateTime64('explicit_redacted_timestamp.999999', 6, 'UTC'))), in(e.event, tuple('step one', 'step three', 'step two'))), or(ifNull(equals(step_0, 1), 0), ifNull(equals(step_1, 1), 0), ifNull(equals(step_2, 1), 0)))))))
                                                                                                                                                            WHERE ifNull(equals(step_0, 1), 0)))
                                                                                                                                                  GROUP BY aggregation_target, steps
                                                                                                                                                  HAVING ifNull(equals(steps, max(max_steps)), isNull(steps)
                                                                                                                                                      and isNull(max(max_steps)))) AS step_runs
                                                                                                                                             WHERE isNotNull(step_runs.step_1_average_conversion_time_inner)) AS histogram_params))),
                                                                                                                          (SELECT histogram_params.bin_width_seconds AS bin_width_seconds
                                                                                                                           FROM
                                                                                                                               (SELECT ifNull(floor(min(step_runs.step_1_average_conversion_time_inner)), 0) AS from_seconds, ifNull(ceil(max(step_runs.step_1_average_conversion_time_inner)), 1) AS to_seconds, round(avg(step_runs.step_1_average_conversion_time_inner), 2) AS average_conversion_time, count() AS sample_count, least(60, greatest(1, ceil(cbrt(ifNull(sample_count, 0))))) AS bin_count, ceil(divide(minus(to_seconds, from_seconds), bin_count)) AS bin_width_seconds_raw, if(ifNull(greater(bin_width_seconds_raw, 0), 0), bin_width_seconds_raw, 60) AS bin_width_seconds
                                                                                                                                FROM
                                                                                                                                    (SELECT aggregation_target AS aggregation_target, steps AS steps, avg(step_1_conversion_time) AS step_1_average_conversion_time_inner, avg(step_2_conversion_time) AS step_2_average_conversion_time_inner, median(step_1_conversion_time) AS step_1_median_conversion_time_inner, median(step_2_conversion_time) AS step_2_median_conversion_time_inner
                                                                                                                                     FROM
                                                                                                                                         (SELECT aggregation_target AS aggregation_target, steps AS steps, max(steps) OVER (PARTITION BY aggregation_target) AS max_steps, step_1_conversion_time AS step_1_conversion_time, step_2_conversion_time AS step_2_conversion_time
                                                                                                                                          FROM
                                                                                                                                              (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, latest_1 AS latest_1, step_2 AS step_2, latest_2 AS latest_2, if(and(ifNull(lessOrEquals(latest_0, latest_1), 0), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0), ifNull(lessOrEquals(latest_1, latest_2), 0), ifNull(lessOrEquals(latest_2, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), 3, if(and(ifNull(lessOrEquals(latest_0, latest_1), 0), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), 2, 1)) AS steps, if(and(isNotNull(latest_1), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), dateDiff('second', latest_0, latest_1), NULL) AS step_1_conversion_time, if(and(isNotNull(latest_2), ifNull(lessOrEquals(latest_2, plus(toTimeZone(latest_1, 'UTC'), toIntervalDay(14))), 0)), dateDiff('second', latest_1, latest_2), NULL) AS step_2_conversion_time
                                                                                                                                               FROM
                                                                                                                                                   (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, latest_1 AS latest_1, step_2 AS step_2, min(latest_2) OVER (PARTITION BY aggregation_target
                                                                                                                                                   ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_2
                                                                                                                                                   FROM
                                                                                                                                                   (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, latest_1 AS latest_1, step_2 AS step_2, if(ifNull(less(latest_2, latest_1), 0), NULL, latest_2) AS latest_2
                                                                                                                                                   FROM
                                                                                                                                                   (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, min(latest_1) OVER (PARTITION BY aggregation_target
                                                                                                                                                   ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_1, step_2 AS step_2, min(latest_2) OVER (PARTITION BY aggregation_target
                                                                                                                                                   ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_2
                                                                                                                                                   FROM
                                                                                                                                                   (SELECT toTimeZone(e.timestamp, 'UTC') AS timestamp, if(not(empty(e__override.distinct_id)), e__override.person_id, e.person_id) AS aggregation_target, if(equals(e.event, 'step one'), 1, 0) AS step_0, if(ifNull(equals(step_0, 1), 0), timestamp, NULL) AS latest_0, if(equals(e.event, 'step two'), 1, 0) AS step_1, if(ifNull(equals(step_1, 1), 0), timestamp, NULL) AS latest_1, if(equals(e.event, 'step three'), 1, 0) AS step_2, if(ifNull(equals(step_2, 1), 0), timestamp, NULL) AS latest_2
                                                                                                                                                   FROM events AS e
                                                                                                                                                   LEFT OUTER JOIN
                                                                                                                                                   (SELECT argMax(person_distinct_id_overrides.person_id, person_distinct_id_overrides.version) AS person_id, person_distinct_id_overrides.distinct_id AS distinct_id
                                                                                                                                                   FROM person_distinct_id_overrides
                                                                                                                                                   WHERE equals(person_distinct_id_overrides.team_id, 99999)
                                                                                                                                                   GROUP BY person_distinct_id_overrides.distinct_id
                                                                                                                                                   HAVING ifNull(equals(argMax(person_distinct_id_overrides.is_deleted, person_distinct_id_overrides.version), 0), 0) SETTINGS optimize_aggregation_in_order=1) AS e__override ON equals(e.distinct_id, e__override.distinct_id)
                                                                                                                                                   WHERE and(equals(e.team_id, 99999), and(and(greaterOrEquals(toTimeZone(e.timestamp, 'UTC'), toDateTime64('explicit_redacted_timestamp.000000', 6, 'UTC')), lessOrEquals(toTimeZone(e.timestamp, 'UTC'), toDateTime64('explicit_redacted_timestamp.999999', 6, 'UTC'))), in(e.event, tuple('step one', 'step three', 'step two'))), or(ifNull(equals(step_0, 1), 0), ifNull(equals(step_1, 1), 0), ifNull(equals(step_2, 1), 0)))))))
                                                                                                                                               WHERE ifNull(equals(step_0, 1), 0)))
                                                                                                                                     GROUP BY aggregation_target, steps
                                                                                                                                     HAVING ifNull(equals(steps, max(max_steps)), isNull(steps)
                                                                                                                                         and isNull(max(max_steps)))) AS step_runs
                                                                                                                                WHERE isNotNull(step_runs.step_1_average_conversion_time_inner)) AS histogram_params))) AS bin_from_seconds,
            count() AS person_count
     FROM
         (SELECT aggregation_target AS aggregation_target,
                 steps AS steps,
                 avg(step_1_conversion_time) AS step_1_average_conversion_time_inner,
                 avg(step_2_conversion_time) AS step_2_average_conversion_time_inner,
                 median(step_1_conversion_time) AS step_1_median_conversion_time_inner,
                 median(step_2_conversion_time) AS step_2_median_conversion_time_inner
          FROM
              (SELECT aggregation_target AS aggregation_target,
                      steps AS steps,
                      max(steps) OVER (PARTITION BY aggregation_target) AS max_steps,
                       step_1_conversion_time AS step_1_conversion_time,
                      step_2_conversion_time AS step_2_conversion_time
               FROM
                   (SELECT aggregation_target AS aggregation_target,
                        timestamp AS timestamp,
                        step_0 AS step_0,
                        latest_0 AS latest_0,
                        step_1 AS step_1,
                        latest_1 AS latest_1,
                        step_2 AS step_2,
                        latest_2 AS latest_2,
                        if(and(ifNull(lessOrEquals(latest_0, latest_1), 0), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0), ifNull(lessOrEquals(latest_1, latest_2), 0), ifNull(lessOrEquals(latest_2, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), 3, if(and(ifNull(lessOrEquals(latest_0, latest_1), 0), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), 2, 1)) AS steps,
                        if(and(isNotNull(latest_1), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), dateDiff('second', latest_0, latest_1), NULL) AS step_1_conversion_time,
                        if(and(isNotNull(latest_2), ifNull(lessOrEquals(latest_2, plus(toTimeZone(latest_1, 'UTC'), toIntervalDay(14))), 0)), dateDiff('second', latest_1, latest_2), NULL) AS step_2_conversion_time
                    FROM
                        (SELECT aggregation_target AS aggregation_target,
                        timestamp AS timestamp,
                        step_0 AS step_0,
                        latest_0 AS latest_0,
                        step_1 AS step_1,
                        latest_1 AS latest_1,
                        step_2 AS step_2,
                        min(latest_2) OVER (PARTITION BY aggregation_target
                        ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_2
                        FROM
                        (SELECT aggregation_target AS aggregation_target,
                        timestamp AS timestamp,
                        step_0 AS step_0,
                        latest_0 AS latest_0,
                        step_1 AS step_1,
                        latest_1 AS latest_1,
                        step_2 AS step_2,
                        if(ifNull(less(latest_2, latest_1), 0), NULL, latest_2) AS latest_2
                        FROM
                        (SELECT aggregation_target AS aggregation_target,
                        timestamp AS timestamp,
                        step_0 AS step_0,
                        latest_0 AS latest_0,
                        step_1 AS step_1,
                        min(latest_1) OVER (PARTITION BY aggregation_target
                        ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_1,
                        step_2 AS step_2,
                        min(latest_2) OVER (PARTITION BY aggregation_target
                        ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_2
                        FROM
                        (SELECT toTimeZone(e.timestamp, 'UTC') AS timestamp,
                        if(not(empty(e__override.distinct_id)), e__override.person_id, e.person_id) AS aggregation_target,
                        if(equals(e.event, 'step one'), 1, 0) AS step_0,
                        if(ifNull(equals(step_0, 1), 0), timestamp, NULL) AS latest_0,
                        if(equals(e.event, 'step two'), 1, 0) AS step_1,
                        if(ifNull(equals(step_1, 1), 0), timestamp, NULL) AS latest_1,
                        if(equals(e.event, 'step three'), 1, 0) AS step_2,
                        if(ifNull(equals(step_2, 1), 0), timestamp, NULL) AS latest_2
                        FROM events AS e
                        LEFT OUTER JOIN
                        (SELECT argMax(person_distinct_id_overrides.person_id, person_distinct_id_overrides.version) AS person_id,
                        person_distinct_id_overrides.distinct_id AS distinct_id
                        FROM person_distinct_id_overrides
                        WHERE equals(person_distinct_id_overrides.team_id, 99999)
                        GROUP BY person_distinct_id_overrides.distinct_id
                        HAVING ifNull(equals(argMax(person_distinct_id_overrides.is_deleted, person_distinct_id_overrides.version), 0), 0) SETTINGS optimize_aggregation_in_order=1) AS e__override ON equals(e.distinct_id, e__override.distinct_id)
                        WHERE and(equals(e.team_id, 99999), and(and(greaterOrEquals(toTimeZone(e.timestamp, 'UTC'), toDateTime64('explicit_redacted_timestamp.000000', 6, 'UTC')), lessOrEquals(toTimeZone(e.timestamp, 'UTC'), toDateTime64('explicit_redacted_timestamp.999999', 6, 'UTC'))), in(e.event, tuple('step one', 'step three', 'step two'))), or(ifNull(equals(step_0, 1), 0), ifNull(equals(step_1, 1), 0), ifNull(equals(step_2, 1), 0)))))))
                    WHERE ifNull(equals(step_0, 1), 0)))
          GROUP BY aggregation_target,
                   steps
          HAVING ifNull(equals(steps, max(max_steps)), isNull(steps)
              and isNull(max(max_steps)))) AS step_runs
     GROUP BY bin_from_seconds) AS results
        RIGHT OUTER JOIN
    (SELECT plus(
                    (SELECT histogram_params.from_seconds AS from_seconds
                     FROM
                         (SELECT ifNull(floor(min(step_runs.step_1_average_conversion_time_inner)), 0) AS from_seconds, ifNull(ceil(max(step_runs.step_1_average_conversion_time_inner)), 1) AS to_seconds, round(avg(step_runs.step_1_average_conversion_time_inner), 2) AS average_conversion_time, count() AS sample_count, least(60, greatest(1, ceil(cbrt(ifNull(sample_count, 0))))) AS bin_count, ceil(divide(minus(to_seconds, from_seconds), bin_count)) AS bin_width_seconds_raw, if(ifNull(greater(bin_width_seconds_raw, 0), 0), bin_width_seconds_raw, 60) AS bin_width_seconds
                          FROM
                              (SELECT aggregation_target AS aggregation_target, steps AS steps, avg(step_1_conversion_time) AS step_1_average_conversion_time_inner, avg(step_2_conversion_time) AS step_2_average_conversion_time_inner, median(step_1_conversion_time) AS step_1_median_conversion_time_inner, median(step_2_conversion_time) AS step_2_median_conversion_time_inner
                               FROM
                                   (SELECT aggregation_target AS aggregation_target, steps AS steps, max(steps) OVER (PARTITION BY aggregation_target) AS max_steps, step_1_conversion_time AS step_1_conversion_time, step_2_conversion_time AS step_2_conversion_time
                                    FROM
                                        (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, latest_1 AS latest_1, step_2 AS step_2, latest_2 AS latest_2, if(and(ifNull(lessOrEquals(latest_0, latest_1), 0), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0), ifNull(lessOrEquals(latest_1, latest_2), 0), ifNull(lessOrEquals(latest_2, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), 3, if(and(ifNull(lessOrEquals(latest_0, latest_1), 0), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), 2, 1)) AS steps, if(and(isNotNull(latest_1), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), dateDiff('second', latest_0, latest_1), NULL) AS step_1_conversion_time, if(and(isNotNull(latest_2), ifNull(lessOrEquals(latest_2, plus(toTimeZone(latest_1, 'UTC'), toIntervalDay(14))), 0)), dateDiff('second', latest_1, latest_2), NULL) AS step_2_conversion_time
                                         FROM
                                             (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, latest_1 AS latest_1, step_2 AS step_2, min(latest_2) OVER (PARTITION BY aggregation_target
                                             ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_2
                                             FROM
                                             (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, latest_1 AS latest_1, step_2 AS step_2, if(ifNull(less(latest_2, latest_1), 0), NULL, latest_2) AS latest_2
                                             FROM
                                             (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, min(latest_1) OVER (PARTITION BY aggregation_target
                                             ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_1, step_2 AS step_2, min(latest_2) OVER (PARTITION BY aggregation_target
                                             ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_2
                                             FROM
                                             (SELECT toTimeZone(e.timestamp, 'UTC') AS timestamp, if(not(empty(e__override.distinct_id)), e__override.person_id, e.person_id) AS aggregation_target, if(equals(e.event, 'step one'), 1, 0) AS step_0, if(ifNull(equals(step_0, 1), 0), timestamp, NULL) AS latest_0, if(equals(e.event, 'step two'), 1, 0) AS step_1, if(ifNull(equals(step_1, 1), 0), timestamp, NULL) AS latest_1, if(equals(e.event, 'step three'), 1, 0) AS step_2, if(ifNull(equals(step_2, 1), 0), timestamp, NULL) AS latest_2
                                             FROM events AS e
                                             LEFT OUTER JOIN
                                             (SELECT argMax(person_distinct_id_overrides.person_id, person_distinct_id_overrides.version) AS person_id, person_distinct_id_overrides.distinct_id AS distinct_id
                                             FROM person_distinct_id_overrides
                                             WHERE equals(person_distinct_id_overrides.team_id, 99999)
                                             GROUP BY person_distinct_id_overrides.distinct_id
                                             HAVING ifNull(equals(argMax(person_distinct_id_overrides.is_deleted, person_distinct_id_overrides.version), 0), 0) SETTINGS optimize_aggregation_in_order=1) AS e__override ON equals(e.distinct_id, e__override.distinct_id)
                                             WHERE and(equals(e.team_id, 99999), and(and(greaterOrEquals(toTimeZone(e.timestamp, 'UTC'), toDateTime64('explicit_redacted_timestamp.000000', 6, 'UTC')), lessOrEquals(toTimeZone(e.timestamp, 'UTC'), toDateTime64('explicit_redacted_timestamp.999999', 6, 'UTC'))), in(e.event, tuple('step one', 'step three', 'step two'))), or(ifNull(equals(step_0, 1), 0), ifNull(equals(step_1, 1), 0), ifNull(equals(step_2, 1), 0)))))))
                                         WHERE ifNull(equals(step_0, 1), 0)))
                               GROUP BY aggregation_target, steps
                               HAVING ifNull(equals(steps, max(max_steps)), isNull(steps)
                                   and isNull(max(max_steps)))) AS step_runs
                          WHERE isNotNull(step_runs.step_1_average_conversion_time_inner)) AS histogram_params), multiply(numbers.number,
                                                                                                                          (SELECT histogram_params.bin_width_seconds AS bin_width_seconds
                                                                                                                           FROM
                                                                                                                               (SELECT ifNull(floor(min(step_runs.step_1_average_conversion_time_inner)), 0) AS from_seconds, ifNull(ceil(max(step_runs.step_1_average_conversion_time_inner)), 1) AS to_seconds, round(avg(step_runs.step_1_average_conversion_time_inner), 2) AS average_conversion_time, count() AS sample_count, least(60, greatest(1, ceil(cbrt(ifNull(sample_count, 0))))) AS bin_count, ceil(divide(minus(to_seconds, from_seconds), bin_count)) AS bin_width_seconds_raw, if(ifNull(greater(bin_width_seconds_raw, 0), 0), bin_width_seconds_raw, 60) AS bin_width_seconds
                                                                                                                                FROM
                                                                                                                                    (SELECT aggregation_target AS aggregation_target, steps AS steps, avg(step_1_conversion_time) AS step_1_average_conversion_time_inner, avg(step_2_conversion_time) AS step_2_average_conversion_time_inner, median(step_1_conversion_time) AS step_1_median_conversion_time_inner, median(step_2_conversion_time) AS step_2_median_conversion_time_inner
                                                                                                                                     FROM
                                                                                                                                         (SELECT aggregation_target AS aggregation_target, steps AS steps, max(steps) OVER (PARTITION BY aggregation_target) AS max_steps, step_1_conversion_time AS step_1_conversion_time, step_2_conversion_time AS step_2_conversion_time
                                                                                                                                          FROM
                                                                                                                                              (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, latest_1 AS latest_1, step_2 AS step_2, latest_2 AS latest_2, if(and(ifNull(lessOrEquals(latest_0, latest_1), 0), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0), ifNull(lessOrEquals(latest_1, latest_2), 0), ifNull(lessOrEquals(latest_2, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), 3, if(and(ifNull(lessOrEquals(latest_0, latest_1), 0), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), 2, 1)) AS steps, if(and(isNotNull(latest_1), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), dateDiff('second', latest_0, latest_1), NULL) AS step_1_conversion_time, if(and(isNotNull(latest_2), ifNull(lessOrEquals(latest_2, plus(toTimeZone(latest_1, 'UTC'), toIntervalDay(14))), 0)), dateDiff('second', latest_1, latest_2), NULL) AS step_2_conversion_time
                                                                                                                                               FROM
                                                                                                                                                   (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, latest_1 AS latest_1, step_2 AS step_2, min(latest_2) OVER (PARTITION BY aggregation_target
                                                                                                                                                   ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_2
                                                                                                                                                   FROM
                                                                                                                                                   (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, latest_1 AS latest_1, step_2 AS step_2, if(ifNull(less(latest_2, latest_1), 0), NULL, latest_2) AS latest_2
                                                                                                                                                   FROM
                                                                                                                                                   (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, min(latest_1) OVER (PARTITION BY aggregation_target
                                                                                                                                                   ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_1, step_2 AS step_2, min(latest_2) OVER (PARTITION BY aggregation_target
                                                                                                                                                   ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_2
                                                                                                                                                   FROM
                                                                                                                                                   (SELECT toTimeZone(e.timestamp, 'UTC') AS timestamp, if(not(empty(e__override.distinct_id)), e__override.person_id, e.person_id) AS aggregation_target, if(equals(e.event, 'step one'), 1, 0) AS step_0, if(ifNull(equals(step_0, 1), 0), timestamp, NULL) AS latest_0, if(equals(e.event, 'step two'), 1, 0) AS step_1, if(ifNull(equals(step_1, 1), 0), timestamp, NULL) AS latest_1, if(equals(e.event, 'step three'), 1, 0) AS step_2, if(ifNull(equals(step_2, 1), 0), timestamp, NULL) AS latest_2
                                                                                                                                                   FROM events AS e
                                                                                                                                                   LEFT OUTER JOIN
                                                                                                                                                   (SELECT argMax(person_distinct_id_overrides.person_id, person_distinct_id_overrides.version) AS person_id, person_distinct_id_overrides.distinct_id AS distinct_id
                                                                                                                                                   FROM person_distinct_id_overrides
                                                                                                                                                   WHERE equals(person_distinct_id_overrides.team_id, 99999)
                                                                                                                                                   GROUP BY person_distinct_id_overrides.distinct_id
                                                                                                                                                   HAVING ifNull(equals(argMax(person_distinct_id_overrides.is_deleted, person_distinct_id_overrides.version), 0), 0) SETTINGS optimize_aggregation_in_order=1) AS e__override ON equals(e.distinct_id, e__override.distinct_id)
                                                                                                                                                   WHERE and(equals(e.team_id, 99999), and(and(greaterOrEquals(toTimeZone(e.timestamp, 'UTC'), toDateTime64('explicit_redacted_timestamp.000000', 6, 'UTC')), lessOrEquals(toTimeZone(e.timestamp, 'UTC'), toDateTime64('explicit_redacted_timestamp.999999', 6, 'UTC'))), in(e.event, tuple('step one', 'step three', 'step two'))), or(ifNull(equals(step_0, 1), 0), ifNull(equals(step_1, 1), 0), ifNull(equals(step_2, 1), 0)))))))
                                                                                                                                               WHERE ifNull(equals(step_0, 1), 0)))
                                                                                                                                     GROUP BY aggregation_target, steps
                                                                                                                                     HAVING ifNull(equals(steps, max(max_steps)), isNull(steps)
                                                                                                                                         and isNull(max(max_steps)))) AS step_runs
                                                                                                                                WHERE isNotNull(step_runs.step_1_average_conversion_time_inner)) AS histogram_params))) AS bin_from_seconds
     FROM numbers(plus(ifNull(
                               (SELECT histogram_params.bin_count AS bin_count
                                FROM
                                    (SELECT ifNull(floor(min(step_runs.step_1_average_conversion_time_inner)), 0) AS from_seconds, ifNull(ceil(max(step_runs.step_1_average_conversion_time_inner)), 1) AS to_seconds, round(avg(step_runs.step_1_average_conversion_time_inner), 2) AS average_conversion_time, count() AS sample_count, least(60, greatest(1, ceil(cbrt(ifNull(sample_count, 0))))) AS bin_count, ceil(divide(minus(to_seconds, from_seconds), bin_count)) AS bin_width_seconds_raw, if(ifNull(greater(bin_width_seconds_raw, 0), 0), bin_width_seconds_raw, 60) AS bin_width_seconds
                                     FROM
                                         (SELECT aggregation_target AS aggregation_target, steps AS steps, avg(step_1_conversion_time) AS step_1_average_conversion_time_inner, avg(step_2_conversion_time) AS step_2_average_conversion_time_inner, median(step_1_conversion_time) AS step_1_median_conversion_time_inner, median(step_2_conversion_time) AS step_2_median_conversion_time_inner
                                          FROM
                                              (SELECT aggregation_target AS aggregation_target, steps AS steps, max(steps) OVER (PARTITION BY aggregation_target) AS max_steps, step_1_conversion_time AS step_1_conversion_time, step_2_conversion_time AS step_2_conversion_time
                                               FROM
                                                   (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, latest_1 AS latest_1, step_2 AS step_2, latest_2 AS latest_2, if(and(ifNull(lessOrEquals(latest_0, latest_1), 0), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0), ifNull(lessOrEquals(latest_1, latest_2), 0), ifNull(lessOrEquals(latest_2, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), 3, if(and(ifNull(lessOrEquals(latest_0, latest_1), 0), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), 2, 1)) AS steps, if(and(isNotNull(latest_1), ifNull(lessOrEquals(latest_1, plus(toTimeZone(latest_0, 'UTC'), toIntervalDay(14))), 0)), dateDiff('second', latest_0, latest_1), NULL) AS step_1_conversion_time, if(and(isNotNull(latest_2), ifNull(lessOrEquals(latest_2, plus(toTimeZone(latest_1, 'UTC'), toIntervalDay(14))), 0)), dateDiff('second', latest_1, latest_2), NULL) AS step_2_conversion_time
                                                    FROM
                                                        (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, latest_1 AS latest_1, step_2 AS step_2, min(latest_2) OVER (PARTITION BY aggregation_target
                                                        ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_2
                                                        FROM
                                                        (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, latest_1 AS latest_1, step_2 AS step_2, if(ifNull(less(latest_2, latest_1), 0), NULL, latest_2) AS latest_2
                                                        FROM
                                                        (SELECT aggregation_target AS aggregation_target, timestamp AS timestamp, step_0 AS step_0, latest_0 AS latest_0, step_1 AS step_1, min(latest_1) OVER (PARTITION BY aggregation_target
                                                        ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_1, step_2 AS step_2, min(latest_2) OVER (PARTITION BY aggregation_target
                                                        ORDER BY timestamp DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS latest_2
                                                        FROM
                                                        (SELECT toTimeZone(e.timestamp, 'UTC') AS timestamp, if(not(empty(e__override.distinct_id)), e__override.person_id, e.person_id) AS aggregation_target, if(equals(e.event, 'step one'), 1, 0) AS step_0, if(ifNull(equals(step_0, 1), 0), timestamp, NULL) AS latest_0, if(equals(e.event, 'step two'), 1, 0) AS step_1, if(ifNull(equals(step_1, 1), 0), timestamp, NULL) AS latest_1, if(equals(e.event, 'step three'), 1, 0) AS step_2, if(ifNull(equals(step_2, 1), 0), timestamp, NULL) AS latest_2
                                                        FROM events AS e
                                                        LEFT OUTER JOIN
                                                        (SELECT argMax(person_distinct_id_overrides.person_id, person_distinct_id_overrides.version) AS person_id, person_distinct_id_overrides.distinct_id AS distinct_id
                                                        FROM person_distinct_id_overrides
                                                        WHERE equals(person_distinct_id_overrides.team_id, 99999)
                                                        GROUP BY person_distinct_id_overrides.distinct_id
                                                        HAVING ifNull(equals(argMax(person_distinct_id_overrides.is_deleted, person_distinct_id_overrides.version), 0), 0) SETTINGS optimize_aggregation_in_order=1) AS e__override ON equals(e.distinct_id, e__override.distinct_id)
                                                        WHERE and(equals(e.team_id, 99999), and(and(greaterOrEquals(toTimeZone(e.timestamp, 'UTC'), toDateTime64('explicit_redacted_timestamp.000000', 6, 'UTC')), lessOrEquals(toTimeZone(e.timestamp, 'UTC'), toDateTime64('explicit_redacted_timestamp.999999', 6, 'UTC'))), in(e.event, tuple('step one', 'step three', 'step two'))), or(ifNull(equals(step_0, 1), 0), ifNull(equals(step_1, 1), 0), ifNull(equals(step_2, 1), 0)))))))
                                                    WHERE ifNull(equals(step_0, 1), 0)))
                                          GROUP BY aggregation_target, steps
                                          HAVING ifNull(equals(steps, max(max_steps)), isNull(steps)
                                              and isNull(max(max_steps)))) AS step_runs
                                     WHERE isNotNull(step_runs.step_1_average_conversion_time_inner)) AS histogram_params), 0), 1)) AS numbers) AS fill ON equals(results.bin_from_seconds, fill.bin_from_seconds)
ORDER BY fill.bin_from_seconds ASC
    LIMIT 100 SETTINGS readonly=2,
                     max_execution_time=60,
                     allow_experimental_object_type=1,
                     format_csv_allow_double_quotes=0,
                     max_ast_elements=4000000,
                     max_expanded_ast_elements=4000000,
                     max_bytes_before_external_group_by=23622320128,
                     allow_experimental_analyzer=1