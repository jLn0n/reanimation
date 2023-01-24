-- services
local inputService = game:GetService("UserInputService")
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local starterGui = game:GetService("StarterGui")
-- objects
local player = players.LocalPlayer
local character = player.Character
local humanoid, rootPart =
	character:FindFirstChildWhichIsA("Humanoid"),
	character:FindFirstChild("HumanoidRootPart")
local fRootPart
local resetBindable = Instance.new("BindableEvent")
-- variables
_G.Connections = (_G.Connections or table.create(16))
local dummyCharacter = game:GetObjects("rbxassetid://6843243348")[1]
local flingStatus = {
	enabled = false,
	positionModified = false,
	currentPartPosition = Vector3.zero,
}
-- functions
local function checkValue(value, defaultValue)
	if typeof(value) == typeof(defaultValue) then
		return value
	else
		return defaultValue
	end
end

local function unpackOrientation(vectRot, dontUseRadians)
	vectRot = (not dontUseRadians and vectRot * (math.pi / 180) or vectRot)
	return vectRot.X, vectRot.Y, (typeof(vectRot) == "Vector2" and 0 or vectRot.Z)
end

local function weldPart(part, parent, position, orientation)
	if not (part or parent) then return end
	part = (part and part:IsA("Accessory")) and part.Handle or part
	parent = (parent and parent:IsA("Accessory")) and parent.Handle or parent
	position, orientation = (position or Vector3.zero), (orientation or Vector3.zero)

	local attachment = Instance.new("Attachment")
	attachment.Name = "Offset"
	attachment.CFrame = ((CFrame.identity + position) * CFrame.Angles(unpackOrientation(orientation)))

	local alignPos, alignOrt = Instance.new("AlignPosition"), Instance.new("AlignOrientation")
	local _attachment = Instance.new("Attachment")
	alignPos.ApplyAtCenterOfMass = true
	alignPos.MaxForce, alignOrt.MaxTorque = 9e9, math.huge
	alignPos.MaxVelocity, alignOrt.MaxAngularVelocity = math.huge, math.huge
	alignPos.ReactionForceEnabled, alignOrt.ReactionTorqueEnabled = false, false
	alignPos.Responsiveness, alignOrt.Responsiveness = 200, 200
	alignPos.RigidityEnabled, alignOrt.RigidityEnabled = false, false
	alignPos.Attachment0, alignOrt.Attachment0 = _attachment, _attachment
	alignPos.Attachment1, alignOrt.Attachment1 = attachment, attachment
	alignPos.Parent, alignOrt.Parent = parent, parent
	attachment.Parent, _attachment.Parent = parent, part
end

local function getBasePart(object)
	if not object then return end
	return (
		(object:IsA("BasePart") and object) or
		((object:IsA("Accessory") and object:FindFirstChild("Handle")) and object.Handle) or
		nil
	)
end

local function toggleRootPart(value)
	local alignPos, alignOrt =
		fRootPart:FindFirstChildWhichIsA("AlignPosition"),
		fRootPart:FindFirstChildWhichIsA("AlignOrientation")
	alignPos.Enabled, alignOrt.Enabled = value, value

	rootPart.RotVelocity = Vector3.zero
end

local function killReanimation()
	for _, connection in ipairs(_G.Connections) do connection:Disconnect() end table.clear(_G.Connections)
	player.Character = dummyCharacter
	player.Character = character
	dummyCharacter:Destroy()
	shared.reanimationCharacter = nil
end
-- pre-initialization
assert(character.Name ~= string.format("%s-reanimation", player.UserId), string.format([[["r6-permadeath.lua"]: Please reset to be able to run the script again]]))
assert(humanoid.RigType == Enum.HumanoidRigType.R6, string.format([[["r6-permadeath.lua"]: Sorry, This script will only work on R6 character rig]]))

local configuration do
	local loadedConfig = ...
	local isATable = (typeof(loadedConfig) == "table")
	loadedConfig = (isATable and loadedConfig or table.create(0))

	if not isATable then warn("[r6-permadeath.lua]: No configuration provided, loading default...") end

	loadedConfig.Velocity = checkValue(loadedConfig.Velocity, Vector3.xAxis * -30.05)
	loadedConfig.UseBuiltinNetless = checkValue(loadedConfig.UseBuiltinNetless, true)

	configuration = loadedConfig
