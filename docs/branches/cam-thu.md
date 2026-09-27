# Cam Thu branch guide

Cam Thu's integration branch is `cam-thu`. Every Cam Thu task starts from this branch and returns to it through a pull request.

```bash
git switch cam-thu
git pull origin cam-thu
git switch -c feat/cam-thu/<description>
```

- Use only `cam-thu` task-branch names: `feat/cam-thu/*`, `fix/cam-thu/*`, `docs/cam-thu/*`, `refactor/cam-thu/*`, `test/cam-thu/*`, or `chore/cam-thu/*`.
- Set the pull request base branch to `cam-thu`.
- Before using an AI, read [`AI_GUIDE.md`](../AI_GUIDE.md) and [`WORKFLOW.md`](../WORKFLOW.md). Complete `.github/PULL_REQUEST_TEMPLATE.md`.
- Do not delete a task branch automatically after merging. Delete it manually only when Cam Thu and the repository owner agree that the task is complete.
