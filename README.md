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
Filters native General, Trade, Trade (Services), and yells, regardless of channel number or language. Other channels, including Trade (Local), are unchanged
Messages are hidden for any of these rules, after removing link data, colors, textures, and atlases while keeping visible link text

- All alphabetic characters are uppercase, with at least one letter. Numbers and punctuation alone do not match
- Whole words `PST`, `recruiting`, `LF`, `LFG`, `WTS`, `LFW`, `WTB`, `WTT`, `lockbox`, `selling`, `L4W`, `mats`, `AH`, `summon`, `summons`, or `summoning`, case-insensitive. Also matches `LFM` and `LF<number>M`, such as `LF1M`, but not `self`
- The phrase `looking for`, `twitch.tv`, or words starting with `enchant`, case-insensitive
- Text enclosed in angle brackets, such as `<Guild Name>`
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

## Waypoints

Use `/way 58.9 53.6` or `/way 58.9, 53.6` to set the native waypoint in your current zone, not the map you are viewing. Both coordinates must be from 0 to 100. Using `/way` without coordinates shows usage instructions
Waypoints starts enabled. Toggle it in `/jj`, then click Reload. No custom arrow, tracking, or map window is added

## Saved Bank

Click Bank in the combined backpack header or use `/jj bank` to view this character's saved bank anywhere. Visit a bank first to save its contents
All purchased character bank bags share one read-only grid, in container and slot order, including empty slots. Scroll for more slots and hover items for tooltips. Items cannot be moved, used, or sorted here
The character and last update time appear above the grid. Contents update only while the real bank is open and are saved per character in `JJSavedBank`. Account banks and other characters are not included
Saved Bank starts enabled. Toggle it in `/jj`, then click Reload. Close its window with the top-right close button or Escape

## Free Slot

Click Free Slot beside Bank in the combined backpack header or use `/jj free`. The window shows the carried stack with the lowest total vendor value, including zero-value items, and outlines its native bag slot
Value is the unit vendor price times the actual stack count, not auction value. Missing data or locked items pause selection. Bank contents and equipped items are not scanned, but all carried item categories and profession bags are included
Next skips that item ID until you close the window. Keep excludes that item ID for this character across sessions. Use Keep list and Remove to reverse a Keep choice. There are no built-in quest, consumable, tool, or equipment exclusions
Destroy… checks the exact stack again, then opens Blizzard's unchanged delete confirmation. Valuable items still require typed DELETE. No item is deleted without native confirmation. The cursor must be empty, and the helper closes in combat. Normal bag dragging is unchanged
Free Slot starts enabled. Toggle it in `/jj`, then click Reload. Close with Close, the top-right close button, or Escape

## Auction house prices

Enable Auction house prices in `/jj` and reload to use `/jj scan` and `/jj clear`
Open an auction house in your faction's capital, then use `/jj scan`. Keep it open until the scan completes
Supported capitals are Stormwind, Ironforge, Darnassus, Orgrimmar, Thunder Bluff, and Undercity. Neutral auction houses and all other locations are not supported
Scans use the full auction list, with a local account-wide 15-minute cooldown. The server can also throttle scans, including scans from other addons. A timeout or cancelled scan keeps the previous prices

Soulbound items omit AH rows when their binding is available from the item or tooltip
Item tooltips show the latest scan's lowest buyout per unit and the median of each day's latest observed minimum over 14 UTC days, including today. Days without an observation are excluded. Repeated scans replace that day's price, not add another sample
Items absent from the latest scan have no current lowest price but keep their recent history. Missing prices show Unavailable, not zero. Displayed prices round up to whole copper
Suffixes and bonus/modifier data remain separate. A complete item link is required, with no fallback to item ID alone
Prices are account-wide in `JJAuctionPrices`, separate from `JJSettings`, and grouped by region, independent PvP/RP/Hardcore rules, and faction, not realm
`/jj clear` asks for confirmation, then clears only the current market's prices and history and cancels its active scan. It keeps settings, other markets, and the scan cooldown

## Leatherworking gear

Run `/reload` after installing. Use `/jj lw` to open the gear browser
Character opens first, with your native character model and supported equipped armor slots on the left, filters and results on the right. Click a gear slot to filter recipes, or click it again for all slots. Hover for the native equipped-item tooltip. These icons cannot equip, use, or move items
Table is the second tab and keeps the full table without the character panel. Both tabs share the same filters and catalog
Open your own Leatherworking to save its learned and unlearned native recipes automatically. Reopen it to update recipes or retry missing items. Linked, guild, and NPC profession views do not update the catalog. Later, browse anywhere without the profession window open
Choose a stat and slot. Max equip level follows your character level until you edit it. Auto restores that behavior. These choices and Upgrades only are saved per character
Rows sort by the selected stat, highest first, and show links, armor type, equip level, stat value, equipped-slot difference, and learned status. Hover for native tooltips and, outside combat, equipment comparisons. Modified clicks use native link actions
Upgrades only means a positive difference in the selected stat, not an overall upgrade. Stats are not weighted or combined. Spell power, damage, healing, and school damage stay separate. Armor includes native bonus armor. Leather and mail both appear, without class usability filtering
Missing stats or equipped data show `-`, not zero. An empty equipped slot counts as zero. Unavailable items and unresolved outputs remain counted even when their slot is unknown
Allow up to 60 seconds for item data to load. Only native default outputs are used, without quality or reagent variants, profession-rank filtering, inferred crafting requirements, or external data
Catalog data is account-wide in `JJLWCatalog`, so characters without Leatherworking can browse after a leatherworker on the same account saves the catalog. Another account needs its own catalog. Options and learned status are per character in `JJLWCharacter`. Learned status is Unknown until that character opens their own Leatherworking
Leatherworking gear starts enabled. Toggle it in `/jj`, then click Reload. Close the browser with its top-right close button or Escape

## Add tweaks

Add each feature as a separate Lua file and list its path after `Core.lua` in `wow-addon.toc`
Get the addon namespace with `local _, addon = ...`, then call `addon.RegisterFeature("uniqueKey", "Checkbox label", function(enabled) ... end)`
The callback runs at startup after saved settings load, not when its checkbox changes. Reload the UI to apply changes
New features start enabled, and the callback must support both states
Restart WoW after adding files or changing the TOC
Use `/reload` after edits to Lua files already listed in the TOC