end

local reanimationAPI do
	local reanimationAPI_ORIG = {}

	function reanimationAPI_ORIG.SetFlingPartPosition(position)
		if not position then
			flingStatus.positionModified = false
		else
			flingStatus.positionModified = true
			position = (
				(typeof(position) == "Vector3" and position) or
				(typeof(position) == "CFrame" and position.Position)
			)
			flingStatus.currentPartPosition = position
		end
	end

	reanimationAPI = setmetatable(table.create(0), {
		__index = function(_, index)
			if index == "IsReanimated" then
				return (shared.reanimationCharacter and shared.reanimationCharacter:IsDescendantOf(workspace))
			elseif index == "FlingEnabled" then
				return flingStatus.enabled
			end
			return rawget(reanimationAPI_ORIG, index)
		end,
		__newindex = function(_, index, value)
			if index == "FlingEnabled" then
				toggleRootPart(not value)
				flingStatus.enabled = value
				flingStatus.positionModified = false -- resets back
			end
		end
	})
end

for _, connection in ipairs(_G.Connections) do connection:Disconnect() end;table.clear(_G.Connections)
-- main
dummyCharacter.Name = string.format("%s-reanimation", player.UserId)
for _, object in ipairs(dummyCharacter:GetChildren()) do if object:IsA("BasePart") then object.Transparency = 1 end end
do -- reanimate initialization
	local oldCharacterPos = character:GetPivot()
	local oldResetPlayerGuiOnSpawnValue = starterGui.ResetPlayerGuiOnSpawn

	starterGui.ResetPlayerGuiOnSpawn = false
	rootPart.Anchored = true
	player.Character = nil
	player.Character = character
	starterGui.ResetPlayerGuiOnSpawn = oldResetPlayerGuiOnSpawnValue
	task.wait(players.RespawnTime + .05)
	dummyCharacter.Parent = workspace
	shared.reanimationCharacter = dummyCharacter
	fRootPart = dummyCharacter.HumanoidRootPart

	for _, object in ipairs(character:GetChildren()) do
		local objPart = getBasePart(object)
		if not objPart then continue end

		objPart:ApplyAngularImpulse(Vector3.zero)
		objPart:ApplyImpulse(configuration.Velocity)
		sethiddenproperty(objPart, "NetworkOwnershipRule", Enum.NetworkOwnership.Manual)

		objPart.RootPriority = 127
		objPart.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
		objPart.Massless = true

		if object:IsA("BasePart") then
			local dummyCharacterPart = dummyCharacter:FindFirstChild(object.Name)
			weldPart(object, dummyCharacterPart)
		elseif object:IsA("Accessory") and object.Handle then
			local accessoryClone = object:Clone()
			local origAccessoryHandle, accessoryHandle = object:FindFirstChild("Handle"), accessoryClone:FindFirstChild("Handle")
			local origAccessoryWeld, accessoryWeld = object:FindFirstChildWhichIsA("Weld", true), accessoryClone:FindFirstChildWhichIsA("Weld", true)

			accessoryClone.Parent = dummyCharacter
			accessoryHandle.Transparency = 1
			accessoryWeld.Part1 = dummyCharacter:FindFirstChild(origAccessoryWeld.Part1.Name) or fRootPart
			weldPart(origAccessoryHandle, accessoryHandle)
		end
	end

	local animScript, plrFace = character.Animate:Clone(), character.Head.face:Clone()
	humanoid.Animator:Clone().Parent = dummyCharacter.Humanoid
	animScript.Parent = dummyCharacter
	animScript.RunContext = Enum.RunContext.Client
	animScript.Enabled = false
	animScript.Enabled = true
	plrFace.Transparency = 1
	plrFace.Parent = dummyCharacter.Head

	character:BreakJoints()
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	dummyCharacter:PivotTo(oldCharacterPos)
	rootPart.Anchored = false
	toggleRootPart(not flingStatus.enabled)

	if not shared.reanimationHooksInitialized then
		local __index
		__index = hookmetamethod(game, "__index", newcclosure(function(self, index)
			if checkcaller() and (shared.reanimationCharacter and shared.reanimationCharacter:IsDescendantOf(workspace)) then
				if self == player and (index == "Character" or index == "character") then
					return shared.reanimationCharacter
				end
			end
			return __index(self, index)
		end))
		shared.reanimationHooksInitialized = true
	end

	table.insert(_G.Connections, player.CharacterRemoving:Connect(killReanimation))
	starterGui:SetCore("SendNotification", {
		Title = "[r6-permadeath.lua]",
		Text = "r6-permadeath.lua is now ready!\nThanks for using the script!\n",
		Cooldown = 2.5
	})
