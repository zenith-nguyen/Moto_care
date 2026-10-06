import { BadRequestException, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DataSource, EntityManager } from 'typeorm';
import { ApprovalStatus } from '../common/enums/approval-status.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { PaymentStatus } from '../common/enums/payment-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import {
  AdminPeriodQueryDto,
  AdminTimeseriesQueryDto,
} from './dto/admin-period-query.dto';
import { ReconciliationQueryDto } from './dto/reconciliation-query.dto';

const timezone = 'Asia/Ho_Chi_Minh';
const defaultPeriodMs = 7 * 24 * 60 * 60 * 1000;
const maximumPeriodMs = 366 * 24 * 60 * 60 * 1000;

type Period = { from: Date; to: Date };
type CountRow = { total: number; [key: string]: number };
type StatusCountRow = { status: string; count: number };
type MoneyRow = {
  collectedInPeriod: string;
  heldCurrent: string;
  settledToProvidersInPeriod: string;
  refundPendingCurrent: string;
  refundedInPeriod: string;
  grossCompletedValueInPeriod: string;
};
type TimeseriesRow = {
  day: string;
  ordersCreated: number;
  ordersCompleted: number;
  collected: string;
  settledToProviders: string;
  refunded: string;
};
type ReconciliationRow = {
  totalCount: number;
  orderId: number;
  orderCode: string;
  orderStatus: OrderStatus;
  orderCreatedAt: Date;
  customerId: number;
  customerName: string;
  providerId: number | null;
  providerName: string | null;
  finalPrice: string | null;
  paymentId: number | null;
  paymentStatus: PaymentStatus | null;
  paymentAmount: string | null;
  paidAt: Date | null;
  refundedAt: Date | null;
  isDemo: boolean | null;
  paymentCount: number;
  creditCount: number;
  creditedAmount: string;
  completedMissingPaidPayment: boolean;
  paymentFinalPriceMismatch: boolean;
  completedWalletCreditMismatch: boolean;
  refundStatusMismatch: boolean;
  refundedWithCredit: boolean;
  multiplePayments: boolean;
};

@Injectable()
export class AdminAnalyticsService {
  constructor(
    private readonly database: DataSource,
    private readonly config: ConfigService,
  ) {}

