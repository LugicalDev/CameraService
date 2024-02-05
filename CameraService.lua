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

    > :LockCameraPanning(xAxis: boolean, yAxis: boolean, lockAtX: number, lockAtY: number)
    Locks camera movement from right-to-left (x-axis) or up-down (y-axis)
	3rd and 4th parameters are optional. If the camera is locked, it'll lock at the rotation of those parameters.
	Input should be in degrees for that.

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

	> :TiltAllAxes(y: number, x: number, z: number)
    Like :Tilt, but allows you to adjust all 3 axes. Most likely use-case would be for creating camera effects.
	Inputs in Y, X, Z order.

    Created by @Lugical | Reased September, 2022
--]]




math.randomseed(tick())


---> Services <---
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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


--> Built-in camera views
local cameraSettings = { 
	["Default"] = {},
	["FirstPerson"] = {Wobble = 2.25, CharacterVisibility = "None", Smoothness = 1, Zoom = 0, AlignChar = true, Offset = CFrame.new(0,0,0), LockMouse = true, MinZoom = 0, MaxZoom = 0, BodyFollow = true},
	["FirstPersonVariant"] = {Wobble = 2.25, CharacterVisibility = "Body", Smoothness = .35, Zoom = 0, AlignChar = true, Offset = CFrame.new(0,0.2,.75), LockMouse = true, MinZoom = 0, MaxZoom = 0, BodyFollow = true},
	["ThirdPerson"] = {Wobble = 4, CharacterVisibility = "All", Smoothness = .7, Zoom = 10, AlignChar = false, Offset = CFrame.new(0,0,0), LockMouse = false, MinZoom = 5, MaxZoom = 15, BodyFollow = true},
	["ShiftLock"] = {Wobble = 4, CharacterVisibility = "All", Smoothness = 0.7, Zoom = 7.5, Offset = CFrame.new(1.75, 0.5, 1), LockMouse = true, AlignChar = true, MinZoom = 2, MaxZoom = 15, BodyFollow = true},
	["Cinematic"] = {
		Smoothness = 5,
		CharacterVisibility = "All",
		MinZoom = 10,
		MaxZoom = 10,
		Zoom = 10,
		AlignChar = false,
		Offset = CFrame.new(),
		LockMouse = false,
		BodyFollow = false,
		Wobble = 0
	}	
}


--> Connections when system is running. Clears out when not in use
local connectionList = {}


--> For camera views
local propertyTypes = {
	["CharacterVisibility"] = "All",
	["Smoothness"] = 0.5, --> If you're looking to get a smooth effect, I HIGHLY suggest values of 0.3+
	["Zoom"] = 10,
	["AlignChar"] = false,
	["Offset"] = CFrame.new(),
	["MinZoom"] = 5,
	["MaxZoom"] = 15,
	["LockMouse"] = false,
	["BodyFollow"] = true,
	["Wobble"] = 0
}




---> Module <---
local CameraService = {
	Offset = CFrame.new(),
	TiltFactor = CFrame.fromEulerAnglesYXZ(0,0,0),
	Host = currentCharacter:WaitForChild("Humanoid").RigType == Enum.HumanoidRigType.R15 and currentCharacter:WaitForChild("HumanoidRootPart") or currentCharacter:WaitForChild("Torso"),
}

---> Camera System Functions <---

--> Sets up CharacterVisibility
local function hideBodyParts(__type: string) 

	if currentCharacter then

		--> Set-up the rotation for shift-locking
		local hum = currentCharacter:FindFirstChildWhichIsA("Humanoid")
		if hum then
			hum.AutoRotate = math.abs(CameraService.Offset.X) <= 1.4 and true or false
		end

		--> Hide/unhide body parts when changing between views
		for _, v in ipairs(currentCharacter:GetChildren()) do  

			if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then

				--> Run logic for parts within parts
				if v:GetDescendants() then
					for _, child in ipairs(v:GetDescendants()) do
						if child:IsA("BasePart") or child:IsA("Decal") then
							child.LocalTransparencyModifier = __type and __type == "All" and 0 or 1
						end
					end
				end

				--> If no __type, hide everything
				if __type then
					v.LocalTransparencyModifier = __type == "All" and 0 or __type == "Body" and v.Name == "Head" and 1 or 0
				else
					v.LocalTransparencyModifier = 1
				end


			elseif v:IsA("Accessory") and v:FindFirstChildWhichIsA("BasePart") then

				--> Set the hiding logic
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


