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

Use `/jj` to open the feature settings. Checkbox changes are saved between sessions. Except for Tank mode and Enable Damage Meter, they take effect after a UI reload
Reload is enabled only when these saved selections differ from the settings applied at startup. Click Reload to apply them
All reload-based features start enabled. Turn off Hide buff collapse arrow to restore the native collapse button without buff consolidation
Close the window with Close, its top-right close button, or Escape. Pending selections remain when you reopen it

Mute spell failure sounds mutes the five spell fizzle files for all failures, separate from Filter common errors. It does not mute normal spell sounds or change the error speech setting
Turn it off and reload to restore those sounds

## Trade chat filter

Filter Trade chat starts enabled. Toggle it in `/jj`, then click Reload
Filters native Trade, Trade (Services), and yells, regardless of channel number or language. Other channels, including General and Trade (Local), are unchanged
Messages are hidden for any of these rules, after removing link data, colors, textures, and atlases while keeping visible link text

- All alphabetic characters are uppercase, with at least one letter. Numbers and punctuation alone do not match
- Whole words `PST`, `recruiting`, `LF`, `LFG`, `WTS`, `LFW`, `WTB`, `summon`, `summons`, or `summoning`, case-insensitive. Also matches `LFM` and `LF<number>M`, such as `LF1M`, but not `self`
- The phrase `looking for`, case-insensitive
- The word `guild` or a native guild finder/community link, together with `recruitment`, `recruits`, or `seeking`, case-insensitive. A guild mention or link alone does not match

These rules are fixed. Native chat privacy restrictions can stop filtering while chat messages are secret

## Tank nameplates

Use the Tank mode checkbox in `/jj` or `/jj tank` to toggle tank mode immediately. The checkbox stays in sync with the command and does not enable Reload
Enemy nameplate health bars turn blue while you have aggro, including insecure tanking
When you lose aggro or turn tank mode off, the bars use native colors. Tank mode is saved per character and restored after login or `/reload`. It starts off for characters without a saved setting

## Damage meter

Use Enable Damage Meter in `/jj` or `/jj dmg` to toggle the built-in meter immediately, without Reload
This changes the native Advanced Options setting, not the meter's frames. Auto Reset Damage Meter is unchanged
The choice is saved per character and restored at login or `/reload`. Characters without a saved choice keep their current native setting
Changes in Advanced Options also update the saved choice and the open `/jj` checkbox
Native availability and Edit Mode visibility rules still apply. A rejected setting change reports an error and leaves the checkbox at the native value

## Flight durations

Enable Flight durations in `/jj` and reload. Hover a reachable destination to see Duration below the fare, in `m:ss`, or Unknown until you complete that exact route
Only the last completed flight is saved. The native early-landing request, death, loading screens, and logout discard the recording. Flights interrupted by `/reload` or login during a flight are not resumed
Times are account-wide in `JJFlightDurations`, separate from settings, and grouped by region, faction, and the full directed path of flight node IDs. Routes with unresolved nodes stay Unknown. No countdown window is shown

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
