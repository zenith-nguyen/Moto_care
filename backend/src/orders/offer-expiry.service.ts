import { Injectable, Logger } from '@nestjs/common';
import { Interval } from '@nestjs/schedule';
import { DataSource } from 'typeorm';
import { MatchingService } from './matching.service';

@Injectable()
export class OfferExpiryService {
  private readonly logger = new Logger(OfferExpiryService.name);
  private running = false;

  constructor(private readonly dataSource: DataSource, private readonly matching: MatchingService) {}

  @Interval(5000)
  async expirePendingOffers(): Promise<void> {
    if (this.running) return;
    this.running = true;
    try {
      const expired = (await this.dataSource.query(
        `SELECT id FROM order_offers
         WHERE status = 'PENDING' AND expires_at <= clock_timestamp()
         ORDER BY expires_at ASC LIMIT 100`,
      )) as Array<{ id: number }>;
      for (const offer of expired) {
        try {
          await this.matching.expireOffer(offer.id);
        } catch (error) {
          this.logger.error(`Could not expire offer ${offer.id}`, error instanceof Error ? error.stack : String(error));
        }
      }
    } finally {
      this.running = false;
    }
  }
}
