local L = LibStub("AceLocale-3.0"):GetLocale("GreatVaultStatus")
GreatVaultStatus = LibStub("AceAddon-3.0"):NewAddon("GreatVaultStatus", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "LibSink-2.0",
	"AceComm-3.0", "AceSerializer-3.0");

local textures = {}
GreatVaultStatus.data = nil

textures.GreatVaultStatus = "Interface\\Addons\\GreatVaultStatus\\media\\icon.blp"
textures.alliance = "|TInterface\\FriendsFrame\\PlusManz-Alliance:18|t"
textures.horde = "|TInterface\\FriendsFrame\\PlusManz-Horde:18|t"
textures.tick = "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:16|t"
textures.reward = "|TInterface\\WorldMap\\Gear_64Grey:16|t"
--Interface/Challenges/ChallengeModeTab
--textures.reward = "|TInterface\\Addons\\GreatVault\\media\\icon.blp:16|t"


local addonName = "GreatVaultStatus"
local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LDB and LibStub("LibDBIcon-1.0", true)
local LibQTip = LibStub('LibQTip-1.0')

local colors = {
	rare = { r = 0, g = 0.44, b = 0.87},
	epic = { r = 0.63921568627451, g = 0.2078431372549, b = 0.93333333333333 },
	white = { r = 1.0, g = 1.0, b = 1.0 },
	yellow = { r = 1.0, g = 1.0, b = 0.2 }
}

local red = { r = 1.0, g = 0.2, b = 0.2 }
local blue = { r = 0.4, g = 0.4, b = 1.0 }
local green = { r = 0.2, g = 1.0, b = 0.2 }
local yellow = { r = 1.0, g = 1.0, b = 0.2 }
local gray = { r = 0.5, g = 0.5, b = 0.5 }
local black = { r = 0.0, g = 0.0, b = 0.0 }
local white = { r = 1.0, g = 1.0, b = 1.0 }
local epic = { r = 0.63921568627451, g = 0.2078431372549, b = 0.93333333333333 }
local frame

local COL_CHARACTER = 2
local COL_ITEMLEVEL = 3
local COL_REWARDS = 4
local COL_RAIDS = 5
local COL_ACTIVITIES = 8
local COL_WORLD = 11

local SORT_ASC = 1
local SORT_DEC = 2

local sortColumn = COL_CHARACTER
local sortAscending = true 
local showSingleRealm = true


local defaults = {
	realm = {
		characters = {
			},
	},
	global = {
		realms = {
			},
		MinimapButton = {
			hide = false,
		},
		displayOptions = {
			showHintLine = true,
			showLegend = true,
			showMinimapButton = true,
		},
		characterOptions = {
			levelRestriction = true,
			minimumLevel = 50,
			removeInactive = true,
			inactivityThreshold = 28,
			include = 3,
		},
		bossOptions = {
			hideBoss = {
			},
			trackLegacyBosses = false,
			disableHoldidayBossTracking = false,
		},
		bonusRollOptions = {
			trackWeeklyQuests = true,
			trackedCurrencies = {
				[1129] = true,
			},
			trackLegacyCurrencies = false,
		},
	},
}

-- Use this to sort encounters
local function encounterSorter(entry1, entry2)
	if ( entry1.level == entry2.level ) then
		return entry1.mapChallengeModeID < entry2.mapChallengeModeID;
	else
		return entry1.level > entry2.level;
	end
end

-- search thru a list for a value.  really, lua doesn't have table.find() 
local function locate( table, value )
	for i = 1, #table do
			if table[i] == value then return true end
	end
	return false
end

local function GetTableSize(T)
	local count = 0

	if T then
		for _ in pairs(T) do
			count = count +1
		end
	end

	return count
end

local function RealmOnClick(cell, realmName)
	GreatVaultStatus.db.global.realms[realmName].collapsed = not GreatVaultStatus.db.global.realms[realmName].collapsed
	GreatVaultStatus:ShowToolTip()
end

local function HeaderOnClick(cell, column)
	if column == sortColumn then
		sortAscending = not sortAscending
	else
		sortColumn = column
	end

	GreatVaultStatus.db.global.sortColumn = sortColumn
	if sortAscending then
		GreatVaultStatus.db.global.sortOrder = "Ascending"
	else
		GreatVaultStatus.db.global.sortOrder = "Descending"
	end

	GreatVaultStatus:ShowToolTip()
end