  async summary(query: AdminPeriodQueryDto) {
    const period = this.resolvePeriod(query);
    const freshnessSeconds =
      this.config.get<number>('PROVIDER_LOCATION_MAX_AGE_SECONDS') ?? 120;
    const [users, providers, orderRows, moneyRows] = await Promise.all([
      this.database.query<CountRow[]>(
        `
        SELECT
          COUNT(*)::int AS "total",
          COUNT(*) FILTER (WHERE role = '${UserRole.CUSTOMER}')::int AS "customers",
          COUNT(*) FILTER (WHERE role = '${UserRole.PROVIDER}')::int AS "providers",
          COUNT(*) FILTER (WHERE role = '${UserRole.ADMIN}')::int AS "admins",
          COUNT(*) FILTER (WHERE created_at >= $1 AND created_at < $2)::int AS "createdInPeriod"
        FROM users
      `,
        [period.from, period.to],
      ),
      this.database.query<CountRow[]>(
        `
        SELECT
          COUNT(*)::int AS "total",
          COUNT(*) FILTER (WHERE approval_status = '${ApprovalStatus.PENDING}')::int AS "pending",
          COUNT(*) FILTER (WHERE approval_status = '${ApprovalStatus.APPROVED}')::int AS "approved",
          COUNT(*) FILTER (WHERE approval_status = '${ApprovalStatus.REJECTED}')::int AS "rejected",
          COUNT(*) FILTER (WHERE is_online = true)::int AS "online",
          COUNT(*) FILTER (
            WHERE current_location IS NOT NULL
              AND last_seen_at >= now() - ($1 * interval '1 second')
          )::int AS "freshLocation"
        FROM providers
      `,
        [freshnessSeconds],
      ),
      this.database.query<StatusCountRow[]>(
        `
        SELECT status::text AS "status", COUNT(*)::int AS "count"
        FROM orders
        WHERE created_at >= $1 AND created_at < $2
        GROUP BY status
      `,
        [period.from, period.to],
      ),
      this.database.query<MoneyRow[]>(
        `
        SELECT
          (
            SELECT COALESCE(SUM(amount), 0)::numeric(18,2)::text
            FROM payments
            WHERE paid_at >= $1 AND paid_at < $2
              AND status IN ('${PaymentStatus.PAID}', '${PaymentStatus.REFUND_PENDING}', '${PaymentStatus.REFUNDED}')
          ) AS "collectedInPeriod",
          (
            SELECT COALESCE(SUM(p.amount), 0)::numeric(18,2)::text
            FROM payments p
            JOIN orders o ON o.id = p.order_id
            WHERE p.paid_at IS NOT NULL
              AND p.status IN ('${PaymentStatus.PAID}', '${PaymentStatus.REFUND_PENDING}')
              AND o.status NOT IN ('${OrderStatus.COMPLETED}', '${OrderStatus.REFUNDED}')
          ) AS "heldCurrent",
          (
            SELECT COALESCE(SUM(amount), 0)::numeric(18,2)::text
            FROM wallet_transactions
            WHERE type = 'CREDIT' AND created_at >= $1 AND created_at < $2
          ) AS "settledToProvidersInPeriod",
          (
            SELECT COALESCE(SUM(amount), 0)::numeric(18,2)::text
            FROM payments WHERE status = '${PaymentStatus.REFUND_PENDING}'
          ) AS "refundPendingCurrent",
          (
            SELECT COALESCE(SUM(amount), 0)::numeric(18,2)::text
            FROM payments
            WHERE status = '${PaymentStatus.REFUNDED}' AND refunded_at >= $1 AND refunded_at < $2
          ) AS "refundedInPeriod",
          (
            SELECT COALESCE(SUM(o.final_price), 0)::numeric(18,2)::text
            FROM wallet_transactions wt
            JOIN orders o ON o.id = wt.order_id
            WHERE wt.type = 'CREDIT' AND wt.created_at >= $1 AND wt.created_at < $2
          ) AS "grossCompletedValueInPeriod"
      `,
        [period.from, period.to],
      ),
    ]);

    const byStatus = Object.fromEntries(
      Object.values(OrderStatus).map((status) => [status, 0]),
    );
    for (const row of orderRows) byStatus[row.status] = row.count;
    const totalOrders = orderRows.reduce((sum, row) => sum + row.count, 0);
    const completed = byStatus[OrderStatus.COMPLETED];
    const closed =
      completed +
      byStatus[OrderStatus.CANCELLED] +
      byStatus[OrderStatus.REFUNDED];

    return {
      period: this.periodResponse(period),
      generatedAt: new Date().toISOString(),
      sandboxOnly: true,
      users: users[0],
      providers: providers[0],
      orders: {
        total: totalOrders,
        byStatus,
        completionRate:
          closed === 0 ? 0 : Number(((completed / closed) * 100).toFixed(2)),
      },
      money: moneyRows[0],
    };
  }

