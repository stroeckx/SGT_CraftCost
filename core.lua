SGTCraftCost = LibStub("AceAddon-3.0"):NewAddon("SGTCraftCost", "AceConsole-3.0", "AceEvent-3.0");
SGTCraftCost.L = LibStub("AceLocale-3.0"):GetLocale("SGTCraftCost");

--Variables start
SGTCraftCost.majorVersion = 1;
SGTCraftCost.subVersion = 0;
SGTCraftCost.minorVersion = 3;
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
    professionsSchematic.QualityDialog:RegisterCallback("Accepted", SGTCraftCost.OnReagentsModified);
    SGTCore:AddTabWithFrame("SGTCraftCost", SGTCraftCost.L["Craft Cost"], SGTCraftCost.L["Craft Cost"], SGTCraftCost:GetVersionString(), SGTCraftCost.OnCraftCostFrameCreated);
    EventRegistry:RegisterCallback("ProfessionsRecipeListMixin.Event.OnRecipeSelected", SGTCraftCost.UpdateCurrentReagentSelectionPrice);
end

function SGTCraftCost:GetVersionString()
    return tostring(SGTCraftCost.majorVersion) .. "." .. tostring(SGTCraftCost.subVersion) .. "." .. tostring(SGTCraftCost.minorVersion);
end

function SGTCraftCost:OnCraftCostFrameCreated()
    local craftCostFrame = SGTCore:GetTabFrame("SGTCraftCost");
    local craftCostDescription = SGTCore:AddAnchoredFontString("SGTCoreDescriptionsText", craftCostFrame.scrollframe.scrollchild, craftCostFrame, 5, -5, SGTCraftCost.L["SGTCraftCostDescription"], craftCostFrame);
end

function SGTCraftCost:tst()
    SGTCraftCost:UpdateCurrentReagentSelectionPrice();
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
    local slots = ProfessionsFrame.CraftingPage.SchematicForm:GetSlotsByReagentType(Enum.CraftingReagentType.Basic);
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
                if(cheapestMatPrice < 0 or matPrice < cheapestMatPrice) then
                    cheapestMatPrice = matPrice;
                end
                allocatedPrice = allocatedPrice + (quantities[tier] * matPrice);
            end
        end
        minPrice = minPrice + (quantityRequired * cheapestMatPrice);
    end
    schematic.QualityDialog:RegisterCallback("Accepted", SGTCraftCost.OnReagentsModified);
    return allocatedPrice, minPrice;
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
    
    return priceFrame;
end

function SGTCraftCost:UpdatePrice(text, priceText)
    if(text ~= nil) then 
        text:SetText(priceText);
    end
end

function SGTCraftCost:GetReagentPrice(itemID)
    local price = SGTPricing:GetShortMarketPrice(itemID);
    if(price == nil) then
        return 0;
    end
    return price;
end