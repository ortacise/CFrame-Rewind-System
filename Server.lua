local Players = game:GetService("Players")
local Server = {}

function Server.Rewind(char)
	script.Parent.Action:FireClient(Players:GetPlayerFromCharacter(char), "Rewind", char)
end

script.Parent:WaitForChild("Action").OnServerEvent:Connect(function(plr, action, ...)
	if action == "Rewind" then
		Server.Rewind(plr.Character)
	end
end)

return Server
