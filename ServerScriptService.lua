--// Main Connector Client //--
game.ReplicatedStorage.Remotes.HandlerFireClient.OnServerEvent:Connect(function(plr,Module,Action,...)
	if Module ~= nil and Action ~= nil then
		game.ReplicatedStorage.Remotes.HandlerFireClient:FireAllClients(Module,Action,...)
	end
end)

--// Main Connector Server //--
local Modules = {
	["FrameWork"] = require(game.ReplicatedStorage.Modules:WaitForChild("FrameWorkServer")),
}

game.ReplicatedStorage.Remotes.HandlerFireServer.OnServerEvent:Connect(function(plr,Module,Action,...)
	if Modules[Module] ~= nil then
		Modules[Module][Action](...)
	end
end)

--// Plr Data //--
game.Players.PlayerAdded:Connect(function(plr)
	for i,v in pairs(game.Players:GetChildren()) do
		if v:IsA("Player") and v.Name ~= plr.Name then
			game.ReplicatedStorage.Remotes.HandlerFireClient:FireClient(plr,"FrameWork","SwordSpawn",v)
		end
	end
	game.ReplicatedStorage.Remotes.HandlerFireClient:FireAllClients("FrameWork","SwordSpawn",plr)
	for i,v in pairs(script:GetChildren()) do
		if v:IsA("Configuration") then
			local newFold = v:Clone()
			newFold.Name = plr.Name.."Data"
			if game.ReplicatedStorage:WaitForChild("PlayersData") ~= nil then
				newFold.Parent = game.ReplicatedStorage.PlayersData
			else
				newFold.Parent = game.Players:WaitForChild(plr.Name)
			end
		end
	end
	plr.CharacterAdded:Connect(function(charModel)
		charModel:WaitForChild("Humanoid").Died:Connect(function()
			plr.CharacterAdded:Wait()
			--// Respawned
			game.ReplicatedStorage.Remotes.HandlerFireClient:FireAllClients("FrameWork","SwordSpawn",plr)
		end)
	end)
end)

game.ReplicatedStorage.Remotes.GetVal.OnServerInvoke = function(plr,Val,Type,AttributeName)
	if plr ~= nil and Val ~= nil then
		if Type == "Value" then
			return Val.Value
		elseif Type == "Name" then
			return Val.Name
		elseif Type == "Attribute" and AttributeName ~= nil then
			return Val:GetAttribute(AttributeName)
		end
	end
end

------------------////////////////////-------------------------------------------------------------------------///////////////////////------------------------

--// Collission
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local playerCollisionGroupName = "Players"
PhysicsService:CreateCollisionGroup(playerCollisionGroupName)
PhysicsService:CollisionGroupSetCollidable(playerCollisionGroupName, playerCollisionGroupName, false)

local previousCollisionGroups = {}

local function setCollisionGroup(object)
	if object:IsA("BasePart") then
		previousCollisionGroups[object] = object.CollisionGroupId
		PhysicsService:SetPartCollisionGroup(object, playerCollisionGroupName)
	end
end

local function setCollisionGroupRecursive(object)
	setCollisionGroup(object)

	for _, child in ipairs(object:GetChildren()) do
		setCollisionGroupRecursive(child)
	end
end

local function resetCollisionGroup(object)
	local previousCollisionGroupId = previousCollisionGroups[object]
	if not previousCollisionGroupId then return end 

	local previousCollisionGroupName = PhysicsService:GetCollisionGroupName(previousCollisionGroupId)
	if not previousCollisionGroupName then return end

	PhysicsService:SetPartCollisionGroup(object, previousCollisionGroupName)
	previousCollisionGroups[object] = nil
end

local function onCharacterAdded(character)
	setCollisionGroupRecursive(character)

	character.DescendantAdded:Connect(setCollisionGroup)
	character.DescendantRemoving:Connect(resetCollisionGroup)
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(onCharacterAdded)
end

Players.PlayerAdded:Connect(onPlayerAdded)
