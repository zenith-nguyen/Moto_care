import { existsSync } from "node:fs";
import { resolve } from "node:path";
import { PASSWORD_RESET_CODE_TTL_MINUTES } from "./password-recovery.constants";

const REVO_LOGO_CID = "revo-logo@revo.local";
const REVO_WELCOME_CID = "revo-welcome@revo.local";

export interface PasswordResetEmailAttachment {
  filename: string;
  path: string;
  cid: string;
  contentDisposition: "inline";
}

export interface PasswordResetEmail {
  subject: string;
  text: string;
  html: string;
  attachments: PasswordResetEmailAttachment[];
}

function assetPath(filename: string): string {
  const candidates = [
    resolve(process.cwd(), "assets/images", filename),
    resolve(process.cwd(), "../assets/images", filename),
  ];
  const match = candidates.find((candidate) => existsSync(candidate));
  if (!match) {
    throw new Error(`Revo email asset is unavailable: ${filename}`);
  }
  return match;
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
    attachments: [
      {
        filename: "logo-revo.png",
        path: assetPath("logo-revo.png"),
        cid: REVO_LOGO_CID,
        contentDisposition: "inline",
      },
      {
        filename: "welcome-background.png",
        path: assetPath("welcome-background.png"),
        cid: REVO_WELCOME_CID,
        contentDisposition: "inline",
      },
    ],
    html: `<!doctype html>
<html lang="vi">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Mã xác nhận Revo</title>
  </head>
  <body style="margin:0;padding:0;background:#f3f4f6;color:#111827;font-family:Arial,'Helvetica Neue',sans-serif;">
    <div style="display:none;max-height:0;overflow:hidden;opacity:0;">Mã Revo của bạn có hiệu lực trong ${expiryLabel}.</div>
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background:#f3f4f6;">
      <tr>
        <td align="center" style="padding:16px 10px;">
          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="max-width:440px;background:#ffffff;border:1px solid #e5e7eb;border-radius:18px;overflow:hidden;">
            <tr>
              <td background="cid:${REVO_LOGO_CID}" align="center" height="70" style="height:70px;background-color:#050505;background-image:url('cid:${REVO_LOGO_CID}');background-repeat:no-repeat;background-position:center center;background-size:300px 300px;padding:0;">
                <span style="font-size:1px;line-height:1px;color:#050505;">Revo</span>
              </td>
            </tr>
            <tr>
              <td background="cid:${REVO_WELCOME_CID}" height="94" valign="bottom" style="height:94px;background-color:#f8fafc;background-image:url('cid:${REVO_WELCOME_CID}');background-repeat:no-repeat;background-position:center 65%;background-size:cover;">
                <div style="padding:8px 14px;background:#202020;color:#f3f4f6;text-align:center;font-size:11px;line-height:16px;font-weight:600;letter-spacing:0.35px;">
                  An tâm trên mọi hành trình <span style="color:#7db5ff;font-weight:800;">cùng Revo</span>
                </div>
              </td>
            </tr>
            <tr>
              <td style="padding:18px 22px 20px;">
                <div style="font-size:11px;line-height:16px;font-weight:700;letter-spacing:1.1px;color:#2563eb;">BẢO MẬT TÀI KHOẢN</div>
                <h1 style="margin:4px 0 8px;font-size:22px;line-height:28px;color:#111827;">Đặt lại mật khẩu</h1>
                <p style="margin:0 0 12px;font-size:14px;line-height:21px;color:#374151;">Dùng mã này để tiếp tục đặt lại mật khẩu Revo:</p>
                <div style="margin:11px 0;padding:12px 10px;border:2px solid #111827;border-radius:13px;background:#ffffff;text-align:center;font-size:28px;line-height:34px;font-weight:800;letter-spacing:7px;color:#111827;">${code}</div>
                <div style="margin:0 0 14px;padding:10px 12px;border-radius:12px;background:#eaf1fc;color:#1e5fae;font-size:13px;line-height:19px;">
                  Mã có hiệu lực trong <strong>${expiryLabel}</strong>. Hết hạn, bạn cần yêu cầu mã mới.
                </div>
                <p style="margin:0;font-size:12px;line-height:18px;color:#5f6368;">Không chia sẻ mã cho bất kỳ ai. Nếu bạn không gửi yêu cầu này, hãy bỏ qua email; mật khẩu hiện tại vẫn được giữ nguyên.</p>
              </td>
            </tr>
            <tr>
              <td style="border-top:1px solid #e5e7eb;padding:10px 22px;background:#fafafa;font-size:10px;line-height:15px;color:#73777f;">
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