--> Creates the shaking effect
local function calculateShakingOffset(intensity: number) 

	local multipliers = {-1, 1}

	--> Use sin/cos for sense of randomness
	local currentSeed = math.random(1, os.time()) * multipliers[math.random(1, #multipliers)] 
	local x = math.sin(currentSeed) * (intensity * 1.5 ^ 2) / 3 
	local y = math.clamp(math.cos(currentSeed) * (intensity * 1.5 ^ 1.5), 0, 10) / 3

	--> Only offset Z in non-first-person views
	local z = CameraService.CharacterVisibility == "All" and (math.cos(currentSeed) / 2) * (intensity) / 5 or 0 

	return Vector3.new(x, y, z) * math.max(CameraService.Smoothness^2 * .5, 1)

end


--> Correct zoom to avoid clipping parts
local function raycastWorld(currentZoom, rotationCFrame) 

	--> Set params w/blacklist
	local params = RaycastParams.new()
	params.IgnoreWater = true
	if CameraService.Host.Parent and CameraService.Host.Parent ~= workspace and CameraService.Host.Parent:IsA("Model") then
		params.FilterDescendantsInstances = {currentCharacter, CameraService.Host.Parent}
	else
		params.FilterDescendantsInstances = {currentCharacter, CameraService.Host}
	end

	local landRay = workspace:Raycast(currentCamPosition, (rotationCFrame * CameraService.Offset * Vector3.new(0, 0, currentZoom)), params)
	local zoom: number = currentZoom

	--> Allow clipping through transluscent parts
	if landRay and landRay.Distance and landRay.Instance then 
		if landRay.Instance:IsA("BasePart") then
			zoom = landRay.Instance.Transparency <= 0.4 and landRay.Distance * 0.91 or currentZoom
		else
			zoom = landRay.Distance - 1
		end
	end

	--> Cframe * Vector3 to zoom out in proper direction.
	return (currentCamPosition + offset) + (rotationCFrame * Vector3.new(0, 0, zoom)) 

end


--> Update camera orientation + pos @ each frame
local lapsed = 1000 --> Used for dampening while jumping/falling
local function updateCamera(deltaTime) 

	local self = CameraService

	--> Console has different inputs + logic. This helps set up CONSOLE camera movement
	if UserInputService.GamepadEnabled then 
		cameraRotation -= differenceVector
	end


	--> Clamp the y-vals for camera rotating
	cameraRotation = Vector2.new(
		self.xLock and self.atX or cameraRotation.X, 
		self.yLock and self.atY or math.clamp(cameraRotation.Y, math.rad(-60), math.rad(60))
	) 
	currentCamPosition = self.Host.Position + Vector3.new(0, self.Host.Parent and self.Host.Parent == currentCharacter and 2.5 or 0,0)


	--> Convert cameraRotation into an angle CFrame (YXZ = Angles)
	local rotationCFrame = CFrame.fromEulerAnglesYXZ(cameraRotation.Y, cameraRotation.X, 0)
	updateShake = updateShake < math.random(2,3) and updateShake + 1 or 0
	offset = self.Shaking and offset and updateShake == 0 and calculateShakingOffset(self.ShakingIntensity) or self.Shaking and offset or Vector3.new(0,0,0)
	local yCFOffset = CFrame.fromEulerAnglesYXZ(0,0,0)
	if self.Wobble and self.Wobble > 0 then
		--> For slight camera tilting for footsteps
		pcall(function()
			local yOff = currentCharacter.Humanoid.RigType == Enum.HumanoidRigType.R15 and (currentCharacter["LeftFoot"].Position.Y - currentCharacter["RightFoot"].Position.Y) / 1.5 or currentCharacter.Humanoid.RigType == Enum.HumanoidRigType.R6 and (currentCharacter["Left Leg"].Position.Y - currentCharacter["Right Leg"].Position.Y) or 0
			yCFOffset = CFrame.fromEulerAnglesYXZ(0,0, math.rad(yOff/ self.Wobble))
		end) 
	end


	--> Damping the motion of the camera for smoothing
	local camPos = raycastWorld(self.Zoom, rotationCFrame) 
	local camCFrame = (rotationCFrame * self.TiltFactor * self.Offset) + camPos
	--print(self.Smoothness)
	local desiredTime = self.Smoothness ^ 2 * 0.05 + 0.02 * self.Smoothness +0.005
	local lerpFactor = math.min(1, deltaTime / desiredTime)
	local targetCFrame =  cam.CFrame:Lerp(camCFrame, lerpFactor)
	local desired2 = desiredTime
	local lerp2
	if self.Zoom > 0 and self.Smoothness > 0 then
		local function damper()
			local hum = currentCharacter:FindFirstChild("Humanoid")
			local humState
		
			if hum then
				humState = hum:GetState()
			end
		
			if (humState == Enum.HumanoidStateType.Jumping) or (humState == Enum.HumanoidStateType.Freefall) then
				lapsed = 0
				return desiredTime * 3.33
			end
			lapsed += 1
			if lapsed < 1 / deltaTime then
				return desiredTime * 3.33
			else		
				return math.max(desiredTime, desiredTime * (3.33 - (lapsed - (1 / deltaTime)) * .03))
			end
		
		end
		desired2 = damper()
	end
	--cam.CFrame = self.Smoothness <= 0 and  camCFrame or cam.CFrame:Lerp(camCFrame, lerpFactor)--(.014 / deltaTime) * (1/((self.Smoothness+1)^1.5)))--(deltaTime * (self.Smoothness > 1 and 5 / self.Smoothness or 5 + (20 * (1 - self.Smoothness/1.2)))))
	lerp2 = desired2 ~= desiredTime and cam.CFrame:Lerp(camCFrame, math.min(1, deltaTime / desired2)) or nil
	cam.CFrame = self.Smoothness <= 0 and camCFrame or CFrame.new(targetCFrame.X, lerp2 and lerp2.Y or targetCFrame.Y, targetCFrame.Z) * targetCFrame.Rotation * yCFOffset 

	--> Extraneous character alignment features if needed
	if self.Host.Parent == currentCharacter then
		workspace.Retargeting = Enum.AnimatorRetargetingMode.Disabled
		local humanoid, root = currentCharacter:FindFirstChild("Humanoid"), currentCharacter:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 then
			local waist = humanoid.RigType == Enum.HumanoidRigType.R15 and currentCharacter.UpperTorso:FindFirstChildWhichIsA("Motor6D") or nil
			local neck = humanoid.RigType == Enum.HumanoidRigType.R15 and currentCharacter.Head:FindFirstChildWhichIsA("Motor6D") or nil
			if waist and not waistCache then
				waistCache = waist.C0
			end
			if  neck and not neckCache then
				neckCache = neck.C0
			end
			if self.AlignChar and humanoid.FloorMaterial ~= Enum.Material.Water then
				if waist and waistCache and waist.C0 ~= waistCache then
					waist.C0 = waistCache
				end
				if neck and neckCache and neck.C0 ~= neckCache then
					neck.C0 = neckCache
				end
				local _, x, _ = camCFrame:ToEulerAnglesYXZ()
				root.CFrame = CFrame.fromEulerAnglesYXZ(0, x + math.rad(self.Offset.X == 0 and 0 or -6), 0) + root.Position
			elseif humanoid.RigType == Enum.HumanoidRigType.R15 then
				if self.BodyFollow then
					waist.C0 = waist.C0:Lerp((CFrame.fromEulerAnglesYXZ(math.rad(mouse.Hit.LookVector:Dot(Vector3.new(0,1,0)) * 10), math.rad(mouse.Hit.LookVector:Dot((CFrame.Angles(root.CFrame:ToEulerAnglesYXZ()) * CFrame.new(-1,0,0)).Position.Unit) * 40), 0) + waistCache.Position), 0.25)
					neck.C0 = neck.C0:Lerp((CFrame.fromEulerAnglesYXZ(math.rad(mouse.Hit.LookVector:Dot(Vector3.new(0,1,0)) * 30), 0, 0) + neckCache.Position), 0.25)
					if waist and not waistCache then
						waistCache = waist.C0
					end
					if neck and not neckCache then
						neckCache = neck.C0
					end
				else
					if waist and waistCache and waist.C0 ~= waistCache then
						waist.C0 = waistCache
					end
					if neck and neckCache and neck.C0 ~= neckCache then
						neck.C0 = neckCache
					end
				end
			end
		end
	end


