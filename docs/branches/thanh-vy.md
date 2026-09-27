# Hướng dẫn nhánh Thanh Vy

Nhánh tích hợp là `thanh-vy`. Mọi task của Thanh Vy bắt đầu từ nhánh này và quay về nhánh này bằng PR.

```bash
git switch thanh-vy
git pull origin thanh-vy
git switch -c feat/thanh-vy/<mo-ta>
```

- Chỉ dùng prefix có owner `thanh-vy`: `feat/thanh-vy/*`, `fix/thanh-vy/*`, `docs/thanh-vy/*`, `refactor/thanh-vy/*`, `test/thanh-vy/*`, hoặc `chore/thanh-vy/*`.
- Base branch của PR là `thanh-vy`.
- Đọc `AGENTS.md` trước khi dùng AI và điền đủ `.github/PULL_REQUEST_TEMPLATE.md`.
- Sau khi PR đã merge, xóa nhánh công việc và đồng bộ lại `thanh-vy` trước task tiếp theo.
