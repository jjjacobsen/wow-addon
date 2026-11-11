# Addon guidance

- Check APIs and restrictions against this client, not assumptions from Retail, Classic Era, or TBC
- Do not add tests, packages, or environment files unless asked
- This is a public repo so do not put any sensitive information in here
- Keep the folder and TOC names matched as `wow-addon` and `wow-addon.toc`
- WoW or its updater changes executable bits in this folder. Keep repository-local `core.fileMode=false` (`git config --local core.fileMode false`) so Git ignores permission-only changes. Do not normalize file permissions or make executable-bit-only commits
- The idea is that I will have several individual "features". Make a separate thing for each
    - For example: one will be displaying a gryphon on my character portrait. Another for hiding an arrow in the UI, etc
    - I want to be able to toggle each of these on or off
