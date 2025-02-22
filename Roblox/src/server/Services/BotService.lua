---------- Required Modules -----------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local HttpService = game:GetService("HttpService")
local SERVER_URL = "https://group-bot.fly.dev/"

---------- Module Instance ------------

local BotService = Knit.CreateService({
	Name = script.Name,
})

local BOT_ENABLED = true --kill switch for sending bot requests
local AUTH_TOKEN =
	"WbfL0VbpuGS1ff0whFzaEVyAu6dfNH4GKQ4LKwK7cKR14MfuF8n1mqtreLAWnvmYJ7E1F7fYuLWZ97p5py7SgYGf1uWLE7HZiFL3izKiuVyir6JHYtbivR56HkrWFibi2rGLwpTXjUjBAUJnfvupdS"

---------- Private functions ----------

function BotService:_serverShutdownBackup()
	--Try to send all remaining requests at once in case of server shutdown
	game:BindToClose(function()
		if #self.PostQueue > 0 then
			self.ServerClosing = true

			local finishedEvent = Instance.new("BindableEvent")
			local remainingRequests = #self.PostQueue

			for _, t in pairs(self.PostQueue) do
				task.spawn(function()
					self:_post(table.unpack(t))

					remainingRequests -= 1
					finishedEvent:Fire()
				end)
			end

			--Keep the server open
			repeat
				finishedEvent.Event:Wait()
			until remainingRequests <= 0
		end
	end)
end

function BotService:_tryPost(endpoint: string, jsonData: string)
	table.insert(self.PostQueue, table.pack(endpoint, jsonData))

	if self.PostActive == false then
		self.PostActive = true

		task.spawn(function()
			print("Doing post", endpoint, jsonData)

			while #self.PostQueue > 0 and self.ServerClosing == false do
				self:_post(table.unpack(table.remove(self.PostQueue, 1)))
				task.wait(1) --wait between requests to prevent flooding
			end

			self.PostActive = false
		end)
	end
end

--[[
    If logging fails, data is accessible in the warn logs.
    See the warnings below for searching:
]]
function BotService:_post(endpoint: string, jsonData: string)
	local success = false
	local response = nil
	local tries = 3

	if self.ServerClosing == true then
		warn(`Server closing, clearing POST queue: {SERVER_URL .. endpoint} {jsonData}`)
	end

	local headers = {
		["Authorization"] = AUTH_TOKEN,
	}

	while tries > 0 and success == false do
		success, response = pcall(function()
			return HttpService:PostAsync(
				SERVER_URL .. endpoint,
				jsonData,
				Enum.HttpContentType.ApplicationJson,
				false,
				headers
			)
		end)

		if success == false then
			task.wait(5) --try again in a few seconds
			tries -= 1
		else
			print("Post success!", endpoint, jsonData)
		end
	end

	if tries <= 0 then
		warn(`Unable to send POST request to: {SERVER_URL .. endpoint} {jsonData} {response}`)
	end
end

---------- Public functions -----------

function BotService:ChangeRank(plr: Player, newRank: number)
	if BOT_ENABLED == true then
		assert(typeof(newRank) == "number", "New rank must be a number!")

		local data = {
			uid = plr.UserId,
			-- uid = 7736685688, --test account
			rank = newRank,
		}

		local jsonData = HttpService:JSONEncode(data)
		local endpoint = "updaterank"

		self:_tryPost(endpoint, jsonData)
	end
end

function BotService:LogExpTransaction(myStaff: Player, myRecipient: Player, expChange: number, myTotalExp: number)
	if BOT_ENABLED == true then
		local data = {
			staff = myStaff.Name,
			recipient = myRecipient.Name,
			amount = expChange,
			totalExp = myTotalExp,
		}

		local jsonData = HttpService:JSONEncode(data)
		local endpoint = "logexp"

		self:_tryPost(endpoint, jsonData)
	end
end

---------- Utility functions ----------

function BotService:KnitInit()
	self.PostQueue = {}
	self.PostActive = false
	self.ServerClosing = false
end

function BotService:KnitStart()
	self:_serverShutdownBackup()
end

return BotService