local GreatVaultStatusLauncher = LDB:NewDataObject(addonName, {
		type = "data source",
		text = L["Great Vault Status"],
		label = "GreatVaultStatus",
		tocname = "GreatVaultStatus",
			--"launcher",
		icon = textures.GreatVaultStatus,
		OnClick = function(clickedframe, button)
			--GreatVaultStatus:ShowOptions()
		end,
		OnEnter = function(self)
			frame = self
			GreatVaultStatus:ShowToolTip()
		end,
	})


function GreatVaultStatus:IsShowMinimapButton(info)
	return not self.db.global.MinimapButton.hide
end

function GreatVaultStatus:ToggleMinimapButton(info, value)

	self.db.global.MinimapButton.hide = not value

	if self.db.global.MinimapButton.hide then
		LDBIcon:Hide(addonName)
	else
		LDBIcon:Show(addonName)
	end

	LDBIcon:Refresh(addonName)
	LDBIcon:Refresh(addonName)
end

function GreatVaultStatus:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("GreatVaultStatusDB", defaults, true)
	self.debug = self.db.global.debug

	sortColumn = self.db.global.sortColumn or COL_CHARACTER
	sortAscending = not self.db.global.sortOrder or self.db.global.sortOrder == "Ascending"
	showSingleRealm = GetTableSize(self.db.global.realms) <= 1

	if showSingleRealm then
		COL_CHARACTER = 1
		COL_ITEMLEVEL = 2
		COL_REWARDS = 3
		COL_RAIDS = 4
		COL_ACTIVITIES = 7
		COL_WORLD = 10
	end

	LDBIcon:Register(addonName, GreatVaultStatusLauncher, self.db.global.MinimapButton)

	C_AddOns.LoadAddOn("Blizzard_WeeklyRewards");
end


function GreatVaultStatus:GetCharacters()
	local realmInfo = self:GetRealmInfo(GetRealmName())
	local characters = realmInfo.characters or {}

	return characters;
end

local function GetWeeklyQuestResetTime()
	local now = time()
	local region = GetCurrentRegion()
	local dayOffset = { 2, 1, 0, 6, 5, 4, 3 }
	local regionDayOffset = {{ 2, 1, 0, 6, 5, 4, 3 }, { 4, 3, 2, 1, 0, 6, 5 }, { 3, 2, 1, 0, 6, 5, 4 }, { 4, 3, 2, 1, 0, 6, 5 }, { 4, 3, 2, 1, 0, 6, 5 } }
	local nextDailyReset = GetQuestResetTime()
	local utc = date("!*t", now + nextDailyReset)
	local reset = regionDayOffset[region][utc.wday] * 86400 + now + nextDailyReset
	
	return reset
end

local function HideSubTooltip()
	local subTooltip = GreatVaultStatus.subTooltip
	if subTooltip then
		LibQTip:Release(subTooltip)
		subTooltip = nil
	end
	GameTooltip:Hide()
	GreatVaultStatus.subTooltip = subTooltip
end


local function GetActivity(activityType, index, activities)
	local activities = activites[activityType]
	local result

	for _, activity in ipairs(activities) do
		if activity.index == index then
			result = activity
			break
		end
	end
	
	return result
end

function SortCharacters(a, b)
	local result

	if sortColumn == COL_CHARACTER then
		if sortAscending then
			result = a.name < b.name
		else
			result = a.name > b.name
		end
	elseif sortColumn == COL_ITEMLEVEL then
		if sortAscending then 
			result = a.averageItemLevel < b.averageItemLevel
		else
			result = a.averageItemLevel > b.averageItemLevel
		end
	elseif sortColumn == COL_RAIDS then

	end

	return result
end

