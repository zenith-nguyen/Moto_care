export type BankTransferInstructions = {
  provider: 'SEPAY';
  mode: 'test' | 'live';
  simulationOnly: boolean;
  paymentCode: string;
  amount: string;
  bank: string;
  accountNumber: string;
  accountHolder: string;
  transferContent: string;
  qrImageUrl: string;
};

export abstract class BankTransferGateway {
  abstract createInstructions(command: { paymentId: number; amount: string }): BankTransferInstructions;

  abstract verifyWebhook(command: {
    rawBody: Buffer | undefined;
    timestamp: string | undefined;
    signature: string | undefined;
  }): string;
}
