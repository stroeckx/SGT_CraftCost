SGTCraftCost = LibStub("AceAddon-3.0"):NewAddon("SGTCraftCost", "AceConsole-3.0", "AceEvent-3.0");
SGTCraftCost.L = LibStub("AceLocale-3.0"):GetLocale("SGTCraftCost");

--Variables start
SGTCraftCost.majorVersion = 1;
SGTCraftCost.subVersion = 0;
SGTCraftCost.minorVersion = 7;
local professionPriceFrame = nil;
local ordersPriceFrame = nil;
local professionsSchematic = ProfessionsFrame.CraftingPage.SchematicForm;
local orderSchematic = ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm;
--Variables end

function SGTCraftCost:OnInitialize()
    if(SGTCore.DoVersionCheck == nil or SGTCore:DoVersionCheck(1,0,4, SGTCore) == false) then
        message(SGTCraftCost.L["Error_version_core"]);
        return;
    end
    if(SGTCore.DoVersionCheck == nil or SGTCore:DoVersionCheck(1,1,0, SGTPricing) == false) then
        message(SGTCraftCost.L["Error_version_pricing"]);
        return;
    end

    SGTCraftCost.db = LibStub("AceDB-3.0"):New("SGTCraftCostDB", {
        profile = 
        {
            settings = 
            {
                enabled = true,
                hideAuctionatorPrices = true;
                hideAuctionatorSearchButton = true;
                showAllocatedCost = true;
                showMinCost= true;
                showProfit = true;
            },
        },
    });
    
	SGTCraftCost:RegisterEvent("TRADE_SKILL_SHOW", "OnProfessionOpened");
	SGTCraftCost:RegisterChatCommand("tstcc", "tst");
    SGTCore:AddTabWithFrame("SGTCraftCost", SGTCraftCost.L["Craft Cost"], SGTCraftCost.L["Craft Cost"], SGTCraftCost:GetVersionString(), SGTCraftCost.OnCraftCostFrameCreated);
    EventRegistry:RegisterCallback("ProfessionsRecipeListMixin.Event.OnRecipeSelected", SGTCraftCost.OnRecipeSelected);
	professionsSchematic:RegisterCallback(ProfessionsRecipeSchematicFormMixin.Event.AllocationsModified, SGTCraftCost.OnAllocationsModified);
    professionsSchematic:RegisterCallback(ProfessionsRecipeSchematicFormMixin.Event.UseBestQualityModified, SGTCraftCost.UseBestQualityModified);
    C_Timer.After(0, function()
        if(SGTPricing.IsAuctionatorLoaded == true) then
            if(SGTCraftCost.db.profile.settings.hideAuctionatorSearchButton) then 
                Auctionator.Config.Options.CRAFTING_INFO_SHOW = false; --pretty ugly but currently SGT craftcost does nothing else as providing pricing, so presumably if people install this addon they want this pricing.
            end
            if(SGTCraftCost.db.profile.settings.hideAuctionatorPrices) then
                Auctionator.Config.Options.CRAFTING_INFO_SHOW_PROFIT = false; --pretty ugly but currently SGT craftcost does nothing else as providing pricing, so presumably if people install this addon they want this pricing.
                Auctionator.Config.Options.CRAFTING_INFO_SHOW_COST = false; --pretty ugly but currently SGT craftcost does nothing else as providing pricing, so presumably if people install this addon they want this pricing.
            end
        end
    end)
end

function SGTCraftCost:GetVersionString()
    return tostring(SGTCraftCost.majorVersion) .. "." .. tostring(SGTCraftCost.subVersion) .. "." .. tostring(SGTCraftCost.minorVersion);
end