end


function CameraService:SetCameraView(__type: string) --> Used to change views (i.e. from 1st to 3rd)
	assert(cameraSettings[__type] ~= nil, "[CameraService] Camera view not found for ID: "..tostring(__type))

	self.CameraView = __type
	for i, v in pairs(cameraSettings[__type]) do
		self[i] = v
	end
	for _, connection in pairs(connectionList) do
		connection:Disconnect()
	end

	--> Check what camera view the user wants
	if __type == "Default" then 

		--> Resets it back to non-scriptable, Roblox default camera
		self.LockMouse = false
		cam.CameraSubject = currentCharacter:WaitForChild("Humanoid")
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		cam.CameraType = Enum.CameraType.Custom
		workspace.Retargeting = Enum.AnimatorRetargetingMode.Default


	elseif cameraSettings[__type] then

		--> Add in settings
		workspace.Retargeting = Enum.AnimatorRetargetingMode.Disabled
		if self.Host.Parent and self.Host.Parent == currentCharacter then
			hideBodyParts(self.CharacterVisibility ~= "None" and self.CharacterVisibility or nil)
		end
		UserInputService.MouseBehavior = self.LockMouse and __type ~= "Default" and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CameraSubject = nil


		--> For camera zooming in/out
		local function updateZoom(input, gpe) 
			if not gpe then
				if input.UserInputType == Enum.UserInputType.MouseWheel then --> Computer (mouse)
					local multiplier = input.Position.Z
					self.Zoom = math.clamp(self.Zoom - (multiplier * (self.MaxZoom - self.MinZoom) / 4), self.MinZoom, self.MaxZoom)
				elseif input.UserInputState == Enum.UserInputState.Begin and (input.KeyCode == Enum.KeyCode.I or input.KeyCode == Enum.KeyCode.O) then --> Computer (I/O)
					local multiplier = input.KeyCode == Enum.KeyCode.I and 1 or -1
					self.Zoom = math.clamp(self.Zoom - (multiplier * (self.MaxZoom - self.MinZoom) / 4), self.MinZoom, self.MaxZoom)
				elseif input.KeyCode == Enum.KeyCode.ButtonR3 and input.UserInputState == Enum.UserInputState.Begin then --> Console Joystick Press
					self.Zoom = self.Zoom - ((self.MaxZoom - self.MinZoom) / 4) < self.MinZoom and self.MaxZoom or self.Zoom - ((self.MaxZoom - self.MinZoom) / 4)
				end
			end
		end


		--> Stores input, convert to Vector2 with rotation data
		local function onInputChange(input, gpe) 
			updateZoom(input, gpe)
			local rightHold = self.LockMouse or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
			local mobile = input.UserInputType == Enum.UserInputType.Touch
			local console = input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.Thumbstick2
			if (not gpe or (not mobile and not console)) and (rightHold or mobile or console) and input.UserInputState == Enum.UserInputState.Change then
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
					cameraRotation = Vector2.new(self.xLock and self.atX or cameraRotation.X, self.yLock and self.atY or math.clamp(cameraRotation.Y, math.rad(-60), math.rad(60)))
				end
			end
			UserInputService.MouseBehavior = self.LockMouse and Enum.MouseBehavior.LockCenter or rightHold and Enum.MouseBehavior.LockCurrentPosition or Enum.MouseBehavior.Default
		end


		--> Disconnect any active connections
		for _, connection in pairs(connectionList) do
			connection:Disconnect()
		end


		--> Mobile Compatibility
		if UserInputService.TouchEnabled then 
			table.insert(connectionList, UserInputService.TouchPan:Connect(onInputChange))
			table.insert(connectionList, UserInputService.TouchRotate:Connect(onInputChange))
			local pinchDelta = 0;
			table.insert(connectionList, UserInputService.TouchPinch:Connect(function(_, scale, _, state, gpe)
				self.Zoom = gpe and self.Zoom or state == Enum.UserInputState.Begin and self.Zoom or math.clamp(self.Zoom - ((pinchDelta and scale - pinchDelta or 0) * 20), self.MinZoom, self.MaxZoom)
				pinchDelta = scale
			end))
		end


		--> Set up the input connections
		table.insert(connectionList, UserInputService.InputBegan:Connect(onInputChange))
		table.insert(connectionList, UserInputService.InputChanged:Connect(onInputChange))
		table.insert(connectionList, UserInputService.InputEnded:Connect(onInputChange))
		--> Set up the actual system to run
		table.insert(connectionList, RunService.PreSimulation:Connect(updateCamera))

		--> Special effects for the CINEMATIC VIEW
		if __type == "Cinematic" then
			local ui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
			ui.Name = "CameraService_Cinematic_Effect"
			ui.Enabled = true
			ui.ResetOnSpawn = false
			ui.IgnoreGuiInset = true
			local uiFrame1 = Instance.new("Frame", ui)
			uiFrame1.BackgroundColor3 = Color3.new(0,0,0)
			uiFrame1.Name = "Frame1"
			uiFrame1.BorderSizePixel = 0
			uiFrame1.Size = UDim2.new(1,0,.135,0)
			local uiFrame2 = uiFrame1:Clone()
			uiFrame2.Parent = ui
			uiFrame2.Name = "Frame2"

			uiFrame1.Position = UDim2.new(0,0,-.136,0)
			uiFrame2.Position = UDim2.new(0,0,1,0)

			uiFrame1:TweenPosition(UDim2.new(0,0,0,0), "Out", "Sine", .25, true)
			uiFrame2:TweenPosition(UDim2.new(0,0,.865,0), "Out", "Sine", .25, true)
		else
			local ui = player:WaitForChild("PlayerGui"):FindFirstChild("CameraService_Cinematic_Effect")
			if ui then
				local uiFrame1 = ui:FindFirstChild("Frame1")
				local uiFrame2 = ui:FindFirstChild("Frame2")
				if uiFrame1 then
					uiFrame1:TweenPosition(UDim2.new(0,0,-.1360,0), "Out", "Sine", .25, true)
				end
				if uiFrame2 then
					uiFrame2:TweenPosition(UDim2.new(0,0,1,0), "Out", "Sine", .25, true)
				end
				task.wait(.25)
				ui:Destroy()
			end
		end
	end
