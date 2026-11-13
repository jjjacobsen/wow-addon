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
Reload-based features start enabled except Maximum camera zoom, Five-second rule, and Filter Trade chat. Turn off Hide buff collapse arrow to restore the native collapse button without buff consolidation
Close the window with Close, its top-right close button, or Escape. Pending selections remain when you reopen it

Mute spell failure sounds mutes the five spell fizzle files for all failures, separate from Filter common errors. It does not mute normal spell sounds or change the error speech setting
Turn it off and reload to restore those sounds

## Maximum camera zoom

Maximum camera zoom starts off. Enable it in `/jj`, then click Reload to set the native Max Camera Distance slider maximum, `2.0` in Forever build 1.60.1.70888. Scroll out manually. It does not force the camera position or bypass native limits
Turn it off and reload to restore the value saved before enabling it

## Five-second rule

Five-second rule starts off. Enable it in `/jj`, then click Reload
A 6-pixel round gold dot beside your portrait shows for five seconds after a successful spell with a readable positive mana cost captured when the cast was sent. Another paid mana cast restarts it. Free casts, energy and rage abilities, failed casts, and form changes do not stop an active timer. A paid form change restarts it
This uses the client's cost snapshot, not measured mana loss or a guarantee of zero mana regeneration. Unavailable or secret costs are skipped. Enemy mana drains are not tracked

## Trade chat filter

Filter Trade chat starts off. Enable it in `/jj`, then click Reload
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

## Zone level ranges

Zone level ranges starts enabled. Toggle it in `/jj`, then click Reload
Shows the selected map's range at the right of the native breadcrumb bar, not your current zone. Hides when the bar has no room, or for cities, instances, continents and unknown maps
Static ranges cover all 41 zones listed in Forever 1.60.1.70888's [Group Finder questing suggestions](https://wago.tools/db2/GroupFinderActivity/csv?build=1.60.1.70888), not quest requirements or scaling. Feralas is `38-54`. Native `53-63` suggestions and Zephras Isle's `1-14` are kept unchanged. Deadwind Pass, Moonglade and Shen'dralas have no verified suggestion and stay hidden

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

Soulbound and bind-on-pickup items omit AH rows when their binding is available from the item or tooltip
Item tooltips show the latest scan's lowest buyout per unit and the median of daily medians over 14 UTC days, including today. Each successful scan adds its lowest buyout per unit to that UTC day's observations. Each sampled day has equal weight, and days without observations are excluded. Existing daily prices count as one observation each
Items absent from the latest scan have no current lowest price but keep their recent history. Missing prices show Unavailable, not zero. Displayed prices round up to whole copper
Suffixes and real bonus/modifier data remain separate. Item source context and the sole native preview bonus 3524 are ignored so previews and auction links can match. Existing scans remain usable. A complete item link is required, with no fallback to item ID alone
Owned stacks also show AH totals for that stack. Native recipe outputs show totals for a fixed per-craft quantity, not the number owned. Variable output ranges have no exact total
Prices are account-wide in `JJAuctionPrices`, separate from `JJSettings`, and grouped by region, independent PvP/RP/Hardcore rules, and faction, not realm
`/jj clear` asks for confirmation, then clears only the current market's prices and history and cancels its active scan. It keeps settings, other markets, and the scan cooldown

## Leatherworking gear

Right-click any Leatherworking, Cooking, First Aid, Engineering, or Tailoring minimap icon to open your own native profession window and scan when recipes are ready. This does not open the addon browser or refresh profit rows
The opening request stops after 10 seconds, on closing the native window, or when another icon requests a scan. Repeated clicks do not restart a pending or active scan

