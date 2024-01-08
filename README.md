# CameraService
*Looking for the DevForums posting? Find it here: https://devforum.roblox.com/t/cameraservice-a-new-camera-for-a-new-roblox/1988655*

Created by me, Ryan! (or Lugical, if you know my Roblox username)

CameraService is my first open-source, serving as an alternative to the default Roblox camera system. I decided to create a custom camera system that lets developers of all kinds be able to implement new, breathtaking camera views into their games and experiences with relative ease compared to having to do it out by themselves. This system is for Roblox game development. 

## The Features
The list of features goes on and on, some of which include:
* Different, **customizable** properties that developers can play around with and implement, including the camera's smoothness, zoom, offset from the part it's focusing on, and more.
* Seamlessly **transitioning** between different camera views (first-person, third-person, shift-lock, etc.), and letting you create your own!
* **Smooth** camera movements, rather than Roblox's usual instantaneous movements, using linear interpolation and damping.
* The ability to **tilt** the camera with ease, opening the door to advanced-like camera manipulation to beginners.
* Properties that let you enable **aesthetically appealing** effects on the player's character, such as having their body follow the mouse.
* **Shaking** camera effects that can be used for a multitude of purposes.
* **Dynamic wobbling** that gives that extra kick of realism
* Ability to **lock** camera panning on the X and Y axes.
* **Compatible** on all devices, from the laptop, phone, tablet, and console.

## API Reference
> **:SetCameraView(__type: string)**
    Sets the camera to a certain view, such as first person, shift-lock, or some other.
    Will error if CameraService cannot find the camera view.

   > **:CreateNewCameraView(id: string, settingsArray: table)**
    Adds a new camera view that the camera can be set to.
    `settingsArray` should have values for camera view properties as seen below in :Change().
    If no value is provided, a default one will be placed within.

   > **:LockCameraPanning(xAxis: boolean, yAxis: boolean, lockAtX: number, lockAtY: number)**
    Locks camera movement from right-to-left (x-axis) or up-down (y-axis)
	3rd and 4th parameters are optional. If the camera is locked, it'll lock at the rotation of those parameters.
	Input should be in degrees for that.
```lua
--> Example for :CreateNewCameraView & :LockCameraPanning
local info = {
	Smoothness = 3,
	CharacterVisibility = "All",
	MinZoom = 15,
	MaxZoom = 15,
	Zoom = 15,
	AlignChar = false,
	Offset = CFrame.new(0,0,0),
	LockMouse = false,
	BodyFollow = false
}

CameraService:CreateNewCameraView("2D_test", info)
CameraService:SetCameraView("2D_test")
CameraService:LockCameraPanning(true, true, 90, 0) 
```
   > **:SetCameraHost(newHost: BasePart)**
    Has the camera focus in on the input part. Must be a BASEPART (not a model).
    To reset the host back to the player's character, you can leave the parameters blank.

   > **:Change(property: string, val: any, changeDefaultProperty: boolean)** Allows you to alter the properties of CameraService to customize it as you wish. Properties that can be changed include:

* **`"CharacterVisibility" (string):`** Determines what part of the character is visible when it's the host. "All" shows all parts, "Body" hides the head, & "None" hides the whole body.
* **`MinZoom" (number)`:** Determines how close the player can zoom in. In studs.
* **`MaxZoom" (number):`** Determines how far the player can zoom out. In studs.
* **`Zoom" (number):`** The current distance the camera is away from the host.
* **`Smoothness" (number):`** Determines how smooth the camera movement is. Intervals from 0-1 are suggested. Intervals higher could be used to create a "cinematic" effect.
* **`Offset" (CFrame):`** Determines the offset/positioning away from the camera host. Can be used to simulate shift-lock.
* **`LockMouse" (boolean):`** Has the mouse locked in at the center.
* **`AlignChar" (boolean):`** If set to true, the character will rotate itself based off the camera (highly advised for shift-locks and first person)
* **`BodyFollow" (boolean):`** If AlignChar is NOT enabled, BodyFollow allows for an effect that has the upper body slightly rotate based off the mouse location.
* **`Wobble" (number):`** Allows you to adjust the intensity of dynamic wobbling. Can also be called via :SetWobbling()




