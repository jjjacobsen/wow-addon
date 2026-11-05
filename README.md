# wow-addon

Personal lightweight WoW addon

## Install

For a fresh installation, clone directly into AddOns

```sh
git clone git@github.com:jjjacobsen/wow-addon.git "/Applications/World of Warcraft/_forever_/Interface/AddOns/wow-addon"
```

Keep the folder named `wow-addon` so it matches `wow-addon.toc`
Restart WoW, then enable `wow-addon` in the AddOns menu

## Add tweaks

Add each feature as a separate Lua file and list its path in `wow-addon.toc`, one per line
Files load from top to bottom, so list any required file before the file that uses it
Restart WoW after adding files or changing the TOC
Use `/reload` after edits to Lua files already listed in the TOC
