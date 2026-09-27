# Thanh Vy branch guide

Thanh Vy's integration branch is `thanh-vy`. Every Thanh Vy task starts from this branch and returns to it through a pull request.

```bash
git switch thanh-vy
git pull origin thanh-vy
git switch -c feat/thanh-vy/<description>
```

- Use only `thanh-vy` task-branch names: `feat/thanh-vy/*`, `fix/thanh-vy/*`, `docs/thanh-vy/*`, `refactor/thanh-vy/*`, `test/thanh-vy/*`, or `chore/thanh-vy/*`.
- Set the pull request base branch to `thanh-vy`.
- Before using an AI, read [`AI_GUIDE.md`](../AI_GUIDE.md) and [`WORKFLOW.md`](../WORKFLOW.md). Complete `.github/PULL_REQUEST_TEMPLATE.md`.
- Do not delete a task branch automatically after merging. Delete it manually only when Thanh Vy and the repository owner agree that the task is complete.
