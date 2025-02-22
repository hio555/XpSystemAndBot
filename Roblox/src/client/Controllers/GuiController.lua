---------- Required Modules -----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local XPMenu = require(Knit.Modules.Gui.XPMenu)

---------- Module Instance ------------

local GuiController = Knit.CreateController({
	Name = script.Name,
})

---------- Private functions ----------

---------- Public functions -----------

---------- Utility functions ----------

function GuiController:KnitInit() end

function GuiController:KnitStart()
	XPMenu:Init()
end

return GuiController
