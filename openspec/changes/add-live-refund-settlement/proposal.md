# Settle refunds outside demo mode

## Why

Writing the capability specs surfaced a dead end in the money path. A customer
who cancels after paying moves their payment to `REFUND_PENDING`, and the order
to `REFUND_PENDING` with it. Only one code path ever writes `REFUNDED`, and it
is the demo settlement path, which refuses to run in production.

So in live mode the refund is real but the record is not: the money is returned
by hand at the bank, while the payment and the order stay `REFUND_PENDING`
forever. The consequences are concrete:

- The admin refund queue never empties, so a genuinely outstanding refund is
  indistinguishable from one already paid back.
- Reconciliation counts the amount as still owed, and the "payment refund
  pending but order is not" flag cannot clear.
- The customer keeps seeing "refund is being processed" after they have the
  money.

This is a reporting and reconciliation gap, not lost money. It is written down
here rather than fixed quietly because it touches the money path, where the
project requires a human decision before anything changes.

## What changes

Give an administrator a way to record that a refund has been paid, and only
that. No automatic outbound transfer is introduced: the transfer itself stays
manual at the bank, exactly like mechanic payouts.

- An administrator can mark a `REFUND_PENDING` payment as refunded, supplying
  the bank reference of the transfer they made.
- The action is idempotent and rejects a bank reference already recorded against
  another payment.
- Settling the payment moves the order to `REFUNDED`, which the existing status
  machine already allows.
- The refund queue, the reconciliation flags and the customer-visible status all
  follow from that single state change; none of them need their own fix.

## Out of scope

- Initiating a bank transfer from the system. Outbound money stays manual and
  human-approved.
- Partial refunds. Today a refund is the whole prepayment.
- Any change to when a refund becomes due; cancellation rules stay as they are.
- Automatic matching of an incoming SePay payout notification to a refund. The
  payout reconciliation flow already exists for mechanic payouts and
  deliberately ends in manual review; wiring refunds into it is a separate
  decision.

## Money impact

Recording only. The change adds no code path that moves money out of the
account, and it cannot credit a wallet. It changes which rows an administrator
sees as outstanding.