end




--> Creates your own set of camera settings for a cam view
function CameraService:CreateNewCameraView(id: string, settingsArray) 

	--> Make sure that settingsArray is a table to ensure all runs well
	assert(typeof(settingsArray) == "table", "[CameraService] 2nd parameter should be a table for :CreateNewCameraView()")

	--> Register the new view
	cameraSettings[id] = settingsArray
	for property, default in pairs(propertyTypes) do
		if cameraSettings[id][property] == nil then
			warn('[CameraService] The "'..property..'" property was set to the default value: '..tostring(default))
			cameraSettings[id][property] = default
		end
	end

end




--> Lock the panning on a certain direction. Great for emulating 2D systems + games on Roblox
function CameraService:LockCameraPanning(lockXAxis: boolean, lockYAxis: boolean, lockAtX: number, lockAtY: number) 

	--> Set up the camera orientation
	self.atX = lockAtX and math.rad(lockAtX) or 0
	self.atY = lockAtY and math.rad(lockAtY) or 0
	--> Lock if necessary
	self.xLock = lockXAxis
	self.yLock = lockYAxis

end




--> For when you change the object the camera focuses on
function CameraService:SetCameraHost(newHost: BasePart)
	assert(not newHost or typeof(newHost) == "Instance" and newHost:IsA("BasePart"), "[CameraService] :SetCameraHost() only accepts a BasePart parameter, or none at all. ")
	self.Host = newHost or currentCharacter:FindFirstChild("HumanoidRootPart") or currentCharacter:FindFirstChild("Torso")
