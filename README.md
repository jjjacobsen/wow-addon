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
Value is the unit vendor price times the actual stack count, not auction value. Missing data or locked items pause selection. Bank contents and equipped items are not scanned. All carried bags, including profession bags, are scanned. Quest items and quest starters identified by the client are excluded
Next skips that item ID until you close the window. Keep excludes that item ID for this character across sessions. Use Keep list and Remove to reverse a Keep choice. There are no built-in consumable, tool, or equipment exclusions
Destroy… checks the exact stack again, then opens Blizzard's unchanged delete confirmation. Valuable items still require typed DELETE. No item is deleted without native confirmation. The cursor must be empty, and the helper closes in combat. Normal bag dragging is unchanged
Free Slot starts enabled. Toggle it in `/jj`, then click Reload. Close with Close, the top-right close button, or Escape

## Auction house prices

Enable Auction house prices in `/jj` and reload to use Scan, `/jj scan`, and `/jj clear`
Open an auction house in your faction's capital, then click Scan between the search box and Filter, or use `/jj scan`. Keep it open until the scan completes. Scan is disabled while a scan runs
Supported capitals are Stormwind, Ironforge, Darnassus, Orgrimmar, Thunder Bluff, and Undercity. Neutral auction houses and all other locations are not supported
Scans use the full auction list, with a local account-wide 15-minute cooldown. The server's scan cooldown cannot be bypassed, and scans from other addons can cause throttling
Chat reports elapsed time every 10 seconds, first while waiting for the server list, then with processed auction counts and checked rows waiting for item data. Scans time out after 300 seconds. A missing server response reports possible throttling, while incomplete data reports the remaining rows. A timeout or cancelled scan keeps the previous prices

Soulbound items omit AH rows when their binding is available from the item or tooltip
Item tooltips show the latest scan's lowest buyout per unit and the median of each day's latest observed minimum over 14 UTC days, including today. Days without an observation are excluded. Repeated scans replace that day's price, not add another sample
Items absent from the latest scan have no current lowest price but keep their recent history. Missing prices show Unavailable, not zero. Displayed prices round up to whole copper
Suffixes and real bonus/modifier data remain separate. Item source context and the sole native preview bonus 3524 are ignored so previews and auction links can match. Existing scans remain usable. A complete item link is required, with no fallback to item ID alone
Owned stacks also show AH totals for that stack. Native recipe outputs show totals for a fixed per-craft quantity, not the number owned. Variable output ranges have no exact total
Prices are account-wide in `JJAuctionPrices`, separate from `JJSettings`, and grouped by region, independent PvP/RP/Hardcore rules, and faction, not realm
`/jj clear` asks for confirmation, then clears only the current market's prices and history and cancels its active scan. It keeps settings, other markets, and the scan cooldown

## Leatherworking gear

