local _, addon = ...

addon.RegisterFeature("autoAcceptSellJunkConfirmation", "Accept Sell Junk confirmation", function(enabled)
    if not enabled then
        return
    end

    hooksecurefunc("StaticPopup_ShowCustomGenericConfirmation", function(data)
        if data.callback ~= MerchantFrame_OnSellAllJunkButtonConfirmed then
            return
        end

        local dialog = StaticPopup_FindVisible("GENERIC_CONFIRMATION", data)
        if dialog then
            dialog:GetButton1():Click()
        end
    end)
end)
