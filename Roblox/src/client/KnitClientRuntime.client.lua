local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Promise = require(game:GetService("ReplicatedStorage").Packages.Promise)
local Component = require(game:GetService("ReplicatedStorage").Packages.Component)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Knit.Components = script.Parent.Components
Knit.Modules = script.Parent.Modules
Knit.Config = ReplicatedStorage:WaitForChild("Common"):WaitForChild("Config")

Knit.AddControllers(script.Parent.Controllers) --AddServicesDeep will look through subfolders

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

Knit:Start()
	:andThen(function()
		--Equivalent to component.auto

		for _, component in pairs(script.Parent.Components:GetChildren()) do
			if component:IsA("ModuleScript") then
				require(component)
			end
		end

		Knit.ComponentsLoaded = true
		print("Components loaded!")
	end)
	:catch(warn)
