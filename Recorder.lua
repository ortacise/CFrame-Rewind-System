-- // Variables \\ --
local RunService = game:GetService("RunService")
local Recorder = {}
Recorder.__index = Recorder

local SETTINGS = require(script.Parent.Parent:WaitForChild("Settings"))

local recordedChars = {}
type RecorderInfo = {
	CFrames: {{CFrame: CFrame, Time: number}}, -- Specifying number as index because their will be gaps in between each index
}

-- // Functions \\ --

local heartbeatConnection = nil
local function StartHeartbeat()
	if heartbeatConnection then
		return
	end -- Already recording chars position
	
	local function Loop(char, self: RecorderInfo) -- Update CFrames table
		if not self.Active then return end
		
		self:Update()
	end
	
	local function LoopThroughRecorders()
		for char, self in recordedChars do
			if not char or not char:FindFirstChild("HumanoidRootPart") then
				recordedChars[char] = nil
				continue
			end -- In case player leaves or something
			Loop(char, self)
		end
	end
	if SETTINGS.Update_Time and SETTINGS.Update_Time > 0 then
		heartbeatConnection = true
		while heartbeatConnection do
			LoopThroughRecorders()
			task.wait(SETTINGS.Update_Time)
		end
	else
		heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
			LoopThroughRecorders()
		end)
	end
	
end

function Recorder.new(char)
	if recordedChars[char] then
		return recordedChars[char]
	end
	
	local self = setmetatable({
		Rewinding = false,
		Active = false,
		Time = 0,
		
		Character = char,
		
		CFrames = {}, -- First index is the latest cframe recorded
	}, Recorder)
	recordedChars[char] = self
	
	return self
end

-- // Metatable Functions \\ --

function Recorder:StartRecording()
	self:SetActive(true)
	StartHeartbeat()
end

function Recorder.StopRecording(char)
	
end

function Recorder:SetActive(bool)
	self.Active = bool == true -- Just makes it always either True or False
end

function Recorder:ClearLog()
	self.CFrames = {}
end

function Recorder:Update()
	self.Time = os.clock()
	local point = {
		self.Character.HumanoidRootPart.CFrame, -- Already checked if HumanoidRootPart existed, so it's safe to assume it exists
		self.Time
	}
	table.insert(self.CFrames, point)

	while true do -- Removes any recorded CFrames that exceed 5 seconds
		local timePassed = os.clock()-self.CFrames[1][2]
		if timePassed > SETTINGS.Max_Seconds then
			table.remove(self.CFrames, 1)
		else
			break -- No recorded CFrames that exceed 5 seconds left
		end
	end
	
	return point
end

--[[
If theres an index of 0.3 and an index of 0.5, and you call GetTimePointsInBetweenTime(0.4),
it will return the values of 0.3 and 0.5, used for lerping in between them
to get the 'hypothetical' cframe of 0.4
]]
function Recorder:GetTimePointsInBetweenTime(Time: number)
	if self.CFrames[1][2] >= Time then -- Trying to access point that is way earlier than the earliest points
		return
	end
	
	local lastPoint, nextPoint
	
	local currentIndex = 1
	while true do
		local point = self.CFrames[currentIndex] -- CurrentIndex = 0, it never found a point that was made after Time
		if not point then
			point = self:Update() -- If next point is non existent, then create it
			
			if Time > point[2] then
				error("Trying to grab points between Time, when Time is in the future.", "\nTime it's trying to grab: ", Time, "Max Recorded Time: ", point[2])
			end
		end
		
		if point[2] <= Time then
			if not lastPoint or lastPoint[2] <= point[2] then
				lastPoint = point
			end
			
		elseif point[2] >= Time then
			nextPoint = point
		end
		
		if nextPoint and lastPoint then
			break
		end
		
		currentIndex += 1
	end
	
	return lastPoint, nextPoint
end

function Recorder:GetCFrameAtCurrentTime()
	return self:GetCFrameAtTime(os.clock())
end

function Recorder:GetCFrameAtTime(Time)
	local lastTimePoint, nextTimePoint = self:GetTimePointsInBetweenTime(Time)
	if not lastTimePoint or not nextTimePoint then return end
	
	local alpha = (Time-lastTimePoint[2]) / (nextTimePoint[2]-lastTimePoint[2])
	return lastTimePoint[1]:Lerp(nextTimePoint[1], alpha)
end

return Recorder
