---------- Required Modules -----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local PlayerDataService = nil
local Types = require(ReplicatedStorage.Common.Types)
local Players = game:GetService("Players")
local Trove = require(ReplicatedStorage.Packages.Trove)
local RunService = game:GetService("RunService")
local Data = require(Knit.Config.Data)

---------- Module Instance ------------

local PassiveExperience = {}

local TIME_REQUIRED = Data.PASSIVE_XP_TIME --time, in seconds, to recieve passive xp
local XP_AMOUNT = Data.PASSIVE_XP_AMOUNT

---------- Private functions ----------

function PassiveExperience:_listenForPlayerJoining()
	for _, plr: Player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			local profile: Types.PlayerProfile = PlayerDataService:GetPlayerProfileDataAsync(plr)

			if
				profile.Rank >= Data.E_RANK_RANGE.Min and profile.Rank <= Data.E_RANK_RANGE.Max
				or RunService:IsStudio()
			then
				self.TrackedPlayers[plr] = profile
			end
		end)
	end

	Players.PlayerAdded:Connect(function(plr: Player)
		local profile: Types.PlayerProfile = PlayerDataService:GetPlayerProfileDataAsync(plr)

		if profile.Rank >= Data.E_RANK_RANGE.Min and profile.Rank <= Data.E_RANK_RANGE.Max or RunService:IsStudio() then
			self.TrackedPlayers[plr] = profile
		end
	end)
end

function PassiveExperience:_trackTime()
	local trove = Trove.new()

	trove:Add(RunService.Heartbeat:Connect(function(dt: number)
		for plr: Player, _: number in pairs(self.TrackedPlayers) do
			if PlayerDataService:IsProfileActive(plr) then
				self.TrackedPlayers[plr].TimeTracker += dt

				if self.TrackedPlayers[plr].TimeTracker >= TIME_REQUIRED then
					print("PASIVE XP!", plr, XP_AMOUNT)
					PlayerDataService.Bindable.AwardExp:Fire(plr, XP_AMOUNT)
					self.TrackedPlayers[plr].TimeTracker -= TIME_REQUIRED
				end
			end
		end
	end))
end

function PassiveExperience:_listenForPlayerLeaving()
	Players.PlayerRemoving:Connect(function(plr: Player)
		self.TrackedPlayers[plr] = nil
	end)
end

---------- Public functions -----------

---------- Utility functions ----------

function PassiveExperience:Init(playerDataService)
	PlayerDataService = playerDataService

	self.TrackedPlayers = {}

	self:_listenForPlayerJoining()
	self:_trackTime()
	self:_listenForPlayerLeaving()
end

return PassiveExperience
