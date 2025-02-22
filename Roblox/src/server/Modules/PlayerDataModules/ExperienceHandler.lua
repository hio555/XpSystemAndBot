---------- Required Modules -----------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local PlayerDataService = nil
local Types = require(ReplicatedStorage.Common.Types)
local GroupInfo = nil
local GroupService = game:GetService("GroupService")
local RunService = game:GetService("RunService")
local BotService = nil
local Data = require(Knit.Config.Data)

---------- Module Instance ------------

--These events accessible through player data service
local ExperienceHandler = {
	Bindable = {
		GiveExp = Instance.new("BindableEvent"), --should probably be remote event
		PlayerLevelUp = Instance.new("BindableEvent"),
	},
}

local ADMIN_LIST = Data.ADMIN_LIST
local EXP_LEVELS = Data.EXP_LEVELS
local MAX_RANK = Data.E_RANK_RANGE.Max --maximum rank a non-officer/staff can be
local MIN_STAFF_RANK = Data.O_RANK_RANGE.Min --Ranks above this are allowed to give xp
local MAX_STAFF_RANK = Data.O_RANK_RANGE.Max

local GROUP_ID = Data.GROUP_ID

---------- Private functions ----------

function ExperienceHandler:_checkForLevelUp(plr: Player, profile: Types.PlayerProfile): boolean
	if profile.Rank < MAX_RANK and profile.Experience >= EXP_LEVELS[profile.Rank + 1] then
		profile.Rank += 1

		while profile.Rank < MAX_RANK and profile.Experience >= EXP_LEVELS[profile.Rank + 1] do
			profile.Rank += 1
		end

		--notify the server
		ExperienceHandler.Bindable.PlayerLevelUp:Fire(plr, profile.Rank)

		print(plr.Name, " leveled up! New rank: ", profile.Rank)

		if BotService == nil then
			BotService = Knit.GetService("BotService")
		end

		BotService:ChangeRank(plr, profile.Rank)

		return true
	end

	return false
end

function ExperienceHandler:_awardExp(plr: Player, amount: number)
	assert(plr:IsA("Player"), "Cannot give exp to non players!")
	assert(typeof(amount) == "number", "Must give a number value for exp")

	local profile: Types.PlayerProfile = PlayerDataService:GetPlayerProfileDataAsync(plr)

	if profile == nil then
		error("[ERROR] Player profile not loaded, unable to give exp")
		return
	end

	if profile.Rank <= 0 then
		if RunService:IsStudio() == true then
			profile.Rank = 1 --for development purposees
		else
			return --players not in the group cannot earn exp
		end
	end

	profile.Experience += amount

	local didLevelUp: boolean = ExperienceHandler:_checkForLevelUp(plr, profile)
	local data: Types.ExpNotification = {
		profile.Rank,
		profile.Experience,
		didLevelUp,
		amount,
	}

	print("Awarded exp", data)

	PlayerDataService.Client.NotifyPlayerOfExpChange:Fire(plr, data)
end

function ExperienceHandler:_staffExpTransaction(plr: Player, data: Types.StaffExpTransaction)
	local staffProfile: Types.PlayerProfile = PlayerDataService:GetPlayerProfileDataAsync(plr)
	local recipientProfile: Types.PlayerProfile = PlayerDataService:GetPlayerProfileDataAsync(data.Recipient)

	if
		staffProfile.Rank >= MIN_STAFF_RANK and staffProfile.Rank <= MAX_STAFF_RANK
		or table.find(ADMIN_LIST, plr.UserId) ~= nil
		or plr.UserId < 0 --for local server testing
		or table.find(Data.STAFF_RANKS, staffProfile.Rank) ~= nil
	then
		--Server side check to prevent exploits
		if os.time() - staffProfile.OfficerAwardXPTimestamp >= Data.XP_AWARD_COOLDOWN then
			print("Staff gave player exp!", data.Recipient, data.Amount)
			ExperienceHandler:_awardExp(data.Recipient, data.Amount)
			staffProfile.OfficerAwardXPTimestamp = os.time()

			if BotService == nil then
				BotService = Knit.GetService("BotService")
			end

			BotService:LogExpTransaction(plr, data.Recipient, data.Amount, recipientProfile.Experience)
		else
			warn(
				plr.Name .. " is on XP awarding cooldown. Time remaining: ",
				Data.XP_AWARD_COOLDOWN - (os.time() - staffProfile.OfficerAwardXPTimestamp)
			)
		end
	else
		warn(plr.Name .. " is not authorized to give xp")
	end
end

---------- Listener functions ----------

--[[
	No need to clean up any of these signals, these should always be active
]]

function ExperienceHandler:_listenForAwardExp()
	PlayerDataService.Bindable.AwardExp.Event:Connect(function(plr: Player, amount: number)
		ExperienceHandler:_awardExp(plr, amount)
	end)
end

function ExperienceHandler:_listenForStaffExpTransaction()
	PlayerDataService.Client.StaffAwardsExp:Connect(function(plr: Player, data: Types.StaffExpTransaction)
		ExperienceHandler:_staffExpTransaction(plr, data)
	end)
end

---------- Public functions -----------

---------- Utility functions ----------

--[[
	Singleton
]]
function ExperienceHandler:Init(myPlayerDataService)
	PlayerDataService = myPlayerDataService

	ExperienceHandler:_listenForAwardExp()
	ExperienceHandler:_listenForStaffExpTransaction()

	--Print all available roles:
	-- task.spawn(function()
	-- 	GroupInfo = GroupService:GetGroupInfoAsync(Data.GROUP_ID)

	-- 	print(GroupInfo.Name .. " has the following roles:")
	-- 	for _, role in ipairs(GroupInfo.Roles) do
	-- 		print("Rank " .. role.Rank .. ": " .. role.Name)
	-- 	end
	-- end)
end

return ExperienceHandler
