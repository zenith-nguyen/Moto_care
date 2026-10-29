import { buildPasswordResetEmail } from "./password-reset-email";

describe("buildPasswordResetEmail", () => {
  it("renders the branded Revo code, expiry and inline image references", () => {
    const message = buildPasswordResetEmail("042911");

    expect(message.subject).toBe("Mã xác nhận đặt lại mật khẩu Revo");
    expect(message.text).toContain("REVO");
    expect(message.text).toContain("042911");
    expect(message.text).toContain("1 phút");
    expect(message.html).toContain("042911");
    expect(message.html).toContain("1 phút");
    expect(message.html).toContain("cid:revo-logo@revo.local");
    expect(message.html).toContain("cid:revo-welcome@revo.local");
    expect(message.html).toContain("max-width:440px");
    expect(message.html).toContain('height="94"');
    expect(message.html).toContain("text-align:center");
    expect(message.html).not.toContain("http://");
    expect(message.html).not.toContain("https://");
    expect(message.attachments).toEqual([
      expect.objectContaining({
        filename: "logo-revo.png",
        cid: "revo-logo@revo.local",
        contentDisposition: "inline",
      }),
      expect.objectContaining({
        filename: "welcome-background.png",
        cid: "revo-welcome@revo.local",
        contentDisposition: "inline",
      }),
    ]);
    expect(
      message.attachments.every((attachment) =>
        attachment.path.endsWith(attachment.filename),
      ),
    ).toBe(true);
  });
});