  async timeseries(query: AdminTimeseriesQueryDto) {
    const period = this.resolvePeriod(query);
    const rows = await this.database.query<TimeseriesRow[]>(
      `
      WITH days AS (
        SELECT generate_series(
          date_trunc('day', timezone('${timezone}', $1::timestamptz)),
          date_trunc('day', timezone('${timezone}', $2::timestamptz - interval '1 microsecond')),
          interval '1 day'
        )::date AS day
      ), order_daily AS (
        SELECT timezone('${timezone}', created_at)::date AS day, COUNT(*)::int AS count
        FROM orders WHERE created_at >= $1 AND created_at < $2 GROUP BY 1
      ), paid_daily AS (
        SELECT timezone('${timezone}', paid_at)::date AS day, SUM(amount)::numeric(18,2) AS amount
        FROM payments
        WHERE paid_at >= $1 AND paid_at < $2
          AND status IN ('${PaymentStatus.PAID}', '${PaymentStatus.REFUND_PENDING}', '${PaymentStatus.REFUNDED}')
        GROUP BY 1
      ), refunded_daily AS (
        SELECT timezone('${timezone}', refunded_at)::date AS day, SUM(amount)::numeric(18,2) AS amount
        FROM payments
        WHERE status = '${PaymentStatus.REFUNDED}' AND refunded_at >= $1 AND refunded_at < $2
        GROUP BY 1
      ), settled_daily AS (
        SELECT
          timezone('${timezone}', created_at)::date AS day,
          COUNT(DISTINCT order_id)::int AS orders,
          SUM(amount)::numeric(18,2) AS amount
        FROM wallet_transactions
        WHERE type = 'CREDIT' AND created_at >= $1 AND created_at < $2
        GROUP BY 1
      )
      SELECT
        d.day::text AS "day",
        COALESCE(o.count, 0)::int AS "ordersCreated",
        COALESCE(s.orders, 0)::int AS "ordersCompleted",
        COALESCE(p.amount, 0)::numeric(18,2)::text AS "collected",
        COALESCE(s.amount, 0)::numeric(18,2)::text AS "settledToProviders",
        COALESCE(r.amount, 0)::numeric(18,2)::text AS "refunded"
      FROM days d
      LEFT JOIN order_daily o USING (day)
      LEFT JOIN paid_daily p USING (day)
      LEFT JOIN refunded_daily r USING (day)
      LEFT JOIN settled_daily s USING (day)
      ORDER BY d.day
    `,
      [period.from, period.to],
    );
    return {
      period: this.periodResponse(period),
      bucket: query.bucket,
      sandboxOnly: true,
      data: rows,
    };
  }

  async reconciliation(query: ReconciliationQueryDto) {
    const period = this.resolvePeriod(query);
    return this.database.transaction('REPEATABLE READ', async (manager) => {
      const total = await this.reconciliationCount(
        manager,
        period,
        query.status,
      );
      const rows = await this.reconciliationRows(manager, period, query);
      return {
        period: this.periodResponse(period),
        sandboxOnly: true,
        page: query.page,
        limit: query.limit,
        total,
        totalPages: total === 0 ? 0 : Math.ceil(total / query.limit),
        items: rows.map((row) => this.mapReconciliationRow(row)),
      };
    });
  }

  private resolvePeriod(query: AdminPeriodQueryDto): Period {
    const to = query.to ? new Date(query.to) : new Date();
    const from = query.from
      ? new Date(query.from)
      : new Date(to.getTime() - defaultPeriodMs);
    if (from >= to)
      throw new BadRequestException('`from` must be earlier than `to`');
    if (to.getTime() - from.getTime() > maximumPeriodMs) {
      throw new BadRequestException('Dashboard period cannot exceed 366 days');
    }
    return { from, to };
  }

  private periodResponse(period: Period) {
    return {
      from: period.from.toISOString(),
      to: period.to.toISOString(),
      timezone,
    };
  }

  private async reconciliationCount(
    manager: EntityManager,
    period: Period,
    status?: PaymentStatus,
  ): Promise<number> {
    const rows = await manager.query<Array<{ total: number }>>(
      `
      SELECT COUNT(*)::int AS "total"
      FROM orders o
      LEFT JOIN payments p ON p.id = (SELECT MIN(p1.id) FROM payments p1 WHERE p1.order_id = o.id)
      WHERE o.created_at >= $1 AND o.created_at < $2
        AND ($3::payment_status_enum IS NULL OR p.status = $3::payment_status_enum)
    `,
      [period.from, period.to, status ?? null],
    );
    return rows[0]?.total ?? 0;
  }

