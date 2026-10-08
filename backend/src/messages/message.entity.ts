import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Order } from '../orders/order.entity';
import { User } from '../users/user.entity';

@Entity({ name: 'messages' })
@Index('IDX_messages_order_created', ['orderId', 'createdAt'])
export class Message {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ name: 'order_id' })
  orderId!: number;

  @ManyToOne(() => Order, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'order_id' })
  order!: Order;

  @Column({ name: 'sender_id' })
  senderId!: number;

  @ManyToOne(() => User, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'sender_id' })
  sender!: User;

  @Column({ type: 'text', nullable: true })
  content!: string | null;

  @Column({ name: 'image_storage_key', type: 'varchar', length: 100, nullable: true })
  imageStorageKey!: string | null;

  @Column({ name: 'image_mime_type', type: 'varchar', length: 50, nullable: true })
  imageMimeType!: string | null;

  @Column({ name: 'image_size_bytes', type: 'integer', nullable: true })
  imageSizeBytes!: number | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;
}
