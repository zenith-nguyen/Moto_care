import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { DataSource, EntityManager, QueryFailedError } from 'typeorm';
import { User } from '../users/user.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { CreateVehicleDto, UpdateVehicleDto } from './dto/vehicle.dto';
import { Vehicle } from './vehicle.entity';
import { VehicleType } from './vehicle-type.enum';

@Injectable()
export class VehiclesService {
  constructor(private readonly database: DataSource) {}

  list(customerId: number): Promise<Vehicle[]> {
    return this.database.getRepository(Vehicle).find({
      where: { customerId },
      order: { isDefault: 'DESC', createdAt: 'ASC', id: 'ASC' },
    });
  }

  async create(customerId: number, dto: CreateVehicleDto): Promise<Vehicle> {
    try {
      return await this.database.transaction(async (manager) => {
        await this.lockCustomer(manager, customerId);
        const repository = manager.getRepository(Vehicle);
        const existingCount = await repository.countBy({ customerId });
        const isDefault = existingCount === 0 || dto.isDefault === true;
        if (isDefault) await repository.update({ customerId, isDefault: true }, { isDefault: false });
        return repository.save(repository.create({
          customerId,
          type: dto.type,
          brand: dto.brand,
          model: dto.model,
          licensePlate: dto.licensePlate,
          color: dto.color ?? null,
          tireType: dto.tireType ?? 'tubed',
          engineType: dto.engineType ?? (dto.type === 'ELECTRIC_MOTORBIKE' ? 'electric' : 'gas'),
          isDefault,
        }));
      });
    } catch (error) {
      this.rethrowDuplicatePlate(error);
      throw error;
    }
  }

  async update(customerId: number, vehicleId: number, dto: UpdateVehicleDto): Promise<Vehicle> {
    try {
      return await this.database.transaction(async (manager) => {
        await this.lockCustomer(manager, customerId);
        const repository = manager.getRepository(Vehicle);
        const vehicle = await repository.findOneBy({ id: vehicleId, customerId });
        if (!vehicle) throw new NotFoundException('Vehicle not found');
        if (dto.isDefault === false && vehicle.isDefault) {
          throw new ConflictException('Choose another default vehicle instead of unsetting the current default');
        }
        if (dto.isDefault === true && !vehicle.isDefault) {
          await repository.update({ customerId, isDefault: true }, { isDefault: false });
        }
        repository.merge(vehicle, {
          ...(dto.type !== undefined && { type: dto.type }),
          ...(dto.type === undefined && dto.engineType !== undefined &&
            [VehicleType.MOTORBIKE, VehicleType.ELECTRIC_MOTORBIKE].includes(vehicle.type) && {
              type: dto.engineType === 'electric' ? VehicleType.ELECTRIC_MOTORBIKE : VehicleType.MOTORBIKE,
            }),
          ...(dto.brand !== undefined && { brand: dto.brand }),
          ...(dto.model !== undefined && { model: dto.model }),
          ...(dto.licensePlate !== undefined && { licensePlate: dto.licensePlate }),
          ...(dto.color !== undefined && { color: dto.color }),
          ...(dto.tireType !== undefined && { tireType: dto.tireType }),
          ...(dto.engineType !== undefined && { engineType: dto.engineType }),
          ...(dto.isDefault === true && { isDefault: true }),
        });
        return repository.save(vehicle);
      });
    } catch (error) {
      this.rethrowDuplicatePlate(error);
      throw error;
    }
  }

  async remove(customerId: number, vehicleId: number): Promise<{ deleted: true; newDefaultVehicleId: number | null }> {
    return this.database.transaction(async (manager) => {
      await this.lockCustomer(manager, customerId);
      const repository = manager.getRepository(Vehicle);
      const vehicle = await repository.findOneBy({ id: vehicleId, customerId });
      if (!vehicle) throw new NotFoundException('Vehicle not found');
      await repository.remove(vehicle);
      let newDefaultVehicleId: number | null = null;
      if (vehicle.isDefault) {
        const replacement = await repository.findOne({
          where: { customerId },
          order: { createdAt: 'ASC', id: 'ASC' },
        });
        if (replacement) {
          replacement.isDefault = true;
          await repository.save(replacement);
          newDefaultVehicleId = replacement.id;
        }
      }
      return { deleted: true, newDefaultVehicleId };
    });
  }

  private async lockCustomer(manager: EntityManager, customerId: number): Promise<void> {
    const customer = await manager.getRepository(User).findOne({
      where: { id: customerId },
      lock: { mode: 'pessimistic_write' },
    });
    if (!customer || customer.role !== UserRole.CUSTOMER) throw new NotFoundException('Customer account not found');
  }

  private rethrowDuplicatePlate(error: unknown): void {
    if (error instanceof QueryFailedError && (error as QueryFailedError & { code?: string }).code === '23505') {
      throw new ConflictException('License plate is already registered');
    }
  }
}
