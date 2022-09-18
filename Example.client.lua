--\\----- [EXAMPLES FOR CAMERASERVICE] -----//--
--[[
	Script for the demo place, showcasing how one can use CameraService.
	By @Lugical, September 2022
--]]

local CameraService = require(script.Parent:WaitForChild("CameraService"))

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ui = playerGui:WaitForChild("ScreenGui")
local uiButton = ui.TextButton
local uiFrame1 = ui.Frame1
local uiFrame2 = ui.Frame2
local function resetToNormal()
	CameraService:ChangeSensitivity(1)
	uiFrame1:TweenPosition(UDim2.new(0,0,-.1360,0), "Out", "Sine", .25, true)
	uiFrame2:TweenPosition(UDim2.new(0,0,1,0), "Out", "Sine", .25, true)
	if player.Character then
		player.Character.Humanoid.WalkSpeed = 16
	end
	CameraService:ChangeFOV(70, false)
end
local information = {
	Smoothness = 10,
	CharacterVisibility = "All",
	MinZoom = 10,
	MaxZoom = 10.001,
	Zoom = 10,
	AlignChar = false,
	Offset = CFrame.new(),
	LockMouse = false,
	BodyFollow = false
}

CameraService:SetCameraView("ThirdPerson")
CameraService:CreateNewCameraView("Cinematic", information) --> Uses info to create a new camera view!

uiButton.MouseButton1Click:Connect(function()
	resetToNormal()
	uiButton.Visible = false
	CameraService:SetCameraView("ThirdPerson")
	CameraService:SetCameraHost() --> Leaving blank will set it back to your character
end)

workspace.WatchPart.ProximityPrompt.Triggered:Connect(function()
	resetToNormal()
	CameraService:SetCameraHost(workspace.WATCHER)
	CameraService:SetCameraView("FirstPerson")
	CameraService:Change("LockMouse", false, false)
	uiButton.Visible = true
end)

workspace.ThirdPart.ProximityPrompt.Triggered:Connect(function()
	resetToNormal()
	CameraService:SetCameraView("ThirdPerson")
end)

workspace.FirstPart.ProximityPrompt.Triggered:Connect(function()
	resetToNormal()
	CameraService:SetCameraView("FirstPerson")
end)

workspace.ShakePart.ProximityPrompt.Triggered:Connect(function()
	CameraService:Shake(0.5, 5)
end)

workspace.CinematicPart.ProximityPrompt.Triggered:Connect(function()
	CameraService:SetCameraView("Cinematic")
	CameraService:ChangeSensitivity(0.333)
	uiFrame1:TweenPosition(UDim2.new(0,0,0,0), "Out", "Sine", .25, true)
	uiFrame2:TweenPosition(UDim2.new(0,0,.865,0), "Out", "Sine", .25, true)
	if player.Character then
		player.Character.Humanoid.WalkSpeed = 12
	end
	CameraService:ChangeFOV(90, false)
end)

workspace.ShiftPart.ProximityPrompt.Triggered:Connect(function()
	resetToNormal()
	CameraService:SetCameraView("ShiftLock")
end)

workspace.TiltPart.ProximityPrompt.Triggered:Connect(function()
	CameraService:Tilt(30)
	task.wait(5)
	CameraService:Tilt(0)
end)