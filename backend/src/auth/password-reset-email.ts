import { PASSWORD_RESET_CODE_TTL_MINUTES } from "./password-recovery.constants";

export interface PasswordResetEmail {
  subject: string;
  text: string;
  html: string;
}

export function buildPasswordResetEmail(code: string): PasswordResetEmail {
  const expiryLabel = `${PASSWORD_RESET_CODE_TTL_MINUTES} phút`;

  return {
    subject: "Mã xác nhận đặt lại mật khẩu Revo",
    text: [
      "REVO — Hỗ trợ cứu hộ và sửa xe",
      "",
      `Mã xác nhận đặt lại mật khẩu của bạn là: ${code}`,
      `Mã chỉ có hiệu lực trong ${expiryLabel}.`,
      "",
      "Không chia sẻ mã này với bất kỳ ai. Nhân viên Revo sẽ không bao giờ hỏi mã xác nhận của bạn.",
      "Nếu bạn không yêu cầu đặt lại mật khẩu, hãy bỏ qua email này.",
    ].join("\n"),
    html: `<!doctype html>
<html lang="vi">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Mã xác nhận Revo</title>
  </head>
  <body style="margin:0;padding:0;background:#f5f5f7;color:#111111;font-family:Arial,'Helvetica Neue',sans-serif;">
    <div style="display:none;max-height:0;overflow:hidden;opacity:0;">Mã Revo của bạn có hiệu lực trong ${expiryLabel}.</div>
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background:#f5f5f7;">
      <tr>
        <td align="center" style="padding:32px 16px;">
          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="max-width:560px;background:#ffffff;border:1px solid #e8e8eb;border-radius:24px;overflow:hidden;">
            <tr>
              <td style="background:#111111;padding:28px 32px;color:#ffffff;">
                <div style="font-size:34px;line-height:38px;font-weight:900;letter-spacing:-1px;">REVO</div>
                <div style="margin-top:6px;font-size:13px;line-height:20px;color:#d7d7dc;">Hỗ trợ cứu hộ và sửa xe, ngay khi bạn cần.</div>
              </td>
            </tr>
            <tr>
              <td style="padding:32px;">
                <table role="presentation" cellspacing="0" cellpadding="0" border="0">
                  <tr>
                    <td style="width:44px;height:44px;border-radius:14px;background:#eaf1fc;text-align:center;font-size:22px;">🚗</td>
                    <td style="padding-left:14px;">
                      <div style="font-size:13px;line-height:18px;color:#77777c;">BẢO MẬT TÀI KHOẢN</div>
                      <div style="font-size:20px;line-height:28px;font-weight:700;color:#111111;">Đặt lại mật khẩu</div>
                    </td>
                  </tr>
                </table>
                <p style="margin:26px 0 10px;font-size:16px;line-height:25px;color:#333337;">Dùng mã xác nhận dưới đây để tiếp tục đặt lại mật khẩu Revo:</p>
                <div style="margin:20px 0;padding:22px 16px;border:2px solid #111111;border-radius:18px;background:#ffffff;text-align:center;font-size:34px;line-height:40px;font-weight:800;letter-spacing:10px;color:#111111;">${code}</div>
                <div style="margin:0 0 24px;padding:14px 16px;border-radius:14px;background:#eaf1fc;color:#1e5fae;font-size:14px;line-height:21px;">
                  Mã chỉ có hiệu lực trong <strong>${expiryLabel}</strong>. Sau thời gian này, bạn cần yêu cầu mã mới.
                </div>
                <p style="margin:0;font-size:14px;line-height:22px;color:#5f5f65;">Không chia sẻ mã này với bất kỳ ai. Nhân viên Revo sẽ không bao giờ hỏi mã xác nhận của bạn.</p>
                <p style="margin:12px 0 0;font-size:14px;line-height:22px;color:#5f5f65;">Nếu bạn không yêu cầu đặt lại mật khẩu, hãy bỏ qua email này. Mật khẩu hiện tại của bạn vẫn được giữ nguyên.</p>
              </td>
            </tr>
            <tr>
              <td style="border-top:1px solid #e8e8eb;padding:20px 32px;background:#fafafa;font-size:12px;line-height:18px;color:#77777c;">
                Email bảo mật được gửi tự động bởi Revo. Vui lòng không trả lời email này.
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>`,
  };
}
