local _, ns = ...
local Parrot = ns.addon
local module = Parrot:NewModule("PointGains")
local L = LibStub("AceLocale-3.0"):GetLocale("Parrot_PointGains")

local newDict, newList = Parrot.newDict, Parrot.newList
local Deformat = Parrot.Deformat

local currentXP = 0

function module:OnEnable()
	currentXP = UnitXP("player")
end

-- Currency
local CURRENCY_GAINED = _G.CURRENCY_GAINED
local CURRENCY_GAINED_MULTIPLE = _G.CURRENCY_GAINED_MULTIPLE
local HONOR_CURRENCY = _G.HONOR_CURRENCY
local ITEM_QUALITY_COLORS = _G.ITEM_QUALITY_COLORS

local function parseCurrencyUpdate(chatmsg)
	local currency, amount = Deformat(chatmsg, CURRENCY_GAINED_MULTIPLE)
	if not currency then
		currency = Deformat(chatmsg, CURRENCY_GAINED)
	end

	if currency then
		local currencyId = currency:match("|Hcurrency:(%d+)|h%[(.+)%]|h")
		if not currencyId or tonumber(currencyId) == HONOR_CURRENCY then return end

		local name, total, texture, _, _, _, _, quality = GetCurrencyInfo(currencyId)
		local color = ITEM_QUALITY_COLORS[quality]
		if color then
			name = ("%s%s|r"):format(color.hex, name)
		end
		return newDict(
			"currency", name,
			"amount", amount or 1,
			"total", total,
			"icon", texture
		)
	end
end

Parrot:RegisterCombatEvent{
	category = "Notification",
	--subCategory = "Loot",
	name = "Currency gains",
	localName = L["Currency gains"],
	defaultTag = "+[Amount] [Currency] ([Total])",
	tagTranslations = {
		Amount = "amount",
		Currency = "currency",
		Total = "total",
		Icon = "icon",
	},
	tagTranslationsHelp = {
		Name = L["Name of the currency"],
		Amount = L["The amount of currency gained."],
		Total = L["Your total amount of the currency."],

	},
	color = "7f7fb2", -- blue-gray
	events = {
		CHAT_MSG_CURRENCY = { parse = parseCurrencyUpdate },
	}
}

-- Reputation
Parrot:RegisterThrottleType("Reputation gains", L["Reputation gains"], 0.1, true)

local REPUTATION = _G.REPUTATION
local FACTION_STANDING_INCREASED = _G.FACTION_STANDING_INCREASED
local FACTION_STANDING_DECREASED = _G.FACTION_STANDING_DECREASED

local function repThrottleFunc(info)
	local num = info.throttleCount or 0
	if num > 1 then
		return (" (%dx)"):format(num)
	end
	return nil
end

local function parseRepGain(chatmsg)
	local faction, amount = Deformat(chatmsg, FACTION_STANDING_INCREASED)
	if faction and amount then
		local info = newList()
		info.amount = amount
		info.faction = faction
		return info
	end
	return nil
end

local function parseRepLoss(chatmsg)
	local faction, amount = Deformat(chatmsg, FACTION_STANDING_DECREASED)
	if faction and amount then
		local info = newList()
		info.amount = amount
		info.faction = faction
		return info
	end
	return nil
end

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Reputation"],
	name = "Reputation gains",
	localName = L["Reputation gains"],
	defaultTag = "+[Amount] " .. REPUTATION .. " ([Faction])",
	events = {
		CHAT_MSG_COMBAT_FACTION_CHANGE = { parse = parseRepGain },
	},
	tagTranslations = {
		Amount = "amount",
		Faction = "faction",
	},
	tagTranslationsHelp = {
		Amount = L["The amount of reputation gained."],
		Faction = L["The name of the faction."],
	},
	color = "7f7fb2", -- blue-gray
	throttle = {
		"Reputation gains",
		"faction",
		{ "throttleCount", repThrottleFunc, },
	},
}

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Reputation"],
	name = "Reputation losses",
	localName = L["Reputation losses"],
	defaultTag = "-[Amount] " .. REPUTATION .. " ([Faction])",
	events = {
		CHAT_MSG_COMBAT_FACTION_CHANGE = { parse = parseRepLoss },
	},
	tagTranslations = {
		Amount = function(info) return info.amount end,
		Faction = "faction",
	},
	tagTranslationsHelp = {
		Amount = L["The amount of reputation lost."],
		Faction = L["The name of the faction."],
	},
	color = "7f7fb2", -- blue-gray
}

-- Skill gains
local SKILL_RANK_UP = _G.SKILL_RANK_UP

local function retrieveAbilityName(info)
	return Parrot:GetAbbreviatedSpell(info.abilityName)
end

local function parseSkillGain(chatmsg)
	local skill, amount = Deformat(chatmsg, SKILL_RANK_UP)
	if skill and amount then
		local info = newList()
		info.abilityName = skill
		info.amount = amount
		return info
	end
end

Parrot:RegisterCombatEvent{
	category = "Notification",
	name = "Skill gains",
	localName = L["Skill gains"],
	defaultTag = "[Skillname]: [Amount]",
	events = {
		CHAT_MSG_SKILL = { parse = parseSkillGain },
	},
	tagTranslations = {
		Skillname = retrieveAbilityName,
		Amount = "amount",
	},
	tagTranslationsHelp = {
		Skill = L["The skill which experienced a gain."],
		Amount = L["The amount of skill points currently."]
	},
	color = "5555ff", -- semi-light blue
}

-- XP gains
local XP = _G.XP

local function parseXPUpdate()
	local newXP = UnitXP("player")
	local delta = newXP - currentXP
	if delta > 0 then
		local info = newDict("amount", delta)
		currentXP = newXP
		return info
	end
end

Parrot:RegisterCombatEvent{
	category = "Notification",
	name = "Experience gains",
	localName = L["Experience gains"],
	defaultTag = "[Amount] " .. XP,
	tagTranslations = {
		Amount = "amount",
	},
	tagTranslationsHelp = {
		Amount = L["The amount of experience points gained."]
	},
	color = "bf4ccc", -- magenta
	sticky = true,
	defaultDisabled = true,
	events = {
		PLAYER_XP_UPDATE = { parse = parseXPUpdate },
	},
}
