# wow-addon

Personal lightweight WoW addon

## Install

For a fresh installation, clone directly into AddOns

```sh
git clone git@github.com:jjjacobsen/wow-addon.git "/Applications/World of Warcraft/_forever_/Interface/AddOns/wow-addon"
```

Keep the folder named `wow-addon` so it matches `wow-addon.toc`
Restart WoW, then enable `wow-addon` in the AddOns menu

## Settings

Use `/jj` to open the feature settings. Except for Tank mode, checkbox changes are saved between sessions and take effect after a UI reload
Reload is enabled only when these saved selections differ from the settings applied at startup. Click Reload to apply them
All reload-based features start enabled. Turn off Hide buff collapse arrow to restore the native collapse button without buff consolidation
Close the window with Close, its top-right close button, or Escape. Pending selections remain when you reopen it

## Tank nameplates

Use the Tank mode checkbox in `/jj` or `/jj tank` to toggle tank mode immediately. The checkbox stays in sync with the command and does not enable Reload
Enemy nameplate health bars turn blue while you have aggro, including insecure tanking
When you lose aggro or turn tank mode off, the bars use native colors. Tank mode starts off after login or `/reload` and is not saved

## Auction house prices

Enable Auction house prices in `/jj` and reload to use `/jj scan` and `/jj clear`
Open an auction house in your faction's capital, then use `/jj scan`. Keep it open until the scan completes
Supported capitals are Stormwind, Ironforge, Darnassus, Orgrimmar, Thunder Bluff, and Undercity. Neutral auction houses and all other locations are not supported
Scans use the full auction list, with a local account-wide 15-minute cooldown. The server can also throttle scans, including scans from other addons. A timeout or cancelled scan keeps the previous prices

Item tooltips show the latest scan's lowest buyout per unit and the median of each day's latest observed minimum over 14 UTC days, including today. Days without an observation are excluded. Repeated scans replace that day's price, not add another sample
Items absent from the latest scan have no current lowest price but keep their recent history. Missing prices show Unavailable, not zero. Displayed prices round up to whole copper
Suffixes and bonus/modifier data remain separate. A complete item link is required, with no fallback to item ID alone
Prices are account-wide in `JJAuctionPrices`, separate from `JJSettings`, and grouped by region, independent PvP/RP/Hardcore rules, and faction, not realm
`/jj clear` asks for confirmation, then clears only the current market's prices and history and cancels its active scan. It keeps settings, other markets, and the scan cooldown

## Add tweaks

Add each feature as a separate Lua file and list its path after `Core.lua` in `wow-addon.toc`
Get the addon namespace with `local _, addon = ...`, then call `addon.RegisterFeature("uniqueKey", "Checkbox label", function(enabled) ... end)`
The callback runs at startup after saved settings load, not when its checkbox changes. Reload the UI to apply changes
New features start enabled, and the callback must support both states
Restart WoW after adding files or changing the TOC
Use `/reload` after edits to Lua files already listed in the TOC