-- This will put one row of character data in the main window
local function ShowActivities(tooltip, line, columnStart, activities, lastUpdated, leftPadding, rightPadding)
	local status
	local column = columnStart
	local activityThisWeek = lastUpdated > GetWeeklyQuestResetTime() - 604800

	table.sort(activities, function(a,b) return a.index < b.index end)

	for _, activity in ipairs(activities) do
		local leftPad = 3
		local rightPad = 3
		local difficulty

		if activity.progress >= activity.threshold and activityThisWeek then
			if activity.type == Enum.WeeklyRewardChestThresholdType.Activities then
				difficulty = L["Dungeons"].." " .. activity.level
			elseif activity.type == Enum.WeeklyRewardChestThresholdType.World then
				difficulty = string.format(GREAT_VAULT_WORLD_TIER, activity.level)
			elseif activity.type == Enum.WeeklyRewardChestThresholdType.Raid then
				difficulty = DifficultyUtil.GetDifficultyName(activity.level)
			end

			status = GREEN_FONT_COLOR_CODE .. difficulty .. FONT_COLOR_CODE_CLOSE			
		else
			local progress = 0

			if activityThisWeek then
				progress = activity.progress
			end

			status = GRAY_FONT_COLOR_CODE .. progress .. '/' .. activity.threshold .. FONT_COLOR_CODE_CLOSE
		end

		if column == columnStart then 
			leftPad = leftPad + leftPadding 
		elseif column == columnStart + 2 then
			rightPad = rightPad + rightPadding
		end

		tooltip:SetCell(line, column, status, nil, "CENTER", nil, nil, leftPad, rightPad)

		tooltip:SetCellScript(line, column, "OnEnter", function(self)
			local info = activity
			GreatVaultStatus:ShowSubTooltip(self, info)
		end)

		tooltip:SetCellScript(line, column, "OnLeave", HideSubTooltip)


		column = column + 1
	end
end

-- Tooltip for a cell in the Raid columns, shows if that cell is unlocked, and what is needed for improvement, and which raids have been run
local function ShowPreviewRaidReward(tooltip, activity)
	local itemLevel = activity.currentItemLevel
	local upgradeItemLevel = activity.upgradeItemLevel
	local currentDifficultyID = activity.level
	local currentDifficultyName = DifficultyUtil.GetDifficultyName(currentDifficultyID);

	-- Iterate raid list until we find the most recent raid name
	local raidName = ""
	local raidIndex = 1
	local _, nextRaidName = EJ_GetInstanceByIndex(raidIndex, true)
	while nextRaidName do
		raidName = nextRaidName
		raidIndex = raidIndex + 1
		_, nextRaidName = EJ_GetInstanceByIndex(raidIndex, true)
	end
	
	if activity.progress < activity.threshold then 
		-- check if they unlocked this reward
		if activity.index == 1 then 
			-- GREAT_VAULT_REWARDS_RAID_INCOMPLETE -- Defeat %d %s |4Boss:Bosses; this week to unlock this reward.|n|nThe item level of this reward will be based on the difficulty of the raid.
			tooltip:AddLine(YELLOW_FONT_COLOR_CODE..string.format(GREAT_VAULT_REWARDS_RAID_INCOMPLETE, activity.threshold - activity.progress, raidName)..FONT_COLOR_CODE_CLOSE)
		else
			-- GREAT_VAULT_REWARDS_RAID_INPROGRESS - Defeat %d more %s |4Boss:Bosses; this week to unlock this reward.|n|nThe item level of this reward will be based on the difficulty of the raid.
			tooltip:AddLine(YELLOW_FONT_COLOR_CODE..string.format(GREAT_VAULT_REWARDS_RAID_INPROGRESS, activity.threshold - activity.progress, raidName)..FONT_COLOR_CODE_CLOSE)
		end
	elseif not itemLevel then 
		-- for some reason we may not have an item level
		tooltip:AddLine(RED_FONT_COLOR_CODE..RETRIEVING_ITEM_INFO..FONT_COLOR_CODE_CLOSE)
	else 
		-- ready to display item level, upgrade item level, and raid bosses killed
		tooltip:AddLine(YELLOW_FONT_COLOR_CODE..string.format(WEEKLY_REWARDS_ITEM_LEVEL_RAID, itemLevel, currentDifficultyName)..FONT_COLOR_CODE_CLOSE)
		tooltip:AddLine(" ")

		-- Is an upgrade available?
		if upgradeItemLevel then
			local nextDifficultyID = DifficultyUtil.GetNextPrimaryRaidDifficultyID(currentDifficultyID);

			if nextDifficultyID then
				local difficultyName = DifficultyUtil.GetDifficultyName(nextDifficultyID);

				tooltip:AddLine(GREEN_FONT_COLOR_CODE..string.format(WEEKLY_REWARDS_IMPROVE_ITEM_LEVEL, upgradeItemLevel)..FONT_COLOR_CODE_CLOSE)
				tooltip:AddLine(string.format(WEEKLY_REWARDS_COMPLETE_RAID, difficultyName))
			end
		end

		-- what have we accomplished so far?
		if activity.encounters then
			local instanceIDs = {}
			local encounters = activity.encounters

			-- sort by instance ID, then uiOrder of each boss, then i guess best difficulty?
			local encounterSorter = function(entry1, entry2)
				if ( entry1.instanceID ~= entry2.instanceID) then
					return entry1.instanceID < entry2.instanceID;
				elseif ( entry1.uiOrder ~= entry2.uiOrder) then
					return entry1.uiOrder < entry2.uiOrder;
				else
					return entry1.bestDifficulty > entry2.bestDifficulty;
				end
			end

			table.sort(encounters, encounterSorter);

			-- get unique list of instance IDs
			for _, encounter in pairs(encounters) do
				if not locate(instanceIDs, encounter.instanceID) then
					table.insert(instanceIDs, encounter.instanceID)
				end
			end

			-- loop through the instances
			for _, instanceID in pairs(instanceIDs) do
				local raidName = EJ_GetInstanceInfo(instanceID)

				tooltip:AddLine(" ")
				tooltip:AddLine(raidName.." "..L["Boss List"])
			
				for _, encounter in pairs(encounters) do
					if encounter.instanceID == instanceID then
						local boss = EJ_GetEncounterInfo(encounter.encounterID);

						if encounter.bestDifficulty and encounter.bestDifficulty > 0 then
							local difficultyName = DifficultyUtil.GetDifficultyName(encounter.bestDifficulty);

							tooltip:AddLine(GREEN_FONT_COLOR_CODE..string.format("- %s (%s)", boss, difficultyName)..FONT_COLOR_CODE_CLOSE)
						else
							tooltip:AddLine(GRAY_FONT_COLOR_CODE..string.format("- %s", boss)..FONT_COLOR_CODE_CLOSE)
						end
					end
				end
			end
		end
	end