end

if configuration.UseBuiltinNetless then
	settings().Physics.AllowSleep = false
	settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
	settings().Rendering.EagerBulkExecution = true
	settings().Physics.ForceCSGv2 = false
	settings().Physics.DisableCSGv2 = true
	settings().Physics.UseCSGv2 = false

	player.ReplicationFocus = workspace

	sethiddenproperty(workspace, "PhysicsSteppingMethod", Enum.PhysicsSteppingMethod.Fixed)
	sethiddenproperty(workspace, "InterpolationThrottling", Enum.InterpolationThrottlingMode.Disabled)
	sethiddenproperty(workspace, "HumanoidOnlySetCollisionsOnStateChange", Enum.HumanoidOnlySetCollisionsOnStateChange.Disabled)
	sethiddenproperty(humanoid, "InternalBodyScale", (Vector3.one * 9e99))
	sethiddenproperty(humanoid, "InternalHeadScale", 9e99)

	table.insert(_G.Connections, runService.Heartbeat:Connect(function()
		for _, object in ipairs(character:GetChildren()) do
			local objectName = object.Name
			object = getBasePart(object)
			local cloneObj = getBasePart(dummyCharacter:FindFirstChild(objectName))
			if (not object or not cloneObj) then continue end

			sethiddenproperty(object, "NetworkIsSleeping", false)
			if (object == rootPart and flingStatus.enabled) then return end
			object.Velocity, object.RotVelocity = configuration.Velocity, Vector3.zero
			if (
				not isnetworkowner(object) and
				(fRootPart.Position - object.Position).Magnitude <= 20
			) then -- tries to reclaim the part
				object.CFrame = cloneObj.CFrame
			end
		end
	end))
end

table.insert(_G.Connections, runService.Heartbeat:Connect(function()
	workspace.CurrentCamera.CameraSubject = dummyCharacter.Humanoid
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	dummyCharacter.Humanoid:Move(humanoid.MoveDirection)
	if inputService:IsKeyDown(Enum.KeyCode.Space) and not inputService:GetFocusedTextBox() then
		dummyCharacter.Humanoid.Jump = true
	end
	if flingStatus.enabled then
		local vX, vY, vZ = math.random(-1, 1), math.random(-1, 1), math.random(-1, 1)
		rootPart.Position = (flingStatus.positionModified and flingStatus.currentPartPosition or fRootPart.Position)
		rootPart.RotVelocity = Vector3.new(vX, vY, vZ) * 1e5
	end
	if fRootPart.Position.Y <= workspace.FallenPartsDestroyHeight then
		return resetBindable:Fire()
	end

	for _, object in ipairs(character:GetChildren()) do
		object = getBasePart(object)
		if not object then continue end
		object.LocalTransparencyModifier = dummyCharacter.Head.LocalTransparencyModifier
	end
end))

table.insert(_G.Connections, runService.Stepped:Connect(function()
	for _, object in ipairs(character:GetChildren()) do
		if not object:IsA("BasePart") then continue end
		object.CanCollide = false
	end
end))

resetBindable.Event:Connect(function()
	starterGui:SetCore("ResetButtonCallback", true)
	resetBindable:Destroy()

	if player.Character == dummyCharacter then
		return killReanimation()
	end
	player.Character:BreakJoints()
end)
starterGui:SetCore("ResetButtonCallback", resetBindable)

return reanimationAPI
