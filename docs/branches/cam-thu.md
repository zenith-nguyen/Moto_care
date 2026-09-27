# Hướng dẫn nhánh Cẩm Thư

Nhánh tích hợp là `cam-thu`. Mọi task của Cẩm Thư bắt đầu từ nhánh này và quay về nhánh này bằng PR.

```bash
git switch cam-thu
git pull origin cam-thu
git switch -c feat/cam-thu/<mo-ta>
```

- Chỉ dùng prefix có owner `cam-thu`: `feat/cam-thu/*`, `fix/cam-thu/*`, `docs/cam-thu/*`, `refactor/cam-thu/*`, `test/cam-thu/*`, hoặc `chore/cam-thu/*`.
- Base branch của PR là `cam-thu`.
- Đọc `AGENTS.md` trước khi dùng AI và điền đủ `.github/PULL_REQUEST_TEMPLATE.md`.
- Sau khi PR đã merge, xóa nhánh công việc và đồng bộ lại `cam-thu` trước task tiếp theo.
