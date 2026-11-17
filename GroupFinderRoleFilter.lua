local _, addon = ...

addon.RegisterFeature("groupFinderRoleFilter", "Group finder role filter", function(enabled)
    if not enabled then
        return
    end

    EventUtil.ContinueOnAddOnLoaded("Blizzard_GroupFinder_VanillaStyle", function()
        local browse = LFGBrowseFrame
        local role = "all"
        local hideGroups = false

        local function HideResult(resultID)
            local info = C_LFGList.GetSearchResultInfo(resultID)
            if not info then
                return
            end
            if info.hasSelf then
                return false
            end
            if info.numMembers > 1 then
                return hideGroups
            end
            if role == "all" then
                return false
            end
            local player = C_LFGList.GetSearchResultPlayerInfo(resultID, 1)
            return not (player and player.lfgRoles and player.lfgRoles[role])
        end

        local function FilterResults()
            if role == "all" and not hideGroups then
                return
            end
            local provider = browse.ScrollBox:GetDataProvider()
            if not provider then
                return
            end

            local changed = false
            for _, node in provider:EnumerateEntireRange() do
                local data = node:GetData()
                if data.resultID and HideResult(data.resultID) then
                    node:GetParent():Remove(node, TreeDataProviderConstants.SkipInvalidation)
                    changed = true
                end
            end
            local headers = provider:GetChildrenNodes()
            for index = #headers, 1, -1 do
                local node = headers[index]
                if node:GetData().dividerType and node:GetSize() == 0 then
                    node:GetParent():Remove(node, TreeDataProviderConstants.SkipInvalidation)
                    changed = true
                end
            end
            if changed then
                provider:Invalidate()
            end
            browse.NoResultsFound:SetShown(provider:IsEmpty())
        end

        hooksecurefunc(browse, "UpdateResults", FilterResults)

        browse:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED")
        browse:HookScript("OnEvent", function(self, event, resultID)
            if event ~= "LFG_LIST_SEARCH_RESULT_UPDATED" or (role == "all" and not hideGroups) or not self:IsShown() then
                return
            end
            local provider = self.ScrollBox:GetDataProvider()
            if not provider or not tContains(self.results, resultID) then
                return
            end
            local visible = provider:ContainsByPredicate(function(node)
                return node:GetData().resultID == resultID
            end, TreeDataProviderConstants.IncludeCollapsed)
            local hidden = HideResult(resultID)
            if hidden ~= nil and visible == hidden then
                browse:UpdateResults()
            end
        end)

        -- Blizzard shares this tag with the listing tab's options menu
        Menu.ModifyMenu("MENU_LFG_LISTING_SETTINGS", function(owner, root)
            if owner ~= browse.OptionsButton then
                return
            end
            root:CreateDivider()
            root:CreateTitle("Role")
            for _, choice in ipairs({ { "All roles", "all" }, { "Tanks", "tank" }, { "Healers", "healer" } }) do
                root:CreateRadio(choice[1], function() return role == choice[2] end, function()
                    role = choice[2]
                    -- UpdateResults renders cached IDs without starting a search
                    browse:UpdateResults()
                end)
            end
            root:CreateCheckbox("Hide groups", function() return hideGroups end, function()
                hideGroups = not hideGroups
                browse:UpdateResults()
            end)
        end)
    end)
end, false)
