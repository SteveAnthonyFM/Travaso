# Security

Travaso has no network code, accounts or stored secrets; it reads audio files you choose and writes converted
copies. The main risk is a malformed audio file hitting a bug in the bundled FFmpeg, so keep Travaso up to date.

## Reporting a problem

Please use GitHub's private reporting: **Security ▸ Report a vulnerability** on the repository
(https://github.com/SteveAnthonyFM/Travaso/security/advisories/new). Don't post details in a public issue.

## What to know

- The app is not sandboxed and is signed ad hoc (not notarized); see `docs/DEVELOPER_GUIDE.md` for why.
- FFmpeg and its libraries are built from official sources against pinned SHA-256 checksums
  (`Scripts/build-ffmpeg.sh`, `docs/FFMPEG.md`).
- Release DMGs are built by GitHub Actions from a version tag and published manually after review.