end

-- Tooltip for cells in the Dungeons columns
local function ShowPreviewActivityReward(tooltip, activity)
	local itemLevel = activity.currentItemLevel
	local upgradeItemLevel = activity.upgradeItemLevel

	tooltip:AddLine(YELLOW_FONT_COLOR_CODE..string.format(WEEKLY_REWARDS_ITEM_LEVEL_MYTHIC, itemLevel, activity.level)..FONT_COLOR_CODE_CLOSE)
	tooltip:AddLine(" ")

	if upgradeItemLevel then
		tooltip:AddLine(GREEN_FONT_COLOR_CODE..string.format(WEEKLY_REWARDS_IMPROVE_ITEM_LEVEL, upgradeItemLevel)..FONT_COLOR_CODE_CLOSE)
		if activity.threshold == 1 then
			tooltip:AddLine(WEEKLY_REWARDS_COMPLETE_MYTHIC_SHORT)
		else
			tooltip:AddLine(string.format(WEEKLY_REWARDS_COMPLETE_MYTHIC, activity.level + 1, activity.threshold))

			local runHistory = C_MythicPlus.GetRunHistory();

			if #runHistory > 0 then
				tooltip:AddLine(" ")
				tooltip:AddLine(string.format(WEEKLY_REWARDS_MYTHIC_TOP_RUNS, activity.threshold))

				table.sort(runHistory, encounterSorter);

				for i = 1, activity.threshold do
					local runInfo = runHistory[i];
					local name = C_ChallengeMode.GetMapUIInfo(runInfo.mapChallengeModeID);
					tooltip:AddLine(string.format(WEEKLY_REWARDS_MYTHIC_RUN_INFO, runInfo.level, name))
				end
			end
		end
	end

end

