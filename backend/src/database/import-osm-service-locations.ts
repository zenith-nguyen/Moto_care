import dataSource from './data-source';
import { ServiceLocation } from '../service-locations/service-location.entity';
import { OsmOverpassSource } from '../service-locations/osm-overpass.source';

const DEFAULT_OVERPASS_URL = 'https://overpass-api.de/api/interpreter';
// South, west, north, east. This bounding box intentionally limits the demo snapshot to TP.HCM.
const DEFAULT_HCMC_BBOX = '10.349,106.363,11.160,107.014';

function validBbox(value: string): string {
  const parts = value.split(',').map(Number);
  if (parts.length !== 4 || parts.some((part) => !Number.isFinite(part))) {
    throw new Error('OSM_IMPORT_BBOX must be south,west,north,east');
  }
  const [south, west, north, east] = parts;
  if (south >= north || west >= east || south < -90 || north > 90 || west < -180 || east > 180) {
    throw new Error('OSM_IMPORT_BBOX is invalid');
  }
  return value;
}

async function run(): Promise<void> {
  const source = new OsmOverpassSource(
    process.env.OSM_OVERPASS_URL ?? DEFAULT_OVERPASS_URL,
    validBbox(process.env.OSM_IMPORT_BBOX ?? DEFAULT_HCMC_BBOX),
  );
  const snapshot = await source.fetchSnapshot();
  if (!snapshot.length) throw new Error('OSM snapshot is empty; existing markers were left unchanged');

  await dataSource.initialize();
  try {
    const repository = dataSource.getRepository(ServiceLocation);
    for (let offset = 0; offset < snapshot.length; offset += 250) {
      await repository.upsert(snapshot.slice(offset, offset + 250), {
        conflictPaths: ['source', 'sourceId'],
        skipUpdateIfNoValuesChanged: true,
      });
    }
    console.log(`Imported or updated ${snapshot.length} named TP.HCM OSM service locations.`);
    console.log('OSM rows are informational, unverified and not MotoCare partners. No missing rows were deleted.');
  } finally {
    await dataSource.destroy();
  }
}

void run().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
