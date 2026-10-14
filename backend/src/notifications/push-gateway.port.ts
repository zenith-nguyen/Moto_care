export interface PushMessage {
  title: string;
  body: string;
  data: Record<string, string>;
  expiresAt: Date | null;
}

export interface PushResult {
  success: boolean;
  errorCode?: string;
  permanent?: boolean;
}

export abstract class PushGateway {
  abstract readonly enabled: boolean;
  abstract send(token: string, message: PushMessage): Promise<PushResult>;
}