end


--> To change camera aspects/properties.
function CameraService:Change(property: string, newVal: any, changeDefaultProperty: boolean) 

	--> Make sure the requested property to change is valid
	assert(propertyTypes[property] ~= nil, '[CameraService] "'..tostring(property)..'" is not a valid property to change.')


	self[property] = newVal
	if changeDefaultProperty then --> Change the camera view's default setting, if wanted
		cameraSettings[self.CameraView][property] = newVal
	end

end


--> You can also just alter MouseDeltaSensitivity in UserInputService directly.
--> This is here in case you forget :3
function CameraService:ChangeSensitivity(val: number) 

	--> Make sure that "val" is positive before doing anything
	assert(type(val) == "number" and val > 0, "[CameraService] Sensitivity should be greater than 0.")
	UserInputService.MouseDeltaSensitivity = val

end




--> POV: your FOV changes. Great for sprinting effects!
function CameraService:ChangeFOV(val: number, instant: boolean)

	--> Make sure that "val" is positive before doing anything
	assert(type(val) == "number" and val > 0, "[CameraService] FieldOfView should be greater than 0.")

	--> Set up FOV logic
	if instant then
		cam.FieldOfView = val
	else
		local tween = TweenService:Create(cam, TWEEN_INFO, {FieldOfView = val})
		tween:Play()
		tween.Completed:Wait()
		tween:Destroy()
	end