> **:ChangeSensitivity(val: number)**
    Changes the rate at which the camera moves. 
    Merely adjusts the UserInputServiceService.MouseDeltaSensitivity property. 
    NOTICE: Players CAN change this themselves manually through the Roblox menu.

   > **:ChangeFOV(val: number, instant: boolean)**
    Gradually changes the field-of-view of the current camera.
    If you want the change to be instantaneous, add a second parameter marked true. 
    Changing FOV directly with the actual camera object is still possible.

   > **:Shake(intensity: number, duration: number)** 
    *Note: This function does yield for the duration of time inputted.*
    Creates a shaking camera effect in which the screen is, well, shaking. Like an earthquake. 
    Intensity should be a number greater than 0, preferably in the 0-1 range. Duration is in seconds.
 ```lua
--> Example 
CameraService:SetCameraView("ThirdPerson")
CameraService:Shake(2, 20)
--> Say I want to end it prematurely if a part is touched...
part.Touched:Connect(function()
	CameraService:Shake(0,0)
end)
```
   > **:Tilt(degree: number)**
    Tilts the camera across the z-axis on whatever object it is currently focusing on. 
    Useful for creating camera effects. Input a number in degrees.
 
 ```lua
--> Example Tilt
CameraService:SetCameraView("ShiftLock")
for i = 1, 180 do --> Create a spinning effect!
	CameraService:Tilt(i+1)
	task.wait(.1)
end
task.wait(1)
for i = 180, 1, -1 do --> Reverse it!
	CameraService:Tilt(i+1)
	task.wait(.1)
end
```

   > **:TiltAllAxes(x: number, y: number, z: number)**
    Like :Tilt, but allows you to adjust all 3 axes. Most likely use-case would be for creating camera effects. Inputs in X,Y,Z order.

> **:SetWobbling(value: number)**
  Determines the amount of dynamic wobbling enabled. The larger the value, the less wobbling. To disable it, set the value to 0.
  
```lua
--> Example
CameraService:SetCameraView("FirstPerson")
CameraService:SetWobbling(1) --> Make the wobbling very noticeable!
```


## Examples
Say you wanted to recreate the cinematic camera effect seen at the very top and in demonstrations. To create something like that, your program would look like:
```lua 
local CameraService = require(script.Parent.WhereverThisIsPlaced.ShouldBeOnTheClient)
local information = {
	Smoothness = 10,
	CharacterVisibility = "All",
	MinZoom = 10,
	MaxZoom = 10, 
	Zoom = 10,
	AlignChar = false,
	Offset = CFrame.new(),
	LockMouse = false,
	BodyFollow = false,
	Wobble = 3
}

CameraService:CreateNewCameraView("Cinematic", information)
CameraService:SetCameraView("Cinematic") --> Tada!
CameraService:ChangeFOV(90, false) --> You could also add a bit more with changing the FOV.
```


And let's say you wanted you wanted to just simply have players start in CameraService's first-person when they join. It's simply a matter of just a couple lines.
```lua 
local CameraService = require(script.Parent.WhereverThisIsPlaced.ShouldBeOnTheClient)
CameraService:SetCameraView("FirstPerson")
--> Other built-in camera views include: FirstPerson, FirstPersonVariant, Cinematic, and ShiftLock

--> And if we wanted to spice it up, and have it feel like an explosion?
--> When the character steps on a certain part, it can go like this:
local player = game.Players.LocalPlayer
local debounce = false
workspace.ExplosionPart.Touched:Connect(function(hit)
    if not debounce and hit and player and player.Character and hit.Parent == player.Character then
         debounce = true 
         CameraService:Shake(1, 5) --> Shakes heavily for 5 seconds.
    end
end)

```
