---------- Required Modules -----------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local RunService = game:GetService("RunService")
local ProfileService = require(Knit.Modules.Utility.ProfileService)
local Players = game:GetService("Players")
local Types = require(ReplicatedStorage.Common.Types) -- need direct links like this otherwise intellisense gets upset :(
local ExperienceHandler = require(Knit.Modules.PlayerDataModules.ExperienceHandler)
local PassiveExperience = require(Knit.Modules.PlayerDataModules.PassiveExperience)
local Data = require(Knit.Config.Data)

---------- Module Instance ------------

local PlayerDataService = Knit.CreateService({
	Name = script.Name,
	Bindable = {
		--[[ Events for Experience Handler ]]
		AwardExp = Instance.new("BindableEvent"),
		PlayerLeveledUp = Instance.new("BindableEvent"),
		--[[ Other events... ]]
	},
	Client = {
		--[[ Remotes for Experience Handler ]]
		StaffAwardsExp = Knit.CreateSignal(), --Types.StaffExpTransaction
		NotifyPlayerOfExpChange = Knit.CreateSignal(), --Types.ExpNotification
	},
})

---------- Profile Setup ------------

--Any additions to this should be reflected in the type declaration in ReplicatedStorage.Common.Types
local ProfileTemplate: Types.PlayerProfile = {
	Rank = 0,
	Experience = 0,
	TimeTracker = 0,
	OfficerAwardXPTimestamp = 0,
}

local ProfileStore = nil

if RunService:IsStudio() == true then
	ProfileStore = ProfileService.GetProfileStore("DEV", ProfileTemplate)
else
	ProfileStore = ProfileService.GetProfileStore("PRODUCTION", ProfileTemplate)
end

---------- Client functions ----------

function PlayerDataService.Client:GetXPCooldown(plr: Player): number
	return PlayerDataService:GetPlayerProfileDataAsync(plr).OfficerAwardXPTimestamp
end

function PlayerDataService.Client:CanSeeXPMenu(plr: Player): number
	local rank = PlayerDataService:GetPlayerProfileDataAsync(plr).Rank

	return rank >= Data.O_RANK_RANGE.Min and rank <= Data.O_RANK_RANGE.Max
		or table.find(Data.STAFF_RANKS, rank) ~= nil
		or table.find(Data.ADMIN_LIST, plr.UserId) ~= nil
end

---------- Private functions ----------

function PlayerDataService:_getCurrentRank(plr: Player, profile)
	if RunService:IsStudio() == true then
		profile.Data.Rank = 1
	else
		profile.Data.Rank = plr:GetRankInGroup(Data.GROUP_ID)

		--If the player was promoted outside the game, make sure they have the correct xp needed for their current rank
		if
			Data.EXP_LEVELS[profile.Data.Rank] ~= nil
			and profile.Data.Experience < Data.EXP_LEVELS[profile.Data.Rank]
		then
			profile.Data.Experience = Data.EXP_LEVELS[profile.Data.Rank]
		end
	end
end

function PlayerDataService:_playerAdded(plr: Player)
	local profile = ProfileStore:LoadProfileAsync("Player_" .. plr.UserId)

	if profile ~= nil then
		profile:AddUserId(plr.UserId) -- the eu says we need to do this :) (GDPR compliance)
		profile:Reconcile() --Fill in missing any info stuff from the profile template
		profile:ListenToRelease(function()
			self.Profiles[plr] = nil
			-- The profile could've been loaded on another Roblox server:
			plr:Kick("Player data is invalid! (most likely a roblox server issue, please try rejoining)")
		end)

		if plr:IsDescendantOf(Players) == true then
			--[[ 
			Make sure the player's rank is up to date (it could be changed on the website while the player is not in game)
			This step needs to be done before the profile can be accessed elsewhere
			so systems that use it when the player loads in are have accurate info
			]]
			self:_getCurrentRank(plr, profile)

			self.Profiles[plr] = profile -- A profile has been successfully loaded:(player, profile)
		else
			-- Player left before the profile loaded:
			profile:Release()
		end
	else
		plr:Kick("Error loading player data (most likely a roblox server issue, please try rejoining)")
	end
end

---------- Public functions -----------

--[[
	Returns the data portion of the player profile
 	May block

	This is what you want for general player data manipulation
]]
function PlayerDataService:GetPlayerProfileDataAsync(plr: Player): Types.PlayerProfile?
	return self:GetPlayerProfileAsync(plr).Data
end

--[[
	Returns the ENTIRE player profile
	Blocks until profile is loaded

]]
function PlayerDataService:GetPlayerProfileAsync(player: Player): Types.PlayerProfile
	-- Yields until a Profile linked to a player is loaded or the player leaves
	local profile = self.Profiles[player]
	while profile == nil and player:IsDescendantOf(Players) == true do
		task.wait()
		profile = self.Profiles[player]
	end
	return profile
end

function PlayerDataService:IsProfileActive(plr: Player): boolean
	if self.Profiles[plr] == nil then
		return false
	end

	return self.Profiles[plr]:IsActive()
end

---------- Utility functions ----------

function PlayerDataService:KnitInit()
	self.Profiles = {}

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:_playerAdded(player)
		end)
	end

	Players.PlayerAdded:Connect(function(player)
		self:_playerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(plr: Player)
		local profile = self.Profiles[plr]

		if profile ~= nil then
			profile:Release()
		end
	end)

	ExperienceHandler:Init(self)
	PassiveExperience:Init(self)
end

function PlayerDataService:KnitStart() end

return PlayerDataService