end



--> Quakes more than Quaker Oats.
function CameraService:Shake(intensity: number, duration: number) 

	--> Make sure that arguments are positive before doing anything
	assert(duration > 0 and intensity > 0, "[CameraService] Inputs for :Shake() must be positive")

	--> Logic
	self.ShakingIntensity = intensity --> Property for shake
	self.Shaking = true --> Actively shaking or not
	task.wait(tonumber(duration))
	self.Shaking = false

end


--> Converts degree to rads. Tilt go brr. 
function CameraService:Tilt(degree: number) 
	self.TiltFactor = CFrame.fromEulerAnglesYXZ(0, 0, math.rad(degree) or 0)
end


--> Converts degree to rads., but in all axes!!! Tilt go brr. 
function CameraService:TiltAllAxes(x: number, y: number, z: number) 
	self.TiltFactor = CFrame.fromEulerAnglesYXZ(y and math.rad(y) or 0, x and math.rad(x) or 0, z and math.rad(z) or 0)
end


--> Set up dynamic wobbling
function CameraService:SetWobbling(value: number)
	self.Wobble = value
end



player.CharacterAdded:Connect(function(char) --> Have camera reset focus to new character.
	if (not CameraService.Host) or (not CameraService.Host:IsDescendantOf(workspace)) or (tostring(CameraService.Host.Parent) == player.Name) then
		currentCharacter = char
		local humanoid = currentCharacter:WaitForChild("Humanoid")
		CameraService:SetCameraHost()
	end
end)
return CameraService