Restart WoW after installing the new files. Left-click the Leatherworking minimap icon or use `/jj lw` to toggle the browser
The icon starts at 9 o'clock. Left-drag to move it around the minimap. Its position is saved account-wide in `JJSettings.minimapButtons`. It appears only while Leatherworking gear is enabled
The last tab is saved per character, with Character selected on first use. Character shows your native character model and read-only equipped armor icons on the left. Hover for native equipped-item tooltips
Choose a stat and max equip level to see one top result for each of the nine supported slots on the right. Each result shows its item link and selected-stat difference from equipped gear. Results use the highest stat value per slot, which gives the largest difference when equipped data is available. Equal values sort by item ID, then recipe ID
Character ignores the Table slot filter and keeps it unchanged. Table keeps the full table, slot selector, sorting, and native modified-click link actions. Both tabs share stat, max equip level, Upgrades only, and the catalog
Open your own Leatherworking, wait for recipes to load, then use `/jj lwscan` to save learned and unlearned native recipes. Run it again to update recipes or retry missing items. Without a right-click request, opening, closing, and recipe-data events do not start scans. The command requires your own native Leatherworking view with recipes ready and does not start another scan while one is active. Later, browse anywhere without the profession window open
Max equip level follows your character level until you edit it. Raise it to plan higher-level equipment. Auto restores level tracking. Filters are saved per character
Table rows sort by the selected stat, highest first, and show links, armor type, equip level, stat value, equipped-slot difference, and learned status. Hover results in either tab for native tooltips and, outside combat, equipment comparisons
Upgrades only means a positive difference in the selected stat, not an overall upgrade. Stats are not weighted. Spell damage includes generic spell power plus damage-only bonuses. Spell healing includes generic spell power plus healing-only bonuses. School damage stays separate. Saved Spell power selections become Spell damage. Armor includes native bonus armor. Both tabs always filter by your currently known native armor proficiencies. Raising max equip level does not grant unlearned proficiencies. Cloaks remain eligible. Learning a proficiency updates the open browser
Character shows the top result even with a zero or negative difference unless Upgrades only is on. No matching item means no equipment fits the filters. No confirmed upgrade means Upgrades only excluded the slot's results
Missing stats or equipped data show `-`, not zero. An empty equipped slot counts as zero in both views. Unknown differences never qualify for Upgrades only. Unavailable items and unresolved outputs remain counted even when their slot is unknown
Keep your own Leatherworking open until chat reports completion, up to 60 seconds. Chat reports scan start, completion, cancellation, and timeout. Saved data stays available in the browser during a scan. Only a complete scan replaces it. Closing Leatherworking or changing its data source cancels the scan, and cancellation or timeout keeps the previous catalog and learned data. Failed item loads do not block completion. Their recipes and ingredients are saved with unavailable items counted. Gear views use native default outputs, without quality or reagent variants or profession-rank filtering
Catalog data is account-wide in `JJLWCatalog`, so characters without Leatherworking can browse after a leatherworker on the same account saves the catalog. Another account needs its own catalog. Options and learned status are per character in `JJLWCharacter`. Learned status is Unknown until that character scans their own Leatherworking. Learning a known Leatherworking recipe updates only that recipe's learned status, without a scan
Gold making is the third tab in the same fixed-size window. It includes all native Leatherworking item outputs, not just gear, without the Character/Table filters. Materials defaults to Buy finished inputs, Prices to Latest lowest, and Include unlearned and Exclude gear to off. These choices are saved per character. Exclude gear hides wearable outputs in any native equipment slot, but keeps bags, quivers, armor kits, leather, hides, and other nongear. Rows with missing item data, output quantity, cash materials, sale value, or margin are always hidden
All five profession profit views use static verified Forever learning requirements from `ProfessionSkillRequirements.lua`, including for learned recipes. Sources and the capture date are in that file. Coverage is partial: 546 Leatherworking, 129 Cooking, 31 First Aid, 202 Engineering, and 399 Tailoring recipe spells, 1,307 total. Sources are 1,121 Wowhead learning-item requirements with exact teaching spell links, 145 Forever Guide trainer and starter requirements, 19 archived native trainer observations copied into the static table, 20 user-confirmed requirements, and two explicit learning requirements from indexed Wowhead Forever spell and profession-guide pages. These totals count verified spell IDs, not all obtainable recipes. Saved catalogs can include outputs whose availability is unverified, so a missing rank does not prove that a recipe is available in Forever. Output use requirements and skill-up thresholds are not learning requirements. Conflicting values, including seven native/Wowhead disagreements, stay omitted. Unverified and unmapped requirements show `-`. No estimates, trainer capture, pattern-item loads, or runtime web requests. Old saved requirements are ignored. Use `/reload` to apply these ranks to existing catalogs, without another scan
Max LW skill follows your current native Leatherworking rank until edited. Auto restores tracking. Without an available current skill, Auto leaves the field blank and does not apply a skill cap. Unlearned recipes with a known requirement above the cap are hidden. Learned recipes and requirements that still show `-` remain eligible under the other Gold filters. This is not a check of reputation, specialization, or access to a recipe's source. Character and Table are unchanged
Rows show minimum output quantity per craft, cash material cost, sale value, and margin before AH fees. Margins sort greatest first, including negative values. Prices use the existing current-market scan and exact item-link variant keys, with a choice of latest lowest or 14-day median. The footer shows scan age at the last calculation. Gold recalculates when you open the browser on this tab, select it, change a Gold filter, or confirm clearing AH prices. There is no periodic recalculation. Cached prices remain usable when Auction house prices is off, but new scans require that feature
Buy finished inputs purchases direct recipe ingredients, including cured hides and vendor supplies. Buy raw materials expands native Leatherworking intermediaries and buys every raw input, including leather, hides, and supplies such as Silken Thread. Its forgone material sale value is zero because all inputs are purchased. Farm leather and hides gives zero cash cost only to Ruined Leather Scraps, Light/Medium/Heavy/Thick/Rugged Leather, Devilsaur Leather, and Light/Medium/Heavy/Thick/Rugged Hide. Native item data must also identify these as leather trade goods. Other leathers and scales are not assumed free
Raw and Farm modes expand native Leatherworking intermediaries, including cured hides. Refined Deeprock Salt also expands through the Salt Shaker item effect: one bought Deeprock Salt makes one Refined Deeprock Salt. This requires a Salt Shaker and Leatherworking 250, with a shared 71-hour cooldown per use. Device ownership and cooldown availability are not checked, and their value is not included in costs. Buy finished inputs still buys Refined Deeprock Salt directly. Raw and Farm modes round intermediary production up to full crafts and give leftovers no sale credit. Neither mode chooses the cheapest route. Multiple producers, cycles, unsupported required choices, or missing ingredient data make the calculation unavailable rather than choosing a recipe or price. Optional reagents are ignored. Open your own Leatherworking and use `/jj lwscan` after updating to collect ingredients. Learned-only results require this character to know the output recipe and every expanded intermediary. Include unlearned shows unlearned and unknown requirements in row tooltips
All five professions use the shared static base coin purchase prices in `VendorPrices.lua` for listed purchased ingredients, without reputation or talent discounts. Prices are per item, not merchant bundle totals or vendor sell values. Salt is 50 copper. Unlisted ingredients use the selected AH price. Without either price, the calculation is unavailable. Limited stock, faction access, and seasonal availability are not checked. These are cost estimates, not a claim that every ingredient is sold in Thunder Bluff. Token and extended-cost offers are excluded. Vendor visits no longer record prices. Old per-character vendor quotes are removed when the profession initializes

