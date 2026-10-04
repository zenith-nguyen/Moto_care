import dataSource from './data-source';

interface ProviderDistanceRow {
  id: number;
  name: string;
  distance_m: string;
}

async function checkNearestProviders(): Promise<void> {
  await dataSource.initialize();

  try {
    const longitude = 106.7009;
    const latitude = 10.7769;
    const radiusMeters = 10_000;
    const rows = (await dataSource.query(
      `
        SELECT
          p.id,
          u.name,
          ST_Distance(
            p.current_location,
            ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography
          )::text AS distance_m
        FROM providers p
        INNER JOIN users u ON u.id = p.user_id
        WHERE p.is_online = true
          AND p.approval_status = 'APPROVED'
          AND p.current_location IS NOT NULL
          AND ST_DWithin(
            p.current_location,
            ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
            $3
          )
        ORDER BY ST_Distance(
          p.current_location,
          ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography
        ) ASC
      `,
      [longitude, latitude, radiusMeters],
    )) as ProviderDistanceRow[];

    if (rows.length === 0) {
      throw new Error('No online approved provider found in the test radius');
    }

    const distances = rows.map((row) => Number(row.distance_m));
    const sorted = distances.every((distance, index) => index === 0 || distances[index - 1] <= distance);
    if (!sorted) {
      throw new Error('Provider results are not sorted by distance');
    }

    console.table(
      rows.map((row) => ({
        id: row.id,
        name: row.name,
        distanceMeters: Number(row.distance_m).toFixed(2),
      })),
    );
    console.log('ST_DWithin nearest-provider check passed.');
  } finally {
    await dataSource.destroy();
  }
}

void checkNearestProviders().catch((error: unknown) => {
  console.error(error);
  process.exitCode = 1;
});
