--localization file for english/United States
local L = LibStub("AceLocale-3.0"):NewLocale("SGTCraftCost", "enUS", true)
if not L then return end 

L["Craft Cost"] = "Craft Cost"
L["SGTCraftCostDescription"] = "SGT Craft Cost is a module that calculates the cost of crafting an recipe using the materials you currently selected, including accounting for the quality of those materials."
L["PriceText"] = "Craft Cost: "
L["AllocPriceText"] = "Allocated Cost: "
if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
    L["MinPriceText"] = "Min craft Cost: "
else
    L["MinPriceText"] = "Craft Cost: "
end
if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
    L["ProfitPriceText"] = "Expected Profit using min: "
else
    L["ProfitPriceText"] = "Profit: "
end
L["Error_version_core"] = "SGT Core version is below the required version, please update SGT Core.\nSGT CraftCost will not load until you have updated!"
L["Error_version_pricing"] = "SGT Pricing version is below the required version, please update SGT pricing.\nSGT CraftCost will not load until you have updated!"
L["hideAuctionatorPrices"] = "Hide auctionator prices (/reload to apply)"
L["hideAuctionatorSeach"] = "Hide auctionator search button on start (/reload to apply)"
L["showAllocated"] = "Show allocated craft cost"
L["showMin"] = "Show min craft cost"
L["showProfit"] = "Show expected profit using min craft cost"