---------- Required Modules -----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local TweenService = game:GetService("TweenService")
local Trove = require(ReplicatedStorage.Packages.Trove)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Data = require(Knit.Config:WaitForChild("Data"))

---------- Module Instance ------------

local XPMenu = {}

local PlayerGui = game.Players.LocalPlayer.PlayerGui
local PlayerDataService = nil
local COOLDOWN = Data.XP_AWARD_COOLDOWN
local ON_SCREEN_POSITION = UDim2.fromScale(0.5, 0.5)
local OFF_SCREEN_POSITION = UDim2.fromScale(0.5, 1.6)

---------- Private functions ----------

function XPMenu:_listenForOpen()
	self.Trove:Connect(self.OpenButton.MouseButton1Click, function()
		if self.IsOpen == false then
			local tween = TweenService:Create(
				self.OuterFrame,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine),
				{ Position = ON_SCREEN_POSITION }
			)

			tween:Play()

			self.Trove:Clean()

			self:_doCooldownInitCheck()
			self:_listenForSearch()
			self:_listenForGiveXP()

			tween.Completed:Wait()
			self:_listenForClose()
			self.IsOpen = true
		end
	end)
end

function XPMenu:_listenForClose()
	self.Trove:Connect(self.ExitButton.MouseButton1Click, function()
		if self.IsOpen == true then
			local tween = TweenService:Create(
				self.OuterFrame,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine),
				{ Position = OFF_SCREEN_POSITION }
			)

			tween:Play()

			self.IsOpen = false
			self.Trove:Clean()
			self.SelectedPlayer = nil

			tween.Completed:Wait()
			self:_listenForOpen()
		end
	end)
end

function XPMenu:_doCooldownInitCheck()
	PlayerDataService:GetXPCooldown(Players.LocalPlayer):andThen(function(cd: number)
		print("CD init Doing init check")
		if os.time() - cd < COOLDOWN then
			print("CD init passed")
			self:_doCooldown(COOLDOWN - (os.time() - cd))
		else
			self.Cooldown = 0
			self.XPButton.Interactable = true
			self.XPButton.Text = self.XPButtonDefaultText
		end
	end)
end

function XPMenu:_doCooldown(cd: number)
	local trove = self.Trove:Extend()

	self.Cooldown = cd
	self.XPButton.Interactable = false

	trove:Connect(RunService.Heartbeat, function(dt: number)
		self.Cooldown -= dt

		self.XPButton.Text = "COOLDOWN: " .. (math.abs(math.ceil(self.Cooldown)))

		if self.Cooldown <= 0 then
			self.Cooldown = 0
			self.XPButton.Interactable = true
			self.XPButton.Text = self.XPButtonDefaultText

			trove:Clean()
		end
	end)
end

function XPMenu:_listenForGiveXP()
	self.Trove:Connect(self.XPButton.MouseButton1Click, function()
		if self.SelectedPlayer ~= nil and self.Cooldown == 0 then
			PlayerDataService.StaffAwardsExp:Fire({ Recipient = self.SelectedPlayer, Amount = 25 })
			self:_doCooldown(COOLDOWN)
		end
	end)
end

function XPMenu:_playerButtonPressed(plr: Player, trove)
	self.PlayerName.Text = "@" .. plr.Name
	self.PlayerPortrait.Image =
		Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)

	local playerNameAlias = self.PlayerName
	local playerPortraitAlias = self.PlayerPortrait

	local cleanupFunction = {}
	function cleanupFunction:Destroy()
		playerNameAlias.Text = "@Player"
		playerPortraitAlias.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
		self.SelectedPlayer = nil
	end

	trove:Add(cleanupFunction)
end

function XPMenu:_getPlayers(pattern: string)
	for _, plr: Player in pairs(Players:GetPlayers()) do
		if #pattern > 0 and string.find(string.lower(plr.DisplayName), string.lower(pattern)) ~= nil then
			if self.DisplayedPlayers[plr.Name] == nil then
				local guiElement = self.PlayerListTemplate:Clone()
				guiElement.PlayerButton.Text = plr.DisplayName

				local buttonTrove = self.Trove:Extend()
				buttonTrove:Add(guiElement)

				buttonTrove:Connect(guiElement.PlayerButton.MouseButton1Click, function()
					self.SelectedPlayer = plr
					self:_playerButtonPressed(plr, buttonTrove)
				end)

				self.DisplayedPlayers[plr.Name] = buttonTrove

				guiElement.Parent = self.NameList
				guiElement.Visible = true
			end
		else
			local buttonTrove = self.DisplayedPlayers[plr.Name]

			if buttonTrove ~= nil then
				buttonTrove:Destroy()
				self.DisplayedPlayers[plr.Name] = nil
			end
		end
	end
end

function XPMenu:_listenForSearch()
	self.Trove:Connect(self.SearchBox.FocusLost, function()
		self:_getPlayers(self.SearchBox.Text)
	end)
end

---------- Public functions -----------

---------- Utility functions ----------

function XPMenu:Init()
	PlayerDataService = Knit.GetService("PlayerDataService")

	self.Trove = Trove.new()
	self.DisplayedPlayers = {}
	self.SelectedPlayer = nil
	self.Cooldown = 0
	self.IsOpen = false

	self.Container = PlayerGui:WaitForChild("RankerGui")
	self.PlayerListTemplate = self.Container:WaitForChild("PlayerListTemplate")
	self.OuterFrame = self.Container:WaitForChild("OuterFrame")

	self.LeftMenu = self.OuterFrame:WaitForChild("LeftMenu")
	self.RightMenu = self.OuterFrame:WaitForChild("RightMenu")
	self.ExitButton = self.OuterFrame:WaitForChild("ExitButton")

	self.SearchBox = self.LeftMenu:WaitForChild("SearchBox")
	self.NameList = self.LeftMenu:WaitForChild("NameList")

	self.PlayerPortrait = self.RightMenu:WaitForChild("PlayerPortrait")
	self.PlayerName = self.RightMenu:WaitForChild("PlayerName")
	self.XPButton = self.RightMenu:WaitForChild("XPButton")
	self.XPButtonDefaultText = self.XPButton.Text

	self.OpenButton = self.Container:WaitForChild("OpenButton")

	PlayerDataService:CanSeeXPMenu(game.Players.LocalPlayer):andThen(function(val)
		if val == true then
			self.OuterFrame.Position = OFF_SCREEN_POSITION
			self.OuterFrame.Visible = true
			self.Container.Enabled = true
			self:_listenForOpen()
		end
	end)
end

return XPMenu