local function ShowPreviewWorldReward(tooltip, activity)
	local itemLevel = activity.currentItemLevel

	if activity.progress < activity.threshold then -- no reward yet, no upgrade
		if activity.index == 1 then 
			tooltip:AddLine(YELLOW_FONT_COLOR_CODE..string.format(GREAT_VAULT_REWARDS_WORLD_INCOMPLETE, activity.threshold - activity.progress)..FONT_COLOR_CODE_CLOSE)
		elseif activity.index == 2 then 
			tooltip:AddLine(YELLOW_FONT_COLOR_CODE..string.format(GREAT_VAULT_REWARDS_WORLD_COMPLETED_FIRST, activity.threshold - activity.progress)..FONT_COLOR_CODE_CLOSE)
		elseif activity.index == 3 then 
			tooltip:AddLine(YELLOW_FONT_COLOR_CODE..string.format(GREAT_VAULT_REWARDS_WORLD_COMPLETED_SECOND, activity.threshold - activity.progress)..FONT_COLOR_CODE_CLOSE)
		end
	elseif not itemLevel then
		-- for some reason we may not have an item level
		tooltip:AddLine(RED_FONT_COLOR_CODE..RETRIEVING_ITEM_INFO..FONT_COLOR_CODE_CLOSE)
	else
		tooltip:AddLine(YELLOW_FONT_COLOR_CODE..string.format(WEEKLY_REWARDS_ITEM_LEVEL_WORLD, itemLevel, activity.level)..FONT_COLOR_CODE_CLOSE)
		tooltip:AddLine(" ")

		local _, _, nextLevel, upgradeItemLevel = C_WeeklyRewards.GetNextActivitiesIncrease(activity.activityTierID, activity.level)

		if upgradeItemLevel then
			tooltip:AddLine(GREEN_FONT_COLOR_CODE..string.format(WEEKLY_REWARDS_IMPROVE_ITEM_LEVEL, upgradeItemLevel)..FONT_COLOR_CODE_CLOSE)
			
			tooltip:AddLine(string.format(WEEKLY_REWARDS_COMPLETE_WORLD, nextLevel))
		end
	end
end

local function ShowCurrentReward(activity)
	local tooltip = GreatVaultStatus.subTooltip
	local itemLevel = activity.currentItemLevel
	local upgradeItemLevel = activity.upgradeItemLevel

	if LibQTip:IsAcquired("GreatVaultStatusSubTooltip") and tooltip then
		tooltip:Clear()
	else
		tooltip = LibQTip:Acquire("GreatVaultStatusSubTooltip", 1, "LEFT")
		GreatVaultStatus.subTooltip = tooltip
	end

	tooltip:ClearAllPoints()
	tooltip:SetClampedToScreen(true)
	tooltip:SetPoint("TOP", GreatVaultStatus.tooltip, "TOP", 30, 0)
	tooltip:SetPoint("RIGHT", GreatVaultStatus.tooltip, "LEFT", -20, 0)
	
	if activity.progress < activity.threshold then
		tooltip:AddLine(WEEKLY_REWARDS_UNLOCK_REWARD) 
	else
		tooltip:AddLine(WEEKLY_REWARDS_CURRENT_REWARD) 
	end

	if activity.type == Enum.WeeklyRewardChestThresholdType.Raid then
		ShowPreviewRaidReward(tooltip, activity)
	elseif activity.type == Enum.WeeklyRewardChestThresholdType.Activities then
		ShowPreviewActivityReward(tooltip, activity)
	elseif activity.type == Enum.WeeklyRewardChestThresholdType.World then
		ShowPreviewWorldReward(tooltip, activity)
	end

	if itemLevel and not upgradeItemLevel then
		-- WEEKLY_REWARDS_MAXED_REWARD = "Reward at Highest Item Level"
		tooltip:AddLine(GREEN_FONT_COLOR_CODE..WEEKLY_REWARDS_MAXED_REWARD..FONT_COLOR_CODE_CLOSE)
	end
	
	tooltip:Show()
end

function GreatVaultStatus:ShowSubTooltip(cell, info)
	ShowCurrentReward(info)
end

local function HasCompletedActivities(status)
	local completed = status and status.hasAvailableRewards

	if not completed and status and status.activities and status.lastUpdated and (status.lastUpdated < GetWeeklyQuestResetTime() - 604800) then
		for index =1, 3 do
			local activities = status.activities[index] or {}

			for _, activity in ipairs(activities) do
				if activity.progress >= activity.threshold then
					completed = true
					break
				end
			end	
		end
	end

	return completed
end


