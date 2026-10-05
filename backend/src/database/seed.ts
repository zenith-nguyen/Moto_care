import * as argon2 from 'argon2';
import { Repository } from 'typeorm';
import dataSource from './data-source';
import { ApprovalStatus } from '../common/enums/approval-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { IncidentType } from '../incident-types/incident-type.entity';
import { Provider, GeoPoint } from '../providers/provider.entity';
import { User } from '../users/user.entity';
import { Wallet } from '../payments/wallet.entity';

const DEV_PASSWORD = 'MotoCareDev123!';

function seedPassword(role: UserRole): string {
  const variable = `SEED_${role}_PASSWORD`;
  const configured = process.env[variable];
  if (process.env.DEMO_MODE === 'true' && (!configured || configured.length < 16 || configured === DEV_PASSWORD)) {
    throw new Error(`${variable} must be a unique password of at least 16 characters in demo mode`);
  }
  return configured ?? DEV_PASSWORD;
}

const incidentSeeds = [
  { code: 'OUT_OF_FUEL', name: 'Hết xăng', basePrice: '80000.00' },
  { code: 'FLAT_TIRE', name: 'Xẹp lốp', basePrice: '100000.00' },
  { code: 'ENGINE_FAILURE', name: 'Chết máy', basePrice: '150000.00' },
  { code: 'DEAD_BATTERY', name: 'Hết bình', basePrice: '120000.00' },
  { code: 'MINOR_COLLISION', name: 'Va quẹt nhẹ', basePrice: '200000.00' },
];

const providerSeeds: Array<{
  name: string;
  email: string;
  phone: string;
  location: GeoPoint;
}> = [
  {
    name: 'Thợ MotoCare Quận 1',
    email: 'provider.q1@motocare.local',
    phone: '0900000001',
    location: { type: 'Point', coordinates: [106.7009, 10.7769] },
  },
  {
    name: 'Thợ MotoCare Bình Thạnh',
    email: 'provider.binhthanh@motocare.local',
    phone: '0900000002',
    location: { type: 'Point', coordinates: [106.7105, 10.8012] },
  },
  {
    name: 'Thợ MotoCare Phú Nhuận',
    email: 'provider.phunhuan@motocare.local',
    phone: '0900000003',
    location: { type: 'Point', coordinates: [106.6805, 10.7992] },
  },
];

async function findOrCreateUser(
  repository: Repository<User>,
  input: {
    name: string;
    email: string;
    phone?: string;
    role: UserRole;
    status: UserStatus;
  },
): Promise<User> {
  const existing = await repository.findOneBy({ email: input.email });
  if (existing) return existing;

  return repository.save(
    repository.create({
      ...input,
      phone: input.phone ?? null,
      passwordHash: await argon2.hash(seedPassword(input.role)),
    }),
  );
}

async function seed(): Promise<void> {
  if (process.env.NODE_ENV === 'production') {
    throw new Error('Development seed is forbidden in production');
  }
  if (process.env.DEMO_MODE === 'true') {
    const roles = [UserRole.CUSTOMER, UserRole.PROVIDER, UserRole.ADMIN];
    const passwords = roles.map(seedPassword);
    if (new Set(passwords).size !== passwords.length) {
      throw new Error('Demo seed roles must use different passwords');
    }
  }
  await dataSource.initialize();

  try {
    const userRepository = dataSource.getRepository(User);
    const providerRepository = dataSource.getRepository(Provider);
    const incidentRepository = dataSource.getRepository(IncidentType);
    const walletRepository = dataSource.getRepository(Wallet);

    await incidentRepository.upsert(incidentSeeds, ['code']);

    const customer = await findOrCreateUser(userRepository, {
      name: 'MotoCare Dev Customer',
      email: 'customer@motocare.local',
      phone: '0900000010',
      role: UserRole.CUSTOMER,
      status: UserStatus.ACTIVE,
    });

    const admin = await findOrCreateUser(userRepository, {
      name: 'MotoCare Dev Admin',
      email: 'admin@motocare.local',
      phone: '0900000011',
      role: UserRole.ADMIN,
      status: UserStatus.ACTIVE,
    });

    for (const providerSeed of providerSeeds) {
      const user = await findOrCreateUser(userRepository, {
        name: providerSeed.name,
        email: providerSeed.email,
        phone: providerSeed.phone,
        role: UserRole.PROVIDER,
        status: UserStatus.ACTIVE,
      });

      let provider = await providerRepository.findOneBy({ userId: user.id });
      if (!provider) {
        provider = providerRepository.create({ userId: user.id });
      }
      provider.isOnline = true;
      provider.approvalStatus = ApprovalStatus.APPROVED;
      provider.currentLocation = providerSeed.location;
      provider.lastSeenAt = new Date();
      provider = await providerRepository.save(provider);

      const wallet = await walletRepository.findOneBy({ providerId: provider.id });
      if (!wallet) {
        await walletRepository.save(walletRepository.create({ providerId: provider.id, balance: '0.00' }));
      }
    }

    console.log(`Seed complete. Customer: ${customer.email}; Admin: ${admin.email}`);
    console.log('Seed passwords are documented for local development only; configured demo passwords are never printed.');
  } finally {
    await dataSource.destroy();
  }
}

void seed().catch((error: unknown) => {
  console.error(error);
  process.exitCode = 1;
});