Base prices use Forever build 1.60.1.70888 ItemSparse `BuyPrice / VendorStackCount`, checked against coin-only merchant offers. Merchant data from [Efficient Games](https://efficient.games), licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), was selected and converted to unit prices. Source links and the full included price list are in `VendorPrices.lua`
Hover a row for ingredient quantities, costs, and recipe requirements. Nested inputs appear beneath their intermediaries. Farm mode shows cash costs, not the sale value of farmed materials. All sale values and comparisons are gross estimates before AH fees because the exact Forever cut is not verified. Deposits and relists are excluded. Unknown prices never count as zero. Confirmed soulbound, account-bound, and other unsupported output bindings are hidden. Unknown output binding also hides the row. There are no sales predictions, automatic crafts, purchases, or listings
Leatherworking gear starts enabled and controls all three tabs. Toggle it in `/jj`, then click Reload. Close the browser with its top-right close button or Escape

## Cooking profit

Restart WoW after installing the new files. Left-click the Cooking minimap icon or use `/jj cook` to toggle the separate Cooking window
The icon starts at 8 o'clock. Left-drag to move it around the minimap. Its position is saved account-wide in `JJSettings.minimapButtons`. It appears only while Cooking profit is enabled
Toggle Cooking profit in `/jj`, then click Reload. This feature does not need Leatherworking enabled
Open your own native Cooking, wait for recipes, then use `/jj cookscan`. Keep Cooking open until completion, up to 60 seconds. The manual scan saves learned and unlearned recipes, ingredients, and minimum yields. Closing Cooking, changing its source, or a timeout keeps the previous catalog. Failed item loads do not block completion. Browse anywhere after capture
Recipes are account-wide in `JJCookingCatalog`. Learned status and filters are per character in `JJCookingCharacter`. Learning requirements use the shared static verified Forever data. Missing ranks show `-`
Search, Prices, Include unlearned, and Max Cooking skill work like Leatherworking Gold. Auto uses your native base Cooking rank, without bonuses. Learned recipes and requirements that still show `-` remain eligible above the cap. Cooking has no Character/Table tabs, gear filter, or Farm mode
Buy finished inputs prices ingredients directly. Buy raw materials recursively expands native Cooking intermediaries, rounds up to whole crafts, and gives leftover output no sale credit. Both modes use shared static base vendor prices for listed purchased ingredients, then the selected AH price for other inputs. Neither mode selects the cheapest route. Learned-only rows require every expanded recipe to be learned
Rows and nested tooltips use the shared Gold columns and current-market AH cache. Minimum yield multiplies sale value. Missing prices, unsupported recipes, ambiguous producers, cycles, and outputs that cannot be auctioned hide affected rows. Margins are before AH fees. There are no extra AH scans or automatic crafts, purchases, or listings
Calculations run only on opening the window, changing a filter, or confirming AH price clearing. Recipe capture, learning, item events, and AH scan completion do not refresh profit rows. Reopen the window to use those inputs. Hidden windows do not calculate

## First Aid profit

Use `/reload` after installing, then left-click the First Aid minimap icon or use `/jj fa` to toggle its separate window. The icon starts at 7 o'clock. Left-drag to move it. Its position is saved in `JJSettings.minimapButtons.firstAid`
First Aid profit starts enabled. Toggle it in `/jj`, then click Reload. It does not need Cooking or Leatherworking enabled
Open your own native First Aid, wait for recipes, then use `/jj fascan`. Keep it open until completion, up to 60 seconds. Capture, cancellation, and item loading work like Cooking, including native ingredients and minimum yields for bandages, potions, kits, and camping recipes
Recipes are account-wide in `JJFirstAidCatalog`. Learned status and filters are per character in `JJFirstAidCharacter`. Learning requirements use the shared static verified Forever data, including First Aid child skill 2942. Missing ranks show `-`
Search, Materials, Prices, Include unlearned, and Max First Aid skill work like Cooking. Auto uses your native base rank without bonuses. Learned recipes and requirements that still show `-` remain eligible above the cap. No gear filter or Farm mode
Buy finished inputs prices ingredients directly. Buy raw materials expands native First Aid intermediaries, rounds up to whole crafts, and gives leftovers no sale credit. Both modes use shared static base vendor prices, then the selected AH price for unlisted inputs. Learned-only results require every expanded recipe to be learned. Missing prices or unsupported outputs hide rows. Margins are before AH fees
Calculations run only on opening the window, changing a filter, or confirming AH price clearing. Capture, learning, item events, and AH scan completion do not refresh profit rows. Reopen the window to use those inputs

## Engineering profit

Use `/reload` after installing, then left-click the Engineering minimap icon or use `/jj eng` to toggle its separate window. The icon starts at 150 degrees. Left-drag to move it. Its position is saved in `JJSettings.minimapButtons.engineering`
Engineering profit starts enabled. Toggle it in `/jj`, then click Reload. It does not need the other profession features enabled
Open your own native Engineering, wait for recipes, then use `/jj engscan`. Keep it open until completion, up to 60 seconds. Capture and cancellation work like Cooking. Native minimum yields set output quantities and sale values, including ammunition batches
Recipes are account-wide in `JJEngineeringCatalog`. Learned status and filters are per character in `JJEngineeringCharacter`. Learning requirements use the shared static verified Forever data. Missing ranks show `-`
Search, Materials, Prices, Include unlearned, and Max Engineering skill work like Cooking. Buy finished inputs and Latest lowest are the defaults. Include unlearned and Exclude gear start off. Exclude gear uses the shared Leatherworking Gold rules. Auto uses native base Engineering rank without bonuses. Learned recipes and requirements that still show `-` remain eligible above the cap. Specialization, recipe access, tools, and current crafting availability are not checked. Owned inventory does not filter results or reduce costs
Buy finished inputs prices ingredients directly. Buy raw materials expands only captured Engineering intermediaries, such as bolts, tubes, and casings. Bars are bought, not expanded through Mining smelting into ore. Production rounds up to whole crafts, with no leftover sale credit. Both modes use shared static base vendor prices first, then the selected AH price for unlisted inputs. Neither mode chooses the cheapest route. No Farm mode or Salt Shaker expansion. Learned-only results require every expanded recipe to be learned
Rows and nested tooltips use the shared Gold view. Missing prices, unsupported recipes, ambiguous producers, cycles, and outputs that cannot be auctioned hide affected rows. BoP outputs are excluded. Margins are before AH fees. No automatic crafts, purchases, or listings
Calculations run only on opening the window, changing a filter, or confirming AH price clearing. Capture, learning, item events, and AH scan completion do not refresh profit rows. Reopen the window to use those inputs. Hidden windows do not calculate

## Tailoring profit

Use `/reload` after installing, then left-click the Tailoring minimap icon or use `/jj tailor` to toggle its separate window. The icon starts at 120 degrees. Left-drag to move it. Its position is saved in `JJSettings.minimapButtons.tailoring`
Tailoring profit starts enabled. Toggle it in `/jj`, then click Reload. It does not need the other profession features enabled
Open your own native Tailoring, wait for recipes, then use `/jj tailorscan`. Keep it open until completion, up to 60 seconds. Capture and cancellation work like Cooking. Native minimum yields set output quantities and sale values
Recipes are account-wide in `JJTailoringCatalog`. Learned status and filters are per character in `JJTailoringCharacter`. Learning requirements use the shared static verified Forever data. Argent Boots and Argent Shoulders remain unknown because their learning items have conflicting ranks. Missing ranks show `-`
Search, Materials, Prices, Include unlearned, and Max Tailor skill work like Engineering. Buy finished inputs and Latest lowest are the defaults. Include unlearned and Exclude gear start off. Exclude gear hides wearable outputs but keeps bags and nongear. Auto uses native base Tailoring rank without bonuses. Learned recipes and requirements that still show `-` remain eligible above the cap. Recipe access, tools, and current crafting availability are not checked. Owned inventory does not filter results or reduce costs
Buy finished inputs prices ingredients directly. Buy raw materials expands only captured Tailoring intermediaries, such as cloth bolts, and buys their inputs. Production rounds up to whole crafts, with no leftover sale credit. Both modes use shared static base vendor prices first, then the selected AH price for unlisted inputs. Neither mode chooses the cheapest route. No Farm mode. Learned-only results require every expanded recipe to be learned. Production cooldowns, including Mooncloth, and their value are not modeled
Rows and nested tooltips use the shared Gold view. Missing prices, unsupported recipes, ambiguous producers, cycles, and outputs that cannot be auctioned hide affected rows. Margins are before AH fees. No automatic crafts, purchases, or listings
Calculations run only on opening the window, changing a filter, or confirming AH price clearing. Capture, learning, item events, and AH scan completion do not refresh profit rows. Reopen the window to use those inputs. Hidden windows do not calculate

## Add tweaks

Add each feature as a separate Lua file and list its path after `Core.lua` in `wow-addon.toc`
Get the addon namespace with `local _, addon = ...`, then call `addon.RegisterFeature("uniqueKey", "Checkbox label", function(enabled) ... end)`
The callback runs at startup after saved settings load, not when its checkbox changes. Reload the UI to apply changes
New features start enabled unless the fourth argument is `false`, and the callback must support both states
Restart WoW after adding files or changing the TOC
Use `/reload` after edits to Lua files already listed in the TOC