local function ShowCharacter(tooltip, name, info)
	if not info then
		return
	end

	local factionIcon = ""
	local line = tooltip:AddLine()
	local activities = info.status.activities
	local lastUpdated = info.status.lastUpdated

	if info.faction and info.faction == "Alliance" then
		factionIcon = textures.alliance
	elseif info.faction and info.faction == "Horde" then
		factionIcon = textures.horde
	end

	tooltip:SetCell(line, COL_CHARACTER, factionIcon.." "..name)

	if info.averageItemLevel then
		tooltip:SetCell(line, COL_ITEMLEVEL, string.format("%.1f", info.averageItemLevel), "RIGHT")
	end

	if activities then 
		ShowActivities(tooltip, line, COL_RAIDS, activities[Enum.WeeklyRewardChestThresholdType.Raid], lastUpdated, 0, 10)
		ShowActivities(tooltip, line, COL_ACTIVITIES, activities[Enum.WeeklyRewardChestThresholdType.Activities], lastUpdated, 10, 10)
		ShowActivities(tooltip, line, COL_WORLD, activities[Enum.WeeklyRewardChestThresholdType.World], lastUpdated, 10, 0)
	end

	if HasCompletedActivities(info.status) then
		tooltip:SetCell(line, COL_REWARDS, textures.reward)
	end

	if info.class then
		local color = RAID_CLASS_COLORS[info.class]
		tooltip:SetCellTextColor(line, COL_CHARACTER, color.r, color.g, color.b)
	end

	return line
end

local function ShowHeader(tooltip, marker, headerName)
	line = tooltip:AddHeader()

	tooltip:SetCell(line, COL_CHARACTER, L["Character"], nil, "LEFT", nil, nil, nil, 50)
	tooltip:SetCellTextColor(line, COL_CHARACTER, yellow.r, yellow.g, yellow.b)
	tooltip:SetCell(line, COL_ITEMLEVEL, L["iLevel"], nil, "RIGHT")
	tooltip:SetCellTextColor(line, COL_ITEMLEVEL, yellow.r, yellow.g, yellow.b)
	tooltip:SetCell(line, COL_RAIDS, L["Raids"], nil, "CENTER", 3)
	tooltip:SetCellTextColor(line, COL_RAIDS, yellow.r, yellow.g, yellow.b)
	tooltip:SetCell(line, COL_ACTIVITIES, L["Dungeons"], nil, "CENTER", 3)
	tooltip:SetCellTextColor(line, COL_ACTIVITIES, yellow.r, yellow.g, yellow.b)
	tooltip:SetCell(line, COL_WORLD, L["World"], nil, "CENTER", 3)
	tooltip:SetCellTextColor(line, COL_WORLD, yellow.r, yellow.g, yellow.b)

	tooltip:SetCellScript(line, COL_CHARACTER, "OnMouseUp", HeaderOnClick, COL_CHARACTER)
	tooltip:SetCellScript(line, COL_ITEMLEVEL, "OnMouseUp", HeaderOnClick, COL_ITEMLEVEL)

	return line
end



local function ShowRealm(tooltip, name, info)
	local collapsed = info.collapsed
	local characters = {}
	local line = tooltip:AddHeader()
	local button = "|TInterface\\Buttons\\UI-MinusButton-Up:16|t"

	if collapsed then
		button = "|TInterface\\Buttons\\UI-PlusButton-Up:16|t"
	end

	if not showSingleRealm then
		tooltip:SetCell(line, 1, button)
		tooltip:SetCellScript(line, 1, "OnMouseUp", RealmOnClick, name)

		tooltip:SetCell(line, 2, name, nil, nil, nil, nil, nil, 50)
		tooltip:SetCellTextColor(line, 2, yellow.r, yellow.g, yellow.b)
	end

	if not collapsed or showSingleRealm then	
		for key, value in pairs(info.characters) do
			table.insert(characters, value);
		end
	
		table.sort(characters, SortCharacters)

		for characterName, characterInfo in pairs(characters) do
			line = ShowCharacter(tooltip, characterInfo.name, characterInfo)

			if name == GetRealmName() and characterInfo.name == GetUnitName("Player") then
				tooltip:SetLineColor(line, yellow.r, yellow.g, yellow.b, 0.2)
			end

		end

		tooltip:AddSeparator(6,0,0,0,0)
	end
end

function GreatVaultStatus:ShowToolTip()
	local tooltip = GreatVaultStatus.tooltip
	local columns = 13	

	self:SaveCharacterInfo()

	if showSingleRealm then
		columns = 12
	end

	if LibQTip:IsAcquired("GreatVaultStatusTooltip") and tooltip then
		tooltip:Clear()
	else
		tooltip = LibQTip:Acquire("GreatVaultStatusTooltip", columns)
		GreatVaultStatus.tooltip = tooltip
	end

	local line = tooltip:AddHeader(" ")

	tooltip:SetCell(line, 1, "|T"..textures.GreatVaultStatus..":18|t "..L["Great Vault Status"], nil, "LEFT", columns)
	tooltip:AddSeparator(6,0,0,0,0)

	ShowHeader(tooltip, nil, nil)

	for key, value in pairs(self.db.global.realms or {}) do
		tooltip:AddSeparator(3,0,0,0,0)
		ShowRealm(tooltip, key, value)
	end

	if (frame) then
		tooltip:SetAutoHideDelay(0.01, frame)
		tooltip:SmartAnchorTo(frame)
	end

	tooltip:UpdateScrolling()
	tooltip:Show()
