import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DataSource, In, QueryFailedError } from 'typeorm';
import { OrderStatus } from '../common/enums/order-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { moneyToCents, centsToMoney } from '../common/utils/money';
import { Order } from '../orders/order.entity';
import {
  CreateSkillDto,
  ProviderWeeklyStatsQueryDto,
  ReplaceProviderSkillsDto,
  ReviewProviderSkillDto,
  UpdateProviderProfileDto,
  UpdateProviderTierDto,
  UpdateSkillDto,
} from './dto/provider-profile.dto';
import { ProviderSkill } from './provider-skill.entity';
import { Provider } from './provider.entity';
import { SkillVerificationStatus } from './skill-verification-status.enum';
import { Skill } from './skill.entity';

type MoneySummaryRow = {
  credited_amount: string;
  debited_amount: string;
};

type RatingSummaryRow = {
  review_count: string;
  average_rating: string | null;
};

const activeContactStatuses = new Set<OrderStatus>([
  OrderStatus.ACCEPTED,
  OrderStatus.ARRIVED,
  OrderStatus.IN_PROGRESS,
  OrderStatus.AWAITING_PRICE_APPROVAL,
  OrderStatus.PRICE_DISPUTED,
  OrderStatus.AWAITING_PAYMENT,
  OrderStatus.PAID,
  OrderStatus.COMPLETED,
]);

@Injectable()
export class ProviderProfilesService {
  constructor(private readonly database: DataSource) {}

  private async ownProvider(userId: number): Promise<Provider> {
    const provider = await this.database.getRepository(Provider).findOne({
      where: { userId },
      relations: { user: true },
    });
    if (!provider) throw new NotFoundException('Provider profile not found');
    return provider;
  }

  private async skillsForProvider(providerId: number, verifiedOnly = false) {
    const repository = this.database.getRepository(ProviderSkill);
    const where = verifiedOnly
      ? { providerId, verificationStatus: SkillVerificationStatus.VERIFIED }
      : { providerId };
    const providerSkills = await repository.find({
      where,
      relations: { skill: true },
      order: { skill: { name: 'ASC' }, id: 'ASC' },
    });
    return providerSkills.map((providerSkill) => ({
      id: providerSkill.skill.id,
      code: providerSkill.skill.code,
      name: providerSkill.skill.name,
      verificationStatus: providerSkill.verificationStatus,
    }));
  }

  private async present(provider: Provider, verifiedOnly = false) {
    return {
      id: provider.id,
      name: provider.user.name,
      bio: provider.bio,
      yearsOfExperience: provider.yearsOfExperience,
      serviceRadiusKm: provider.serviceRadiusKm,
      tier: provider.tier,
      skills: await this.skillsForProvider(provider.id, verifiedOnly),
    };
  }

  async getOwnProfile(userId: number) {
    return this.present(await this.ownProvider(userId));
  }

  async updateOwnProfile(userId: number, dto: UpdateProviderProfileDto) {
    const provider = await this.ownProvider(userId);
    if (dto.bio !== undefined) provider.bio = dto.bio;
    if (dto.yearsOfExperience !== undefined) provider.yearsOfExperience = dto.yearsOfExperience;
    if (dto.serviceRadiusKm !== undefined) provider.serviceRadiusKm = dto.serviceRadiusKm.toFixed(2);
    await this.database.getRepository(Provider).save(provider);
    return this.present(provider);
  }

