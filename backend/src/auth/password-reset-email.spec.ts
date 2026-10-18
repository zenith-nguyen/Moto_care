import { buildPasswordResetEmail } from "./password-reset-email";

describe("buildPasswordResetEmail", () => {
  it("renders the Revo password reset code and one-minute expiry in both formats", () => {
    const message = buildPasswordResetEmail("042911");

    expect(message.subject).toBe("Mã xác nhận đặt lại mật khẩu Revo");
    expect(message.text).toContain("REVO");
    expect(message.text).toContain("042911");
    expect(message.text).toContain("1 phút");
    expect(message.html).toContain("REVO");
    expect(message.html).toContain("042911");
    expect(message.html).toContain("1 phút");
    expect(message.html).toContain("#eaf1fc");
    expect(message.html).not.toContain("http://");
    expect(message.html).not.toContain("https://");
  });
});