end

function GreatVaultStatus:GetRealmInfo(realmName)
	if not self.db.global.realms then
		self.db.global.realms = {}
	end

	local realmInfo = self.db.global.realms[realmName]

	if not realmInfo then
		realmInfo = {}
		realmInfo.characters = {}
	end

	return realmInfo
end

local function GetActivities(activityType)
	local activities = C_WeeklyRewards.GetActivities(activityType);

	table.sort(activities, function(a,b) return a.index < b.index end)

	for _,activity in pairs(activities) do
		if activity.progress >= activity.threshold then			
			local encounterInfo = C_WeeklyRewards.GetActivityEncounterInfo(activityType, activity.index);
			local currentLink, upgradeLink = C_WeeklyRewards.GetExampleRewardItemHyperlinks(activity.id);

			if encounterInfo then
				activity.encounters = encounterInfo
			end

			if currentLink then
				activity.currentItemLevel = C_Item.GetDetailedItemLevelInfo(currentLink);
			end

			if upgradeLink then
				activity.upgradeItemLevel = C_Item.GetDetailedItemLevelInfo(upgradeLink);
			end
		end
	end

	return activities
end

local function UpdateStatusForCharacter(currentStatus)
	local now = time()
	local status = currentStatus or {}

	status.lastUpdated = now
	status.activities = {}
	status.activities[Enum.WeeklyRewardChestThresholdType.Raid] = GetActivities(Enum.WeeklyRewardChestThresholdType.Raid)
	status.activities[Enum.WeeklyRewardChestThresholdType.Activities] = GetActivities(Enum.WeeklyRewardChestThresholdType.Activities)
	status.activities[Enum.WeeklyRewardChestThresholdType.World] = GetActivities(Enum.WeeklyRewardChestThresholdType.World)
	status.hasAvailableRewards = C_WeeklyRewards.HasAvailableRewards();

	return status
end

function GreatVaultStatus:SaveCharacterInfo(info)
	if UnitLevel("player") < 60 then
		return
	end

	local characterInfo = info or self:GetCharacterInfo()
	local characterName = UnitName("player")
	local realmName = GetRealmName()
	local realmInfo = self:GetRealmInfo(realmName)

	realmInfo.characters[characterName]  = characterInfo
	self.db.global.realms[realmName] = realmInfo
end

function GreatVaultStatus:GetCharacterInfo()
	local name = UnitName("player")
	local realmInfo = GreatVaultStatus:GetRealmInfo(GetRealmName())
	local characterInfo = realmInfo.characters[name] or {}
	local _, className = UnitClass("player")

	characterInfo.name = name
	characterInfo.lastUpdate = time()
	characterInfo.class = className
	characterInfo.level = UnitLevel("player")
	characterInfo.averageItemLevel = GetAverageItemLevel();
	characterInfo.faction = UnitFactionGroup("player")
	characterInfo.status = UpdateStatusForCharacter(characterInfo.status)

	return characterInfo
end

local function UpdateStatus()
	GreatVaultStatus:SaveCharacterInfo()
end

function GreatVaultStatus:PLAYER_ENTERING_WORLD(event, isLogin, isReload)
	if isLogin or isReload then
		self:ScheduleTimer(UpdateStatus, 10)
	end
end

function GreatVaultStatus:WEEKLY_REWARDS_UPDATE(event)
	--self:Print(event)
	self:SaveCharacterInfo()
end

function GreatVaultStatus:WEEKLY_REWARDS_ITEM_CHANGED(event)
	--self:Print(event)
	self:SaveCharacterInfo()
end

function GreatVaultStatus:OnEnable()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("WEEKLY_REWARDS_UPDATE")
	self:RegisterEvent("WEEKLY_REWARDS_ITEM_CHANGED")
end

function GreatVaultStatus:OnDisable()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("WEEKLY_REWARDS_UPDATE")
	self:UnregisterEvent("WEEKLY_REWARDS_ITEM_CHANGED")
end