Run `/reload` after installing. Use `/jj lw` to open the browser
The last tab is saved per character, with Character selected on first use. Character shows your native character model and read-only equipped armor icons on the left. Hover for native equipped-item tooltips
Choose a stat and max equip level to see one top result for each of the nine supported slots on the right. Each result shows its item link and selected-stat difference from equipped gear. Results use the highest stat value per slot, which gives the largest difference when equipped data is available. Equal values sort by item ID, then recipe ID
Character ignores the Table slot filter and keeps it unchanged. Table keeps the full table, slot selector, sorting, and native modified-click link actions. Both tabs share stat, max equip level, Upgrades only, and the catalog
Open your own Leatherworking, wait for recipes to load, then use `/jj lwscan` to save learned and unlearned native recipes. Run it again to update recipes or retry missing items. Opening, closing, and recipe-data events do not start scans. The command requires your own native Leatherworking view with recipes ready and does not start another scan while one is active. Later, browse anywhere without the profession window open
Max equip level follows your character level until you edit it. Raise it to plan higher-level equipment. Auto restores level tracking. Filters are saved per character
Table rows sort by the selected stat, highest first, and show links, armor type, equip level, stat value, equipped-slot difference, and learned status. Hover results in either tab for native tooltips and, outside combat, equipment comparisons
Upgrades only means a positive difference in the selected stat, not an overall upgrade. Stats are not weighted. Spell damage includes generic spell power plus damage-only bonuses. Spell healing includes generic spell power plus healing-only bonuses. School damage stays separate. Saved Spell power selections become Spell damage. Armor includes native bonus armor. Both tabs always filter by your currently known native armor proficiencies. Raising max equip level does not grant unlearned proficiencies. Cloaks remain eligible. Learning a proficiency updates the open browser
Character shows the top result even with a zero or negative difference unless Upgrades only is on. No matching item means no equipment fits the filters. No confirmed upgrade means Upgrades only excluded the slot's results
Missing stats or equipped data show `-`, not zero. An empty equipped slot counts as zero in both views. Unknown differences never qualify for Upgrades only. Unavailable items and unresolved outputs remain counted even when their slot is unknown
Keep your own Leatherworking open until chat reports completion, up to 60 seconds. Chat reports scan start, completion, cancellation, and timeout. Saved data stays available in the browser during a scan. Only a complete scan replaces it. Closing Leatherworking or changing its data source cancels the scan, and cancellation or timeout keeps the previous catalog and learned data. Failed item loads do not block completion. Their recipes and ingredients are saved with unavailable items counted. Gear views use native default outputs, without quality or reagent variants or profession-rank filtering
Catalog data is account-wide in `JJLWCatalog`, so characters without Leatherworking can browse after a leatherworker on the same account saves the catalog. Another account needs its own catalog. Options and learned status are per character in `JJLWCharacter`. Learned status is Unknown until that character scans their own Leatherworking. Learning a known Leatherworking recipe updates only that recipe's learned status, without a scan
Gold making is the third tab in the same fixed-size window. It includes all native Leatherworking item outputs, not just gear, without the Character/Table filters. Materials defaults to Buy finished inputs, Prices to Latest lowest, and Include unlearned and Exclude gear to off. These choices are saved per character. Exclude gear hides wearable outputs in any native equipment slot, but keeps bags, quivers, armor kits, leather, hides, and other nongear. Rows with missing item data, output quantity, cash materials, sale value, or margin are always hidden
Gold's LW skill column shows a verified pattern or trainer learning requirement, including for learned recipes, or `-` for an empty requirement. Open your own Leatherworking and use `/jj lwscan` to collect pattern requirements. Pattern items load only during that manual scan and stay separate from output and ingredient availability counts. The shipped recipe-to-pattern map uses exact Forever 1.60.1.70888 data, with no runtime web access. After saving a catalog, visit Leatherworking trainers to record native skill requirements for listed services whose native tooltip spell ID exactly matches a catalog recipe. Trainer filters stay unchanged, so only listed services are observed. Requirements are account-wide and survive later manual scans. Missing or conflicting requirements stay Unknown. Trainer capture runs only on opening or list updates, without timers, scans, or Gold recalculation. Reopen Gold to use new observations
Max LW skill follows your current native Leatherworking rank until edited. Auto restores tracking. Without an available current skill, Auto leaves the field blank and does not apply a skill cap. Unlearned recipes with a known requirement above the cap are hidden. Learned recipes and unknown requirements remain eligible under the other Gold filters. This is not a check of reputation, specialization, or access to a recipe's source. Character and Table are unchanged
Rows show minimum output quantity per craft, cash material cost, sale value, and margin before AH fees. Margins sort greatest first, including negative values. Prices use the existing current-market scan and exact item-link variant keys, with a choice of latest lowest or 14-day median. The footer shows scan age at the last calculation. Gold recalculates when you open the browser on this tab, select it, change a Gold filter, or confirm clearing AH prices. There is no periodic recalculation. Cached prices remain usable when Auction house prices is off, but new scans require that feature
Buy finished inputs prices required ingredients directly from the AH, including cured hides and vendor supplies. Buy raw materials expands native Leatherworking intermediaries and buys every raw input, including leather, hides, and supplies such as Silken Thread. Its forgone material sale value is zero because all inputs are purchased. Farm leather and hides gives zero cash cost only to Ruined Leather Scraps, Light/Medium/Heavy/Thick/Rugged Leather, Devilsaur Leather, and Light/Medium/Heavy/Thick/Rugged Hide. Native item data must also identify these as leather trade goods. Other leathers and scales are not assumed free
Raw and Farm modes expand native Leatherworking intermediaries, including cured hides. Refined Deeprock Salt also expands through the Salt Shaker item effect: one bought Deeprock Salt makes one Refined Deeprock Salt. This requires a Salt Shaker and Leatherworking 250, with a shared 71-hour cooldown per use. Device ownership and cooldown availability are not checked, and their value is not included in costs. Buy finished inputs still buys Refined Deeprock Salt directly. Raw and Farm modes round intermediary production up to full crafts and give leftovers no sale credit. Neither mode chooses the cheapest route. Multiple producers, cycles, unsupported required choices, or missing ingredient data make the calculation unavailable rather than choosing a recipe or price. Optional reagents are ignored. Open your own Leatherworking and use `/jj lwscan` after updating to collect ingredients. Learned-only results require this character to know the output recipe and every expanded intermediary. Include unlearned shows unlearned and unknown requirements in row tooltips
After collecting ingredients, visit vendors to record this character's observed coin-only buy prices for catalog ingredients. Raw and Farm modes use those per-unit quotes, including the observed discount, for purchased inputs. Without a quote they use an explicitly marked AH estimate. Buy finished inputs always uses AH prices. Vendor sell values and extended-cost offers are not used. Quotes are observations, not stock or future-price guarantees. Recording a quote does not refresh Gold. The next calculation uses it
Hover a row for ingredient quantities, costs, and recipe requirements. Nested inputs appear beneath their intermediaries. Farm mode shows cash costs, not the sale value of farmed materials. All sale values and comparisons are gross estimates before AH fees because the exact Forever cut is not verified. Deposits and relists are excluded. Unknown prices never count as zero. Confirmed soulbound, account-bound, and other unsupported output bindings are hidden. Unknown output binding also hides the row. There are no sales predictions, automatic crafts, purchases, or listings
Leatherworking gear starts enabled and controls all three tabs. Toggle it in `/jj`, then click Reload. Close the browser with its top-right close button or Escape

## Add tweaks

Add each feature as a separate Lua file and list its path after `Core.lua` in `wow-addon.toc`
Get the addon namespace with `local _, addon = ...`, then call `addon.RegisterFeature("uniqueKey", "Checkbox label", function(enabled) ... end)`
The callback runs at startup after saved settings load, not when its checkbox changes. Reload the UI to apply changes
New features start enabled, and the callback must support both states
Restart WoW after adding files or changing the TOC
Use `/reload` after edits to Lua files already listed in the TOC
