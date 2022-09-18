--\\----- [CAMERA SERVICE] -----//--
--[[
    Open-sourced, custom camera system for Roblox experiences.
    Find more ease in implementing beautiful, breath-taking camera effects into your place.

    API:
    > :SetCameraView(__type: string)
    Sets the camera to a certain view, such as first person, shift-lock, or some other.
    Will error if CameraService cannot find the camera view.

    > :CreateNewCameraView(id: string, settingsArray: table)
    Adds a new camera view that the camera can be set to.
    settingsArray should have values for camera view properties as seen below.
    If no value is provided, a default one will be placed within.

    > :LockCameraPanning(xAxis: boolean, yAxis: boolean)
    Locks camera movement from right-to-left (x-axis) or up-down (y-axis)

    > :SetCameraHost(newHost: BasePart)
    Has the camera focus in on the input part. Must be a BASEPART (not a model).
    To reset the host back to the player's character, you can leave the parameters blank.

    > :Change(property: string, val: any, changeDefaultProperty: boolean)
    Properties include:
        "CharacterVisibility" (string): Determines what part of the character is visible.
        when it's the host. "All" shows all parts, "Body" hides the head, & "None" hides the whole body.
        "MinZoom" (number): Determines how close the player can zoom in. In studs.
        "MaxZoom" (number): Determines how far the player can zoom out. In studs.
        "Zoom" (number): The current distance the camera is away from the host.
        "Smoothness" (number): Determines how smooth the camera movement is.
        Intervals from 0-1 are suggested. Intervals higher could be used to create a "cinematic" effect.
        "Offset" (CFrame): Determines the offset/positioning away from the camera host.
        Can be used to simulate shift-lock.
        "LockMouse" (boolean): Has the mouse locked in at the center.
		"AlignChar" (boolean): If set to true, the character will rotate itself based off the camera (highly advised for shift-locks and first person)
		"BodyFollow" (boolean): If AlignChar is NOT enabled, BodyFollow allows for an effect that has the upper body slightly rotate based off the mouse location.

    > :ChangeSensitivity(val: number)
    Changes the rate at which the camera moves. 
    Merely adjusts the UserInputServiceService.MouseDeltaSensitivity property. 
    NOTICE: Players CAN change this themselves manually through the Roblox menu.

    > :ChangeFOV(val: number, instant: boolean)
    Gradually changes the field-of-view of the current camera.
    If you want the change to be instantaneous, add a second parameter marked true. 
    Changing FOV directly with the actual camera object is still possible.

    > :Shake(intensity: number, duration: number) (YIELDING FUNCTION)
    Creates a shaking camera effect in which the screen is, well, shaking. Like an earthquake. 
    Intensity should be a number greater than 0, preferably in the 0-1 range. Duration is in seconds.

    > :Tilt(degree: number)
    Tilts the camera across the z-axis on whatever object it is currently focusing on. 
    Useful for creating camera effects. Input a number in degrees.

    Created by @Lugical | Reased September, 2022
--]]





math.randomseed(tick())
---> Services <---
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

---> Player & Camera Objects <---
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local cam = workspace.CurrentCamera or workspace:WaitForChild("Camera")


