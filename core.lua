SGTCraftCost = LibStub("AceAddon-3.0"):NewAddon("SGTCraftCost", "AceConsole-3.0", "AceEvent-3.0");
SGTCraftCost.L = LibStub("AceLocale-3.0"):GetLocale("SGTCraftCost");

--Variables start
local SGTCraftCostVersion = "v1.0";
local professionPriceFrame = nil;
local ordersPriceFrame = nil;
local professionsSchematic = ProfessionsFrame.CraftingPage.SchematicForm;
local orderSchematic = ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm;
--Variables end

function SGTCraftCost:OnInitialize()
	SGTCraftCost:RegisterEvent("TRADE_SKILL_SHOW", "OnProfessionOpened");
	SGTCraftCost:RegisterChatCommand("tstcc", "tst");
    professionsSchematic.QualityDialog:RegisterCallback("Accepted", SGTCraftCost.OnReagentsModified);
    SGTCore:AddTabWithFrame("SGTCraftCost", SGTCraftCost.L["Craft Cost"], SGTCraftCost.L["Craft Cost"], SGTCraftCostVersion, SGTCraftCost.OnCraftCostFrameCreated);
    EventRegistry:RegisterCallback("ProfessionsRecipeListMixin.Event.OnRecipeSelected", SGTCraftCost.UpdateCurrentReagentSelectionPrice);
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
        local price = SGTCraftCost:GetCurrentPriceInSchematic(professionsSchematic);
        if(price == nil) then 
            professionPriceFrame.Text:SetText("");
            return;
        end
        SGTCraftCost:UpdatePrice(professionPriceFrame, GetCoinTextureString(price));
    end

    if(ProfessionsFrame.OrdersPage:IsVisible()) then
        local price = SGTCraftCost:GetCurrentPriceInSchematic(orderSchematic);
        if(price == nil) then 
            ordersPriceFrame.Text:SetText("");
            return;
        end
        SGTCraftCost:UpdatePrice(ordersPriceFrame, GetCoinTextureString(price));
    end
end

function SGTCraftCost:GetCurrentPriceInSchematic(schematic)
    local slots = ProfessionsFrame.CraftingPage.SchematicForm:GetSlotsByReagentType(Enum.CraftingReagentType.Basic);
    local price = 0;
    if(slots == nil) then
        return nil;
    end;
    for slotIndex, slot in pairs(slots) do
        local schematic = slot:GetReagentSlotSchematic();
        local transaction = slot:GetTransaction();
        local quantities = Professions.GetQuantitiesAllocated(transaction, slot:GetReagentSlotSchematic());
        for tier, data in pairs(schematic.reagents) do
            for _, reagentID in pairs(data) do
                price = price + quantities[tier] * SGTCraftCost:GetReagentPrice(reagentID);
            end
        end
    end
    schematic.QualityDialog:RegisterCallback("Accepted", SGTCraftCost.OnReagentsModified);
    return price;
end

function SGTCraftCost:CreateprofessionPriceFrame(schematic)
    local priceFrame = CreateFrame("Frame", "SGTCraftCostFrame", schematic);
    priceFrame:SetPoint("TOPLEFT", schematic.Reagents, "BOTTOMLEFT",0,0);
    priceFrame:SetSize(200,16);
    
    local text = priceFrame:CreateFontString("SGTCraftCostText","ARTWORK", "GameFontHighlight");
    text:SetPoint("TOPLEFT",priceFrame, "TOPLEFT", 0, 0);
    priceFrame.Text = text;
    return priceFrame;
end

function SGTCraftCost:UpdatePrice(frame, priceText)
    if(frame ~= nil and frame.Text ~= nil) then 
        frame.Text:SetText(priceText);
    end
end

function SGTCraftCost:GetReagentPrice(itemID)
    local price = SGTPricing:GetCurrentAuctionPrice(itemID);
    if(price == nil) then
        return 0;
    end
    return price;
end