function SGTCraftCost:OnCraftCostFrameCreated()
    local craftCostFrame = SGTCore:GetTabFrame("SGTCraftCost");
    local scrollframe = craftCostFrame.scrollframe.scrollchild;
    local craftCostDescription = SGTCore:AddAnchoredFontString("SGTCraftCostDescriptionText", craftCostFrame.scrollframe.scrollchild, craftCostFrame, 5, -5, SGTCraftCost.L["SGTCraftCostDescription"], craftCostFrame);
    local showAllocCheckbox = SGTCore:AddOptionCheckbox("SGTCraftCostShowAllocatedCheckbox", scrollframe, craftCostDescription, SGTCraftCost.db.profile.settings.showAllocatedCost, SGTCraftCost.L["showAllocated"], function(x, checked) 
        SGTCraftCost.db.profile.settings.showAllocatedCost = checked; 
        if(checked) then
            professionPriceFrame.Text:Show();
            ordersPriceFrame.Text:Show();
        else
            professionPriceFrame.Text:Hide();
            ordersPriceFrame.Text:Hide();
        end
    end)
    local showMinCheckbox = SGTCore:AddOptionCheckbox("SGTCraftCostShowMinatedCheckbox", scrollframe, showAllocCheckbox, SGTCraftCost.db.profile.settings.showMinCost, SGTCraftCost.L["showMin"], function(x, checked) 
        SGTCraftCost.db.profile.settings.showMinCost = checked; 
        if(checked) then
            professionPriceFrame.Text2:Show();
            ordersPriceFrame.Text2:Show();
        else
            professionPriceFrame.Text2:Hide();
            ordersPriceFrame.Text2:Hide();
        end
    end)
    local showProfitCheckbox = SGTCore:AddOptionCheckbox("SGTCraftCostShowProfitCheckbox", scrollframe, showMinCheckbox, SGTCraftCost.db.profile.settings.showProfit, SGTCraftCost.L["showProfit"], function(x, checked) 
        SGTCraftCost.db.profile.settings.showProfit = checked; 
        if(checked) then
            professionPriceFrame.Text3:Show();
            ordersPriceFrame.Text3:Show();
        else
            professionPriceFrame.Text3:Hide();
            ordersPriceFrame.Text3:Hide();
        end
    end)
    local hideAuctionatorPricesCheckbox = SGTCore:AddOptionCheckbox("SGTCraftCostHideAuctionatorPricesCheckbox", scrollframe, showProfitCheckbox, SGTCraftCost.db.profile.settings.hideAuctionatorPrices, SGTCraftCost.L["hideAuctionatorPrices"], function(x, checked) SGTCraftCost.db.profile.settings.hideAuctionatorPrices = checked; end)
    local hideAuctionatorSearchCheckbox = SGTCore:AddOptionCheckbox("SGTCraftCostHideAuctionatorSearchCheckbox", scrollframe, hideAuctionatorPricesCheckbox, SGTCraftCost.db.profile.settings.hideAuctionatorSearchButton, SGTCraftCost.L["hideAuctionatorPrices"], function(x, checked) SGTCraftCost.db.profile.settings.hideAuctionatorSearchButton = checked; end)
end

function SGTCraftCost:OnAllocationsModified()
    SGTCraftCost:UpdateCurrentReagentSelectionPrice();
end

function SGTCraftCost:UseBestQualityModified()
    SGTCraftCost:UpdateCurrentReagentSelectionPrice();
end

function SGTCraftCost:OnRecipeSelected(recipeInfo)
    C_Timer.After(0, function()
        SGTCraftCost:UpdateCurrentReagentSelectionPrice();
    end)
end