---> Camera System Variables <---
local TWEEN_INFO = TweenInfo.new(.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local currentCamPosition = Vector3.zero
local cameraRotation = Vector2.zero
local currentCharacter = player.Character or player.CharacterAdded:Wait()
local offset = CFrame.new()
local updateShake = 0
local delta;
local differenceVector;
local waistCache;
local neckCache;
local cameraSettings = { --> Built-in camera views
	["Default"] = {},
	["FirstPerson"] = {CharacterVisibility = "None", Smoothness = 1, Zoom = 0, AlignChar = true, Offset = CFrame.new(0,0,0), LockMouse = true, MinZoom = 0, MaxZoom = 0, BodyFollow = true},
	["FirstPersonVariant"] = {CharacterVisibility = "Body", Smoothness = .35, Zoom = 0, AlignChar = true, Offset = CFrame.new(0,0.2,.75), LockMouse = true, MinZoom = 0, MaxZoom = 0, BodyFollow = true},
	["ThirdPerson"] = {CharacterVisibility = "All", Smoothness = 1, Zoom = 10, AlignChar = false, Offset = CFrame.new(0,0,0), LockMouse = false, MinZoom = 5, MaxZoom = 15, BodyFollow = true},
	["ShiftLock"] = {CharacterVisibility = "All", Smoothness = 0.75, Zoom = 7.5, Offset = CFrame.new(1.75, 0.5, 1), LockMouse = true, AlignChar = true, MinZoom = 2, MaxZoom = 15, BodyFollow = true},
}
local connectionList = {}
local propertyTypes = { --> For camera views
	["CharacterVisibility"] = "All",
	["Smoothness"] = 0.5,
	["Zoom"] = 10,
	["AlignChar"] = false,
	["Offset"] = CFrame.new(),
	["MinZoom"] = 5,
	["MaxZoom"] = 15,
	["LockMouse"] = false,
	["BodyFollow"] = true,
}





---> Module <---
local CameraService = {
	Offset = CFrame.new(),
	TiltFactor = CFrame.fromEulerAnglesYXZ(0,0,0),
	Host = currentCharacter:WaitForChild("Humanoid").RigType == Enum.HumanoidRigType.R15 and currentCharacter:WaitForChild("LowerTorso") or currentCharacter:WaitForChild("HumanoidRootPart"),
}

---> Camera System Functions <---
local function hideBodyParts(__type: string) --> Sets up CharacterVisibility
	if currentCharacter then
		for _, v in ipairs(currentCharacter:GetChildren()) do 
			if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
				if v:GetDescendants() then
					for _, child in ipairs(v:GetDescendants()) do
						if child:IsA("BasePart") or child:IsA("Decal") then
							child.LocalTransparencyModifier = __type and __type == "All" and 0 or 1
						end
					end
				end
				if __type then
					v.LocalTransparencyModifier = __type == "All" and 0 or __type == "Body" and v.Name == "Head" and 1 or 0
				else
					v.LocalTransparencyModifier = 1
				end
			elseif v:IsA("Accessory") and v:FindFirstChildWhichIsA("BasePart") then
				for _, child in ipairs(v:GetDescendants()) do
					if child:IsA("BasePart") or child:IsA("Decal") then
						child.LocalTransparencyModifier = __type and __type == "All" and 0 or 1
					end
				end
			end
		end
	else
		warn("[CameraService] Cannot find a host that is a Character model.")
	end
end

local function calculateShakingOffset(intensity: number) --> Creates the shaking effect
	local multipliers = {-1, 1}
	--> Use sin/cos for sense of randomness
	local currentSeed = math.random(1, os.time()) * multipliers[math.random(1, #multipliers)] 
	local x = math.sin(currentSeed) * (intensity * 1.5 ^ 2) / 3 
	local y = math.clamp(math.cos(currentSeed) * (intensity * 1.5 ^ 1.5), 0, 10) / 3
	local z = CameraService.CharacterVisibility == "All" and (math.cos(currentSeed) / 2) * (intensity) / 5 or 0

	return Vector3.new(x, y, z) * CameraService.Smoothness
end

local function raycastWorld(currentZoom, rotationCFrame) --> Correct zoom to avoid clipping parts
	--> Set params w/blacklist
	local params = RaycastParams.new()
	params.IgnoreWater = true
	if  CameraService.Host.Parent ~= workspace and CameraService.Host.Parent:IsA("Model") then
		params.FilterDescendantsInstances = {currentCharacter, CameraService.Host.Parent}
	else
		params.FilterDescendantsInstances = {currentCharacter, CameraService.Host}
	end
	local landRay = workspace:Raycast((currentCamPosition), (rotationCFrame * Vector3.new(0, 0, currentZoom)), params)
	local zoom: number = currentZoom
	--> Allow clipping through transluscent parts
	if landRay and landRay.Distance and landRay.Instance then 
		if landRay.Instance:IsA("BasePart") then
			zoom = landRay.Instance.Transparency <= 0.2 and landRay.Distance or currentZoom
		else
			zoom = landRay.Distance
		end
	end

	return (currentCamPosition + offset) + (rotationCFrame * Vector3.new(0, 0, zoom)) --> Cframe * Vector3 to zoom out in proper direction.
end

local function updateCamera(deltaTime) --> Update camera each frame
	local self = CameraService
	if UserInputService.GamepadEnabled then --> Set logic for CONSOLE camera movement
		cameraRotation -= differenceVector
		cameraRotation = Vector2.new(self.xLock and 0 or cameraRotation.X, self.yLock and 0 or math.clamp(cameraRotation.Y, math.rad(-45), math.rad(45)))
	end
	currentCamPosition = self.Host.Position + Vector3.new(0, self.Host.Parent == currentCharacter and 2.5 or 0,0)
	--> Convert cameraRotation into an angle CFrame (YXZ = Angles)
	local rotationCFrame = CFrame.fromEulerAnglesYXZ(cameraRotation.Y, cameraRotation.X, 0)
	updateShake = updateShake < math.random(2,3) and updateShake + 1 or 0
	offset = self.Shaking and offset and updateShake == 0 and calculateShakingOffset(self.ShakingIntensity) or self.Shaking and offset or Vector3.new(0,0,0)
	local camPos = raycastWorld(self.Zoom, rotationCFrame)
	local camCFrame = (rotationCFrame * self.TiltFactor * self.Offset) + camPos
	cam.CFrame = self.Smoothness <= 0 and  camCFrame or cam.CFrame:Lerp(camCFrame, (deltaTime * (self.Smoothness > 1 and 10 / self.Smoothness or 10 + (30 * (1 - self.Smoothness/1.2)))))
	--> Extraneous character alignment features if needed
	if self.Host.Parent == currentCharacter then
		local humanoid, root = currentCharacter:FindFirstChild("Humanoid"), currentCharacter:FindFirstChild("HumanoidRootPart")
		local waist = currentCharacter.UpperTorso:FindFirstChildWhichIsA("Motor6D")
		local neck = currentCharacter.Head:FindFirstChildWhichIsA("Motor6D")
		if not waistCache then
			waistCache = waist.C0
		end
		if not neckCache then
			neckCache = neck.C0
		end
		if self.AlignChar and humanoid.FloorMaterial ~= Enum.Material.Water then
			if waistCache and waist.C0 ~= waistCache then
				waist.C0 = waistCache
			end
			if neckCache and neck.C0 ~= neckCache then
				neck.C0 = neckCache
			end
			local _, x, _ = camCFrame:ToEulerAnglesYXZ()
			root.CFrame = CFrame.fromEulerAnglesYXZ(0, x + math.rad(self.Offset.X == 0 and 0 or -6), 0) + root.Position
		elseif humanoid.RigType == Enum.HumanoidRigType.R15 then
			if self.BodyFollow then
				waist.C0 = waist.C0:Lerp((CFrame.fromEulerAnglesYXZ(0, math.rad(mouse.Hit.LookVector:Dot((CFrame.Angles(root.CFrame:ToEulerAnglesYXZ()) * CFrame.new(-1,0,0)).Position.Unit) * 40), 0) + (waistCache).Position), 0.25)
				neck.C0 = neck.C0:Lerp((CFrame.fromEulerAnglesYXZ(math.rad(mouse.Hit.LookVector:Dot(Vector3.new(0,1,0)) * 40), 0, 0) + (neckCache).Position), 0.25)
				if not waistCache then
					waistCache = waist.C0
				end
				if not neckCache then
					neckCache = neck.C0
				end
			else
				if waistCache and waist.C0 ~= waistCache then
					waist.C0 = waistCache
				end
				if neckCache and neck.C0 ~= neckCache then
					neck.C0 = neckCache
				end
			end
		end
	end
end


function CameraService:SetCameraView(__type: string) --> Used to change views (i.e. from 1st to 3rd)
	assert(cameraSettings[__type] ~= nil, "[CameraService] Camera view not found for ID: "..tostring(__type))
	RunService:UnbindFromRenderStep("CameraUpdate")
	self.CameraView = __type
	for i, v in pairs(cameraSettings[__type]) do
		self[i] = v
	end
	RunService:UnbindFromRenderStep("CameraUpdate")
	if __type == "Default" then --> Resets it back to non-scriptable, Roblox default camera
		cam.CameraType = Enum.CameraType.Custom
		cam.CameraSubject = currentCharacter:WaitForChild("Humanoid")
	elseif cameraSettings[__type] then
		--> Add in settings
		if self.Host.Parent and self.Host.Parent == currentCharacter then
			hideBodyParts(self.CharacterVisibility ~= "None" and self.CharacterVisibility or nil)
		end
		UserInputService.MouseBehavior = self.LockMouse and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CameraSubject = nil
		local function updateZoom(input, gpe) --> For camera zooming in/out
			if not gpe then
				if input.UserInputType == Enum.UserInputType.MouseWheel then --> Computer (mouse)
					local multiplier = input.Position.Z
					self.Zoom = math.clamp(self.Zoom - (multiplier * (self.MaxZoom - self.MinZoom) / 7), self.MinZoom, self.MaxZoom)
				elseif input.UserInputState == Enum.UserInputState.Begin and (input.KeyCode == Enum.KeyCode.I or input.KeyCode == Enum.KeyCode.O) then --> Computer (I/O)
					local multiplier = input.KeyCode == Enum.KeyCode.I and 1 or -1
					self.Zoom = math.clamp(self.Zoom - (multiplier * (self.MaxZoom - self.MinZoom) / 4), self.MinZoom, self.MaxZoom)
				elseif input.KeyCode == Enum.KeyCode.ButtonR3 and input.UserInputState == Enum.UserInputState.Begin then --> Console Joystick Press
					self.Zoom = self.Zoom - ((self.MaxZoom - self.MinZoom) / 4) < self.MinZoom and self.MaxZoom or self.Zoom - ((self.MaxZoom - self.MinZoom) / 4)
				end
			end
		end
		local function onInputChange(input, gpe) --> Stores input, convert to Vector2 with rotation data
			updateZoom(input, gpe)
			local rightHold = self.LockMouse or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
			local mobile = input.UserInputType == Enum.UserInputType.Touch
			local console = input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.Thumbstick2
			if (not gpe or self.LockMouse) and (rightHold or mobile or console) and input.UserInputState == Enum.UserInputState.Change then
				delta = console and input.Position / 15 * math.sqrt(UserInputService.MouseDeltaSensitivity) or input.Delta --> Get mouse position
				differenceVector = console and Vector2.new(delta.X, -delta.Y) or {X = math.sqrt(math.abs(delta.X)) / (mobile and 27 or 50), Y = math.sqrt(math.abs(delta.Y)) / (mobile and 27 or 50)}
				--> Adjust the positions
				if console then
					differenceVector = Vector2.new(
						if delta.X < 0.2 / 15 * math.sqrt(UserInputService.MouseDeltaSensitivity) and delta.X > -0.2 / 15 * math.sqrt(UserInputService.MouseDeltaSensitivity) then 0 else delta.X,
						if -delta.Y < 0.2 / 15 * math.sqrt(UserInputService.MouseDeltaSensitivity) and -delta.Y > -0.2 / 15 * math.sqrt(UserInputService.MouseDeltaSensitivity) then 0 else -delta.Y
					)
				else
					differenceVector = Vector2.new(
						if delta.X > 0 then 1 * differenceVector.X else -1 * differenceVector.X,
						if delta.Y > 0 then 1 * differenceVector.Y else -1 * differenceVector.Y
					)
				end
				--> Update rotation once if not console; console updates rotation on each frame
				if not console then
					cameraRotation -= differenceVector
					cameraRotation = Vector2.new(self.xLock and 0 or cameraRotation.X, self.yLock and 0 or math.clamp(cameraRotation.Y, math.rad(-45), math.rad(45)))
				end
			end
			UserInputService.MouseBehavior = self.LockMouse and Enum.MouseBehavior.LockCenter or rightHold and Enum.MouseBehavior.LockCurrentPosition or Enum.MouseBehavior.Default
		end
		for _, connection in pairs(connectionList) do
			connection:Disconnect()
		end
		if UserInputService.TouchEnabled then --> Mobile Compatibility
			table.insert(connectionList, UserInputService.TouchPan:Connect(onInputChange))
			table.insert(connectionList, UserInputService.TouchRotate:Connect(onInputChange))
			local pinchDelta = 0;
			table.insert(connectionList, UserInputService.TouchPinch:Connect(function(_, scale, _, state, gpe)
				self.Zoom = gpe and self.Zoom or state == Enum.UserInputState.Begin and self.Zoom or math.clamp(self.Zoom - ((pinchDelta and scale - pinchDelta or 0) * 20), self.MinZoom, self.MaxZoom)
				pinchDelta = scale
			end))
		end
		table.insert(connectionList, UserInputService.InputBegan:Connect(onInputChange))
		table.insert(connectionList, UserInputService.InputChanged:Connect(onInputChange))
		table.insert(connectionList, UserInputService.InputEnded:Connect(onInputChange))
		RunService:BindToRenderStep("CameraUpdate", Enum.RenderPriority.Camera.Value - 1, updateCamera)
	end
end

function CameraService:CreateNewCameraView(id: string, settingsArray) --> Creates your own set of camera settings for a cam view
	assert(typeof(settingsArray) == "table", "[CameraService] 2nd parameter should be a table for :CreateNewCameraView()")
	cameraSettings[id] = settingsArray
	for property, default in pairs(propertyTypes) do
		if cameraSettings[id][property] == nil then
			warn('[CameraService] The "'..property..'" property was set to the default value: '..tostring(default))
			cameraSettings[id][property] = default
		end
	end
end

function CameraService:LockCameraPanning(lockXAxis: boolean, lockYAxis: boolean) --> Lock go brr
	self.xLock = lockXAxis
	self.yLock = lockYAxis
end

function CameraService:SetCameraHost(newHost: BasePart) --> For when you change the object the camera focuses on
	assert(not newHost or typeof(newHost) == "Instance" and newHost:IsA("BasePart"), "[CameraService] :SetCameraHost() only accepts a BasePart parameter, or none at all. ")
	self.Host = newHost or currentCharacter:WaitForChild("LowerTorso")
end

function CameraService:Change(property: string, newVal: any, changeDefaultProperty: boolean) --> To change camera aspects/properties.
	assert(propertyTypes[property] ~= nil, '[CameraService] "'..tostring(property)..'" is not a valid property to change.')
	self[property] = newVal
	if changeDefaultProperty then --> Change the camera view's default setting, if wanted
		cameraSettings[self.CameraView][property] = newVal
	end
end

function CameraService:ChangeSensitivity(val: number) --> MouseDeltaSensitivity but different
	assert(type(val) == "number" and val > 0, "[CameraService] Sensitivity should be greater than 0.")
	UserInputService.MouseDeltaSensitivity = val
end

function CameraService:ChangeFOV(val: number, instant: boolean) --> POV: your FOV changes
	assert(type(val) == "number" and val > 0, "[CameraService] FieldOfView should be greater than 0.")
	if instant then
		cam.FieldOfView = val
	else
		local tween = TweenService:Create(cam, TWEEN_INFO, {FieldOfView = val})
		tween:Play()
		tween.Completed:Wait()
		tween:Destroy()
	end
end

function CameraService:Shake(intensity: number, duration: number) --> Quakes more than Quaker Oats.
	assert(duration > 0 and intensity > 0, "[CameraService] Inputs for :Shake() must be positive")
	self.ShakingIntensity = intensity --> Property for shake
	self.Shaking = true --> Actively shaking or not
	task.wait(tonumber(duration))
	self.Shaking = false
end

function CameraService:Tilt(degree: number) --> Tilt on Z axis. Converts degree to rads. Tilt go brr.
	self.TiltFactor = CFrame.fromEulerAnglesYXZ(0,0, math.rad(degree))
end

player.CharacterAdded:Connect(function(char) --> Have camera reset focus to new character.
	if tostring(CameraService.Host.Parent) == player.Name then
		currentCharacter = char
		CameraService.Host = CameraService.Host.Parent.Name == player.Name and char:WaitForChild("LowerTorso") or CameraService.Host
	end
end)

return CameraService