  private reconciliationRows(
    manager: EntityManager,
    period: Period,
    query: ReconciliationQueryDto,
  ): Promise<ReconciliationRow[]> {
    return manager.query<ReconciliationRow[]>(
      `
      WITH payment_rollup AS (
        SELECT order_id, COUNT(*)::int AS payment_count, MIN(id) AS first_payment_id
        FROM payments GROUP BY order_id
      ), credit_rollup AS (
        SELECT
          order_id,
          COUNT(*) FILTER (WHERE type = 'CREDIT')::int AS credit_count,
          COALESCE(SUM(amount) FILTER (WHERE type = 'CREDIT'), 0)::numeric(18,2) AS credited_amount
        FROM wallet_transactions WHERE order_id IS NOT NULL GROUP BY order_id
      )
      SELECT
        o.id AS "orderId", o.code AS "orderCode", o.status AS "orderStatus",
        o.created_at AS "orderCreatedAt", o.final_price::text AS "finalPrice",
        customer.id AS "customerId", customer.name AS "customerName",
        provider.id AS "providerId", provider_user.name AS "providerName",
        p.id AS "paymentId", p.status AS "paymentStatus", p.amount::text AS "paymentAmount",
        p.paid_at AS "paidAt", p.refunded_at AS "refundedAt", p.is_demo AS "isDemo",
        COALESCE(pr.payment_count, 0)::int AS "paymentCount",
        COALESCE(cr.credit_count, 0)::int AS "creditCount",
        COALESCE(cr.credited_amount, 0)::numeric(18,2)::text AS "creditedAmount",
        (o.status = '${OrderStatus.COMPLETED}' AND (p.id IS NULL OR p.status <> '${PaymentStatus.PAID}'))
          AS "completedMissingPaidPayment",
        (p.paid_at IS NOT NULL AND o.final_price IS NOT NULL AND p.amount <> o.final_price)
          AS "paymentFinalPriceMismatch",
        (o.status = '${OrderStatus.COMPLETED}' AND COALESCE(cr.credit_count, 0) <> 1)
          AS "completedWalletCreditMismatch",
        (COALESCE(p.status = '${PaymentStatus.REFUND_PENDING}', false)
          IS DISTINCT FROM (o.status = '${OrderStatus.REFUND_PENDING}'))
          AS "refundStatusMismatch",
        (p.status = '${PaymentStatus.REFUNDED}' AND COALESCE(cr.credit_count, 0) > 0)
          AS "refundedWithCredit",
        (COALESCE(pr.payment_count, 0) > 1) AS "multiplePayments"
      FROM orders o
      JOIN users customer ON customer.id = o.customer_id
      LEFT JOIN providers provider ON provider.id = o.provider_id
      LEFT JOIN users provider_user ON provider_user.id = provider.user_id
      LEFT JOIN payment_rollup pr ON pr.order_id = o.id
      LEFT JOIN payments p ON p.id = pr.first_payment_id
      LEFT JOIN credit_rollup cr ON cr.order_id = o.id
      WHERE o.created_at >= $1 AND o.created_at < $2
        AND ($3::payment_status_enum IS NULL OR p.status = $3::payment_status_enum)
      ORDER BY o.created_at DESC, o.id DESC
      LIMIT $4 OFFSET $5
    `,
      [
        period.from,
        period.to,
        query.status ?? null,
        query.limit,
        (query.page - 1) * query.limit,
      ],
    );
  }

  private mapReconciliationRow(row: ReconciliationRow) {
    const flags = [
      row.completedMissingPaidPayment && 'COMPLETED_MISSING_PAID_PAYMENT',
      row.paymentFinalPriceMismatch && 'PAYMENT_FINAL_PRICE_MISMATCH',
      row.completedWalletCreditMismatch && 'COMPLETED_WALLET_CREDIT_MISMATCH',
      row.refundStatusMismatch && 'REFUND_STATUS_MISMATCH',
      row.refundedWithCredit && 'REFUNDED_WITH_WALLET_CREDIT',
      row.multiplePayments && 'MULTIPLE_PAYMENTS',
    ].filter((flag): flag is string => Boolean(flag));
    return {
      order: {
        id: row.orderId,
        code: row.orderCode,
        status: row.orderStatus,
        createdAt: row.orderCreatedAt,
        finalPrice: row.finalPrice,
        customer: { id: row.customerId, name: row.customerName },
        provider: row.providerId
          ? { id: row.providerId, name: row.providerName }
          : null,
      },
      payment: row.paymentId
        ? {
            id: row.paymentId,
            status: row.paymentStatus,
            amount: row.paymentAmount,
            paidAt: row.paidAt,
            refundedAt: row.refundedAt,
            isDemo: row.isDemo,
            paymentCount: row.paymentCount,
          }
        : null,
      settlement: {
        creditCount: row.creditCount,
        creditedAmount: row.creditedAmount,
      },
      flags,
    };
  }
}
