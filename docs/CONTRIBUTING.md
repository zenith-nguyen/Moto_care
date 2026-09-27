# Contribution guide

## Branch model

| Branch | Owner | Purpose |
| --- | --- | --- |
| `main` | Repository owner | Reviewed, stable code and the only release source. |
| `cam-thu` | Cam Thu | Integrates Cam Thu's reviewed task pull requests before they reach `main`. |
| `thanh-vy` | Thanh Vy | Integrates Thanh Vy's reviewed task pull requests before they reach `main`. |
| `feat/<owner>/<description>` | Contributor | One product feature. |
| `fix/<owner>/<description>` | Contributor | One bug fix. |
| `docs/<owner>/<description>` | Contributor | Documentation or configuration that does not change app behavior. |
| `chore/<owner>/<description>` | Contributor | Small maintenance work. |

`<owner>` is `cam-thu` or `thanh-vy`. `<description>` uses lowercase letters, numbers, and hyphens. Example: `feat/cam-thu/booking-form`.

The integration branches are destinations for pull requests. A task branch such as `feat/cam-thu/booking-form` is where a contributor writes the code. A branch cannot open a pull request into itself, so both are required.

## Work flow

1. Update the personal integration branch: `git switch cam-thu` and `git pull origin cam-thu`.
2. Create a task branch from it: `git switch -c feat/cam-thu/booking-form`.
3. Complete one focused task, make Conventional Commits, and push the task branch.
4. Open a pull request into `cam-thu` or `thanh-vy`. Do not open a feature pull request directly into `main`.
5. Merge only after GitHub Actions pass and required reviews are complete.
6. When a group of changes is stable, open a pull request from `cam-thu` or `thanh-vy` into `main`. The repository owner reviews and merges it.

Example for Cam Thu:

```bash
git switch cam-thu
git pull origin cam-thu
git switch -c feat/cam-thu/booking-form
git add lib test
git commit -m "feat: add booking form"
git push -u origin feat/cam-thu/booking-form
```

Open the pull request with `cam-thu` as the base branch. Keep the task branch after merging until the team agrees that it is no longer useful.

## Commits and pull requests

- Keep each commit focused. Use an imperative subject line of no more than 72 characters.
- Use `feat`, `fix`, `docs`, `refactor`, `test`, or `chore` as the commit type.
- Complete the pull request template. Do not include unrelated changes, build output, secrets, or logs.
- Do not merge your own pull request when branch protection requires review.
