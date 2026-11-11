local _, addon = ...
local lw = addon.Leatherworking

function lw.RequiredSkill(recipeID, recipe)
    recipe = recipe or JJLWCatalog.recipes[recipeID]
    local requirements = JJLWCatalog and JJLWCatalog.trainerRequirements
    local trainer = requirements and requirements[recipeID]
    if trainer == false or (trainer and recipe.requiredSkill and trainer ~= recipe.requiredSkill) then return end
    return trainer or recipe.requiredSkill
end

function lw.InitializeTrainer()
    local open = false
    local events = CreateFrame("Frame")
    events:RegisterEvent("TRAINER_SHOW")
    events:RegisterEvent("TRAINER_UPDATE")
    events:RegisterEvent("TRAINER_CLOSED")
    events:SetScript("OnEvent", function(_, event)
        if event == "TRAINER_CLOSED" then
            open = false
            return
        end
        if event == "TRAINER_SHOW" then open = true end
        if not open or not JJLWCatalog then return end
        -- SHOW establishes the native interaction, even before its frame is shown.
        if event == "TRAINER_UPDATE" and (not ClassTrainerFrame or not ClassTrainerFrame:IsShown()) then return end
        local profession = C_TradeSkillUI.GetProfessionInfoBySkillLineID(165)
        for index = 1, GetNumTrainerServices() do
            -- The third return says whether this character meets the requirement.
            local skill, rank = GetTrainerServiceSkillReq(index)
            if skill == profession.professionName and rank and rank > 0 and rank == math.floor(rank) then
                local tooltip = C_TooltipInfo.GetTrainerService(index)
                -- Forever 70888 TooltipUtil.GetDisplayedSpell uses this exact type and ID.
                -- Output item links and recipe names are not recipe spell identities.
                local recipeID = tooltip and tooltip.type == Enum.TooltipDataType.Spell and tooltip.id
                if recipeID and JJLWCatalog.recipes[recipeID] then
                    JJLWCatalog.trainerRequirements = JJLWCatalog.trainerRequirements or {}
                    local requirements = JJLWCatalog.trainerRequirements
                    local previous = requirements[recipeID]
                    -- false preserves a conflicting observation as Unknown, never the minimum.
                    if previous ~= nil and previous ~= rank then
                        requirements[recipeID] = false
                    else
                        requirements[recipeID] = rank
                    end
                end
            end
        end
    end)
end
