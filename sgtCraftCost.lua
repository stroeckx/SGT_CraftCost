SGTCraftCost = LibStub("AceAddon-3.0"):NewAddon("SGTCraftCost", "AceConsole-3.0", "AceEvent-3.0");
SGTCraftCost.L = LibStub("AceLocale-3.0"):GetLocale("SGTCraftCost");

--Variables start
SGTCraftCost.majorVersion = 1;
SGTCraftCost.subVersion = 0;
SGTCraftCost.minorVersion = 6;
local professionPriceFrame = nil;
local ordersPriceFrame = nil;
local professionsSchematic = ProfessionsFrame.CraftingPage.SchematicForm;
local orderSchematic = ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm;
--Variables end

function SGTCraftCost:OnInitialize()
    if(SGTCore.DoVersionCheck == nil or SGTCore:DoVersionCheck(1,0,2, SGTPricing) == false) then
        message(SGTCraftCost.L["Error_version_pricing"]);
        return;
    end
	SGTCraftCost:RegisterEvent("TRADE_SKILL_SHOW", "OnProfessionOpened");
	SGTCraftCost:RegisterChatCommand("tstcc", "tst");
    SGTCore:AddTabWithFrame("SGTCraftCost", SGTCraftCost.L["Craft Cost"], SGTCraftCost.L["Craft Cost"], SGTCraftCost:GetVersionString(), SGTCraftCost.OnCraftCostFrameCreated);
    EventRegistry:RegisterCallback("ProfessionsRecipeListMixin.Event.OnRecipeSelected", SGTCraftCost.OnRecipeSelected);
	professionsSchematic:RegisterCallback(ProfessionsRecipeSchematicFormMixin.Event.AllocationsModified, SGTCraftCost.OnAllocationsModified);
    professionsSchematic:RegisterCallback(ProfessionsRecipeSchematicFormMixin.Event.UseBestQualityModified, SGTCraftCost.UseBestQualityModified);
    C_Timer.After(0, function()
        if(SGTPricing.IsAuctionatorLoaded == true) then 
            Auctionator.Config.Options.CRAFTING_INFO_SHOW = false; --pretty ugly but currently SGT craftcost does nothing else as providing pricing, so presumably if people install this addon they want this pricing.
            Auctionator.Config.Options.CRAFTING_INFO_SHOW_PROFIT = false; --pretty ugly but currently SGT craftcost does nothing else as providing pricing, so presumably if people install this addon they want this pricing.
            Auctionator.Config.Options.CRAFTING_INFO_SHOW_COST = false; --pretty ugly but currently SGT craftcost does nothing else as providing pricing, so presumably if people install this addon they want this pricing.
        end
    end)
end

function SGTCraftCost:GetVersionString()
    return tostring(SGTCraftCost.majorVersion) .. "." .. tostring(SGTCraftCost.subVersion) .. "." .. tostring(SGTCraftCost.minorVersion);
end

function SGTCraftCost:OnCraftCostFrameCreated()
    local craftCostFrame = SGTCore:GetTabFrame("SGTCraftCost");
    local craftCostDescription = SGTCore:AddAnchoredFontString("SGTCoreDescriptionsText", craftCostFrame.scrollframe.scrollchild, craftCostFrame, 5, -5, SGTCraftCost.L["SGTCraftCostDescription"], craftCostFrame);
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
    print(string.sub(tostring(item), 2, -7))
    local test, t2 = GetItemInfo(item);
    print(t2);
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

    local text2 = priceFrame:CreateFontString("SGTCraftCostText2","ARTWORK", "GameFontHighlight");
    text2:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, 0);
    priceFrame.Text2 = text2;
    
    local text3 = priceFrame:CreateFontString("SGTCraftCostText3","ARTWORK", "GameFontHighlight");
    text3:SetPoint("TOPLEFT", text2, "BOTTOMLEFT", 0, 0);
    priceFrame.Text3 = text3;

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