import { execFileSync } from "node:child_process";
import { readFileSync, statSync } from "node:fs";

const candidateFiles = execFileSync(
  "git",
  ["ls-files", "--cached", "--others", "--exclude-standard", "-z"],
  { encoding: "utf8" },
)
  .split("\0")
  .filter(Boolean);

const forbiddenPaths = [
  {
    rule: "environment file",
    matches: (path) =>
      /(^|\/)\.env(?:\.|$)/i.test(path) &&
      path !== ".env.example" &&
      !path.endsWith("/.env.example"),
  },
  {
    rule: "private key or keystore",
    matches: (path) => /\.(?:pem|key|p12|pfx|jks|keystore)$/i.test(path),
  },
  {
    rule: "runtime upload",
    matches: (path) => /(^|\/)storage\//i.test(path),
  },
  {
    rule: "database or upload backup",
    matches: (path) => /(^|\/)backups\//i.test(path),
  },
];

const secretSignatures = [
  { rule: "private key block", pattern: /-----BEGIN [A-Z ]*PRIVATE KEY-----/ },
  { rule: "GitHub token", pattern: /\bgh(?:p|o|u|s|r)_[A-Za-z0-9]{30,}\b/ },
  { rule: "Google API key", pattern: /\bAIza[0-9A-Za-z_-]{35}\b/ },
  { rule: "AWS access key", pattern: /\b(?:AKIA|ASIA)[A-Z0-9]{16}\b/ },
  { rule: "Slack token", pattern: /\bxox[baprs]-[A-Za-z0-9-]{20,}\b/ },
];

const findings = [];
for (const path of candidateFiles) {
  for (const check of forbiddenPaths) {
    if (check.matches(path)) findings.push(`${path}: ${check.rule}`);
  }

  let size;
  try {
    size = statSync(path).size;
  } catch {
    continue;
  }
  if (size > 1_000_000) continue;
  const content = readFileSync(path);
  if (content.includes(0)) continue;
  const text = content.toString("utf8");
  for (const signature of secretSignatures) {
    if (signature.pattern.test(text))
      findings.push(`${path}: ${signature.rule}`);
  }
}

if (findings.length > 0) {
  console.error(
    "Sensitive-file check failed. Values are intentionally not printed:",
  );
  for (const finding of findings) console.error(`- ${finding}`);
  process.exitCode = 1;
} else {
  console.log(
    `Sensitive-file check passed for ${candidateFiles.length} tracked or untracked candidate files.`,
  );
}
