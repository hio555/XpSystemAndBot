local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Component = require(game:GetService("ReplicatedStorage").Packages.Component)
local Promise = require(game:GetService("ReplicatedStorage").Packages.Promise)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local players = game:GetService("Players")
Knit.ComponentsLoaded = false

function Knit.OnComponentsLoaded()
	if Knit.ComponentsLoaded == true then
		return Promise.resolve()
	end
	return Promise.new(function(resolve, _reject, onCancel)
		local heartbeat
		heartbeat = game:GetService("RunService").Heartbeat:Connect(function()
			if Knit.ComponentsLoaded then
				heartbeat:Disconnect()
				resolve()
			end
		end)
		onCancel(function()
			if heartbeat then
				heartbeat:Disconnect()
			end
		end)
	end)
end

Knit.Modules = script.Parent.Modules
Knit.Components = script.Parent.Components
Knit.Config = ReplicatedStorage.Common.Config

Knit.AddServices(script.Parent.Services) --AddServicesDeep will look through subfolders

--Component.auto was removed...
--https://devforum.roblox.com/t/how-to-get-components-with-knit/1597428/11
Knit:Start()
	:andThen(function()
		--Equivalent to component.auto

		for _, component in pairs(script.Parent.Components:GetChildren()) do
			if component:IsA("ModuleScript") then
				require(component)
			end
		end

		Knit.ComponentsLoaded = true
	end)
	:catch(warn)
