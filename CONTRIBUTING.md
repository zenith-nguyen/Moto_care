# Quy trình cộng tác

## Mô hình nhánh

| Nhánh | Người dùng | Mục đích |
| --- | --- | --- |
| `main` | Chủ repository | Mã đã duyệt, ổn định và sẵn sàng phát hành. |
| `cam-thu` | Cẩm Thư | Tích hợp các PR công việc của Cẩm Thư trước khi đưa vào `main`. |
| `thanh-vy` | Thanh Vy | Tích hợp các PR công việc của Thanh Vy trước khi đưa vào `main`. |
| `feat/<owner>/<mo-ta>` | Từng người thực hiện | Một chức năng cụ thể. |
| `fix/<owner>/<mo-ta>` | Từng người thực hiện | Một lỗi cụ thể. |
| `docs/<owner>/<mo-ta>` | Từng người thực hiện | Tài liệu hoặc cấu hình không đổi hành vi ứng dụng. |
| `chore/<owner>/<mo-ta>` | Từng người thực hiện | Bảo trì nhỏ, không thuộc các nhóm trên. |

`<owner>` là `cam-thu` hoặc `thanh-vy`; `<mo-ta>` dùng chữ thường, số và dấu gạch ngang. Ví dụ: `feat/cam-thu/booking-form`.

## Luồng làm việc

1. Đồng bộ nhánh tích hợp của mình: `git switch cam-thu` (hoặc `thanh-vy`) rồi `git pull origin cam-thu`.
2. Tạo nhánh công việc từ nhánh đó: `git switch -c feat/cam-thu/booking-form`.
3. Làm một phạm vi công việc, commit theo Conventional Commits, rồi push nhánh công việc.
4. Mở PR vào `cam-thu` hoặc `thanh-vy` tương ứng. Không mở PR chức năng thẳng vào `main`.
5. Chỉ merge khi các kiểm tra GitHub Actions xanh và đã có review bắt buộc.
6. Khi một nhóm thay đổi đã ổn định, mở PR từ `cam-thu` hoặc `thanh-vy` vào `main`. Chủ repository duyệt và merge.

Ví dụ cho Cẩm Thư:

```bash
git switch cam-thu
git pull origin cam-thu
git switch -c feat/cam-thu/booking-form
git add lib test
git commit -m "feat: add booking form"
git push -u origin feat/cam-thu/booking-form
```

Sau đó tạo PR với base branch là `cam-thu`. Xóa nhánh công việc sau khi PR đã được merge.

## Commit và PR

- Mỗi commit chỉ phục vụ một mục đích rõ ràng, tiêu đề ở thì mệnh lệnh và không quá 72 ký tự.
- Dùng một trong các tiền tố: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.
- PR phải điền đủ mẫu, không chứa thay đổi ngoài phạm vi và không để lại tệp build, secret hoặc log.
- Không tự merge PR của chính mình khi branch protection yêu cầu review.

## Trách nhiệm của chủ repository

Chủ repository thêm Cẩm Thư và Thanh Vy với quyền **Write**. GitHub Rules/Branch protection là nơi thực thi các quy tắc, không phải chỉ tài liệu. Cấu hình hiện hành được ghi ở [docs/WORKFLOW.md](docs/WORKFLOW.md).