  async replaceOwnSkills(userId: number, dto: ReplaceProviderSkillsDto) {
    await this.database.transaction(async (manager) => {
      const provider = await manager.getRepository(Provider).findOne({
        where: { userId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!provider) throw new NotFoundException('Provider profile not found');

      const selectedSkills = dto.skillIds.length
        ? await manager.getRepository(Skill).findBy({ id: In(dto.skillIds), isActive: true })
        : [];
      if (selectedSkills.length !== dto.skillIds.length) {
        throw new BadRequestException('Every selected skill must exist and be active');
      }

      const repository = manager.getRepository(ProviderSkill);
      const existing = await repository.findBy({ providerId: provider.id });
      const selectedIds = new Set(dto.skillIds);
      const removed = existing.filter((item) => !selectedIds.has(item.skillId));
      if (removed.length) await repository.remove(removed);

      const existingBySkill = new Map(existing.map((item) => [item.skillId, item]));
      for (const skillId of dto.skillIds) {
        const current = existingBySkill.get(skillId);
        if (!current) {
          await repository.save(repository.create({
            providerId: provider.id,
            skillId,
            verificationStatus: SkillVerificationStatus.PENDING,
            verifiedAt: null,
          }));
        } else if (current.verificationStatus === SkillVerificationStatus.REJECTED) {
          current.verificationStatus = SkillVerificationStatus.PENDING;
          current.verifiedAt = null;
          await repository.save(current);
        }
      }
    });
    return this.getOwnProfile(userId);
  }

  async listActiveSkills() {
    return this.database.getRepository(Skill).find({
      where: { isActive: true },
      select: { id: true, code: true, name: true, isActive: true },
      order: { name: 'ASC', id: 'ASC' },
    });
  }

  async assignedProviderProfile(orderId: number, actorId: number, actorRole: UserRole) {
    const order = await this.database.getRepository(Order).findOne({
      where: { id: orderId },
      relations: { provider: { user: true } },
    });
    if (!order?.provider || !activeContactStatuses.has(order.status)) {
      throw new NotFoundException('Assigned provider profile not found');
    }
    const allowed = actorRole === UserRole.CUSTOMER
      ? order.customerId === actorId
      : actorRole === UserRole.PROVIDER && order.provider.userId === actorId;
    if (!allowed) throw new NotFoundException('Assigned provider profile not found');

    const summary = await this.present(order.provider, true);
    const rating = await this.ratingSummary(order.provider.userId, null, null);
    return {
      ...summary,
      reviewCount: Number(rating.review_count),
      averageRating: rating.average_rating,
    };
  }

  async weeklyStatistics(userId: number, query: ProviderWeeklyStatsQueryDto) {
    const provider = await this.ownProvider(userId);
    const { start, end, label } = this.weekRange(query.week_start);
    const orderRows = await this.database.query<Array<{ completed_orders: string }>>(
      `SELECT COUNT(*)::text AS completed_orders
       FROM orders
       WHERE provider_id = $1 AND status = $2 AND updated_at >= $3 AND updated_at < $4`,
      [provider.id, OrderStatus.COMPLETED, start, end],
    );
    const rating = await this.ratingSummary(provider.userId, start, end);
    const moneyRows = await this.database.query<MoneySummaryRow[]>(
      `SELECT
         COALESCE(SUM(wt.amount) FILTER (WHERE wt.type = 'CREDIT'), 0)::text AS credited_amount,
         COALESCE(SUM(wt.amount) FILTER (WHERE wt.type = 'DEBIT'), 0)::text AS debited_amount
       FROM wallets w
       LEFT JOIN wallet_transactions wt
         ON wt.wallet_id = w.id AND wt.created_at >= $2 AND wt.created_at < $3
       WHERE w.provider_id = $1`,
      [provider.id, start, end],
    );
    const money = moneyRows[0] ?? { credited_amount: '0', debited_amount: '0' };
    const credited = centsToMoney(moneyToCents(money.credited_amount));
    const debited = centsToMoney(moneyToCents(money.debited_amount));
    return {
      weekStart: label,
      weekEndExclusive: this.localDate(end),
      timezone: 'Asia/Ho_Chi_Minh',
      completedOrders: Number(orderRows[0]?.completed_orders ?? 0),
      reviewCount: Number(rating.review_count),
      averageRating: rating.average_rating,
      creditedAmount: credited,
      debitedAmount: debited,
    };
  }

  async listAllSkills() {
    return this.database.getRepository(Skill).find({ order: { name: 'ASC', id: 'ASC' } });
  }

  async createSkill(dto: CreateSkillDto) {
    try {
      return await this.database.getRepository(Skill).save(
        this.database.getRepository(Skill).create({ ...dto, isActive: true }),
      );
    } catch (error) {
      if (error instanceof QueryFailedError && (error as QueryFailedError & { code?: string }).code === '23505') {
        throw new ConflictException('Skill code already exists');
      }
      throw error;
    }
  }

  async updateSkill(skillId: number, dto: UpdateSkillDto) {
    const skill = await this.database.getRepository(Skill).findOneBy({ id: skillId });
    if (!skill) throw new NotFoundException('Skill not found');
    if (dto.code !== undefined) skill.code = dto.code;
    if (dto.name !== undefined) skill.name = dto.name;
    if (dto.isActive !== undefined) skill.isActive = dto.isActive;
    try {
      return await this.database.getRepository(Skill).save(skill);
    } catch (error) {
      if (error instanceof QueryFailedError && (error as QueryFailedError & { code?: string }).code === '23505') {
        throw new ConflictException('Skill code already exists');
      }
      throw error;
    }
  }

  async updateTier(providerId: number, dto: UpdateProviderTierDto) {
    const provider = await this.database.getRepository(Provider).findOneBy({ id: providerId });
    if (!provider) throw new NotFoundException('Provider profile not found');
    provider.tier = dto.tier;
    await this.database.getRepository(Provider).save(provider);
    return { providerId: provider.id, tier: provider.tier };
  }

  async reviewSkill(providerId: number, skillId: number, dto: ReviewProviderSkillDto) {
    const providerSkill = await this.database.getRepository(ProviderSkill).findOne({
      where: { providerId, skillId },
      relations: { skill: true },
    });
    if (!providerSkill) throw new NotFoundException('Provider skill not found');
    if (dto.verificationStatus === SkillVerificationStatus.VERIFIED && !providerSkill.skill.isActive) {
      throw new ConflictException('Inactive skills cannot be verified');
    }
    providerSkill.verificationStatus = dto.verificationStatus;
    providerSkill.verifiedAt = dto.verificationStatus === SkillVerificationStatus.VERIFIED ? new Date() : null;
    await this.database.getRepository(ProviderSkill).save(providerSkill);
    return {
      providerId,
      skillId,
      verificationStatus: providerSkill.verificationStatus,
      verifiedAt: providerSkill.verifiedAt,
    };
  }

  private async ratingSummary(userId: number, start: Date | null, end: Date | null): Promise<RatingSummaryRow> {
    const parameters: unknown[] = [userId];
    let period = '';
    if (start && end) {
      parameters.push(start, end);
      period = ' AND created_at >= $2 AND created_at < $3';
    }
    const rows = await this.database.query<RatingSummaryRow[]>(
      `SELECT COUNT(*)::text AS review_count,
              CASE WHEN COUNT(*) = 0 THEN NULL ELSE ROUND(AVG(rating)::numeric, 2)::text END AS average_rating
       FROM reviews WHERE reviewee_id = $1${period}`,
      parameters,
    );
    return rows[0] ?? { review_count: '0', average_rating: null };
  }

  private weekRange(requested?: string): { start: Date; end: Date; label: string } {
    let label = requested;
    if (!label) {
      const localNow = new Date(Date.now() + 7 * 60 * 60 * 1000);
      const day = (localNow.getUTCDay() + 6) % 7;
      localNow.setUTCDate(localNow.getUTCDate() - day);
      label = localNow.toISOString().slice(0, 10);
    }
    const calendarDay = new Date(`${label}T00:00:00Z`);
    if (Number.isNaN(calendarDay.getTime()) || calendarDay.getUTCDay() !== 1) {
      throw new BadRequestException('week_start must be a valid Monday');
    }
    const start = new Date(`${label}T00:00:00+07:00`);
    const end = new Date(start.getTime() + 7 * 24 * 60 * 60 * 1000);
    return { start, end, label };
  }

  private localDate(date: Date): string {
    return new Date(date.getTime() + 7 * 60 * 60 * 1000).toISOString().slice(0, 10);
  }
}