function SGTCraftCost:tst(item)
    --local x1 = string.gsub(item,"|","\\124");
    --print(x1);
    --print("|cff1eff00|Hitem:193522::::::::70:577::13:5:8839:8840:5247:8983:8802:5:28:2164:29:40:30:36:38:8:40:416::::Player-3391-09B7156D:|h[Crimson Combatant's Wildercloth Cloak |A:Professions-ChatIcon-Quality-Tier5:17:17::1|a]|h|r 7")
    --print("|cff1eff00|Hitem:193522::::::::70:577::13:5:8839:8840:5247:8983:8802:5:28:2164:29:40:30:36:38:8:40:416:::::|h[Crimson Combatant's Wildercloth Cloak |A:Professions-ChatIcon-Quality-Tier5:17:17::1|a]|h|r 7")
    --print("|cff1eff00|Hitem:193522::::::::70:577::13:5:8839:8840:5247:8983:8802:5:28:2164:29:40:30:36:38:8:40:416:::::|h[Crimson Combatant's Wildercloth Cloak |A::17:17::1|a]|h|r 7")
    --print("|cff1eff00|Hitem:193522::::::::70:577::13:5:8839:8840:5247:8983:8802:5:28:2164:29:40:30:36:38:8:40:416:::::|h[Crimson Combatant's Wildercloth Cloak]|h|r")
    --print("|cff1eff00|Hitem:193522::::::::70:577::13:1:3524:2:40:416:38:8:::::|h[Crimson Combatant's Wildercloth Cloak]|h|r")
    --print("|cff0070dd|Hitem:201943::::::::70:577::13:1:3524:2:40:847:38:8:::::|h[Pioneer's Practiced Gloves]|h|r")
    --print("|cff0070dd|Hitem:201943::::::::70:577::13:1:3524:2:40:847:38:8:::::|r")
    --
    --print(TSM_API.ToItemString("|cff0070dd|Hitem:201943::::::::70:577::13:1:3524:2:40:847:38:8:::::|h[Pioneer's Practiced Gloves]|h|r"))
    --print("|cff1eff00|Hitem:193522::::::::70:577::13:1:3524:2:40:416:38:8:::::::::::::::|h[Crimson Combatant's Wildercloth Cloak]|h|r")
    --print(TSM_API.ToItemString("|cff1eff00|Hitem:193522::::::::70:577::13:1:3524:2:40:416:38:8:::::::::::::::|h[Crimson Combatant's Wildercloth Cloak]|h|r"))
    --print(TSM_API.ToItemString("|cff1eff00|Hitem:193522::::::::70:577::13:5:8839:1:11:111:11:1:::::::::::::::|h[Crimson Combatant's Wildercloth Cloak]|h|r"))
    --print(TSM_API.GetCustomPriceValue("DBRecent", TSM_API.ToItemString("|cff1eff00|Hitem:193522::::::::70:577::13:5:8839:1:11:111:11:1:::::::::::::::|h[Crimson Combatant's Wildercloth Cloak]|h|r")))
    --print(TSM_API.GetCustomPriceValue("DBRecent", TSM_API.ToItemString("|cff0070dd|Hitem:201943::::::::70:577::13:1:3524:2:40:847:38:8:::::|h[Pioneer's Practiced Gloves]|h|r")))
    --print(TSM_API.ToItemString("|cff0070dd|Hitem:201943::::::::70:577::13:1:3524:2:40:847:38:8:::::|h[Pioneer's Practiced Gloves]|h|r"))
    --print(TSM_API.ToItemString("|cff0070dd|Hitem:201943::::::::70:577::13:1:3524:2:40:847:38:8:::::::::::::::|h[Pioneer's Practiced Gloves]|h|r"))
    --print(TSM_API.ToItemString("|cff0070dd|Hitem:201943::::::::70:577::13:1:8851:2:40:847:38:8:::::::::::::::|h[Pioneer's Practiced Gloves]|h|r"))
    --print(TSM_API.ToItemString("|cff0070dd|Hitem:201943::::::::70:577::13:3:8851:8852:8802:5:28:2164:29:32:30:49:38:8:40:847:::::|h[Pioneer's Practiced Gloves]|h|r"))
    --print(TSM_API.GetCustomPriceValue("DBRecent", TSM_API.ToItemString("|cff0070dd|Hitem:201943::::::::70:577::13:1:8851:8852:8802:847:38:8:::::::::::::::|h[Pioneer's Practiced Gloves]|h|r")))
    --print(TSM_API.GetCustomPriceValue("DBRecent", TSM_API.ToItemString("|cff0070dd|Hitem:201943::::::::70:577::13:3:8851:8852:8802:5:28:2164:29:32:30:49:38:8:40:847:::::|h[Pioneer's Practiced Gloves]|h|r")))


    
    
    --print(tostring(item))
    --local x1 = string.gsub(item,"|","\\124");
    --print(x1);
    --local x2 = string.gsub(x1,"\\124","|");
    --print(x2);
    --print(string.gsub(item,"|","\\124"));




    --print(string.sub(tostring(item), 2, -7))
    --local test, t2 = GetItemInfo(item);
    --print(t2);
    --print(tostring(item))
    --print(TSM_API.ToItemString(tostring(item)))
end

function SGTCraftCost:OnProfessionOpened()
    if(professionPriceFrame == nil) then 
        professionPriceFrame = SGTCraftCost:CreateprofessionPriceFrame(professionsSchematic)
    end
    if(ordersPriceFrame == nil) then
        ordersPriceFrame = SGTCraftCost:CreateprofessionPriceFrame(orderSchematic);
    end
end

function SGTCraftCost:OnProfessionClosed()
end

function SGTCraftCost:OnReagentsModified()
    SGTCraftCost:UpdateCurrentReagentSelectionPrice();
end

function SGTCraftCost:UpdateCurrentReagentSelectionPrice()
    if(ProfessionsFrame.CraftingPage:IsVisible()) then
        local price, minPrice = SGTCraftCost:GetCurrentPriceInSchematic(professionsSchematic);
        if(price == nil) then 
            professionPriceFrame.Text:SetText("");
        else
            SGTCraftCost:UpdatePrice(professionPriceFrame.Text, SGTCraftCost.L["AllocPriceText"] .. GetCoinTextureString(price));
        end
        if(minPrice == nil) then 
            professionPriceFrame.Text2:SetText("");
        else
            SGTCraftCost:UpdatePrice(professionPriceFrame.Text2, SGTCraftCost.L["MinPriceText"] .. GetCoinTextureString(minPrice));
        end
        if(minPrice == nil) then
            professionPriceFrame.Text3:SetText("");
            return;
        end

        local resultPriceMin, resultPriceMax  = SGTCraftCost:GetResultValue();
        if(resultPriceMin == nil or resultPriceMin == 0) then 
            professionPriceFrame.Text3:SetText("");
        else
            local minProfit = resultPriceMin - minPrice;
            local prefix = SGTCraftCost.L["ProfitPriceText"];
            local absMinProfit = math.abs(minProfit);
            if minProfit < 0 then 
                prefix = prefix .. " -";
            end

            if resultPriceMax == nil or resultPriceMax == resultPriceMin then 
                SGTCraftCost:UpdatePrice(professionPriceFrame.Text3, prefix .. GetCoinTextureString(absMinProfit));
            else
                local maxProfit = resultPriceMax - minPrice;
                local absMaxProfit = math.abs(maxProfit);
                local midfix = "";
                if maxProfit < 0 then 
                    midfix = "-";
                end
                SGTCraftCost:UpdatePrice(professionPriceFrame.Text3, prefix .. GetCoinTextureString(absMinProfit) .. " < " .. midfix .. GetCoinTextureString(absMaxProfit));
            end
        end
    end

    if(ProfessionsFrame.OrdersPage:IsVisible()) then
        local price, minPrice = SGTCraftCost:GetCurrentPriceInSchematic(orderSchematic);
        if(price == nil) then 
            ordersPriceFrame.Text:SetText("");
            return;
        end
        if(minPrice == nil) then 
            ordersPriceFrame.Text2:SetText("");
            return;
        end
        SGTCraftCost:UpdatePrice(ordersPriceFrame.Text, SGTCraftCost.L["AllocPriceText"] .. GetCoinTextureString(price));
        SGTCraftCost:UpdatePrice(ordersPriceFrame.Text2, SGTCraftCost.L["MinPriceText"] .. GetCoinTextureString(minPrice));
    end
end

function SGTCraftCost:GetCurrentPriceInSchematic(schematic)
    local slots = professionsSchematic:GetSlotsByReagentType(Enum.CraftingReagentType.Basic);
    local allocatedPrice = 0;
    local minPrice = 0;
    if(slots == nil) then
        return nil, nil;
    end;
    for slotIndex, slot in pairs(slots) do
        local schematic = slot:GetReagentSlotSchematic();
        local transaction = slot:GetTransaction();
        local quantities = Professions.GetQuantitiesAllocated(transaction, slot:GetReagentSlotSchematic());
        local quantityRequired = schematic.quantityRequired;
        local cheapestMatPrice = -1;
        for tier, data in pairs(schematic.reagents) do
            for _, reagentID in pairs(data) do
                local matPrice = SGTCraftCost:GetReagentPrice(reagentID);
                if(cheapestMatPrice < 0 or matPrice < cheapestMatPrice and matPrice > 0) then
                    cheapestMatPrice = matPrice;
                end
                allocatedPrice = allocatedPrice + (quantities[tier] * matPrice);
            end
        end
        minPrice = minPrice + (quantityRequired * cheapestMatPrice);
    end
    return allocatedPrice, minPrice;
end

function SGTCraftCost:GetResultValue()
    local recipeInfo = professionsSchematic:GetRecipeInfo();
    local reagents = professionsSchematic.transaction:CreateCraftingReagentInfoTbl();
    local recipeID = recipeInfo.recipeID;
    local outputItemInfo = C_TradeSkillUI.GetRecipeOutputItemData(recipeID, reagents, professionsSchematic.transaction:GetAllocationItemGUID());
    if(outputItemInfo.hyperlink == nil) then
        return;
    end
    local _, itemLink = GetItemInfo(outputItemInfo.hyperlink);
    local outputPrice = SGTCraftCost:GetOutputPrice(itemLink);
    local recipeSchematic = professionsSchematic.transaction:GetRecipeSchematic();
	local quantityMin, quantityMax = recipeSchematic.quantityMin, recipeSchematic.quantityMax;
    return outputPrice * quantityMin, outputPrice * quantityMax;
end

function SGTCraftCost:CreateprofessionPriceFrame(schematic)
    local priceFrame = CreateFrame("Frame", "SGTCraftCostFrame", schematic);
    priceFrame:SetPoint("TOPLEFT", schematic.Reagents, "BOTTOMLEFT",0,0);
    priceFrame:SetSize(200,32);
    
    local text = priceFrame:CreateFontString("SGTCraftCostText","ARTWORK", "GameFontHighlight");
    text:SetPoint("TOPLEFT", priceFrame, "TOPLEFT", 0, 0);
    priceFrame.Text = text;
    if(SGTCraftCost.db.profile.settings.showAllocatedCost == false) then
        text:Hide();
    end

    local text2 = priceFrame:CreateFontString("SGTCraftCostText2","ARTWORK", "GameFontHighlight");
    text2:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, 0);
    priceFrame.Text2 = text2;
    if(SGTCraftCost.db.profile.settings.showMinCost == false) then
        text2:Hide();
    end
    
    local text3 = priceFrame:CreateFontString("SGTCraftCostText3","ARTWORK", "GameFontHighlight");
    text3:SetPoint("TOPLEFT", text2, "BOTTOMLEFT", 0, 0);
    priceFrame.Text3 = text3;
    if(SGTCraftCost.db.profile.settings.showProfit == false) then
        text3:Hide();
    end

    return priceFrame;
end

function SGTCraftCost:UpdatePrice(text, priceText)
    if(text ~= nil) then 
        text:SetText(priceText);
    end
end

function SGTCraftCost:GetReagentPrice(itemID)
    local price = SGTPricing:GetShortMarketPriceByItemID(itemID);
    if(price == nil) then
        return 0;
    end
    return price;
end

function SGTCraftCost:GetOutputPrice(itemLink)
    local price = SGTPricing:GetCurrentAuctionPriceByItemLink(itemLink);
    if(price == nil) then
        return 0;
    end
    return price;
end