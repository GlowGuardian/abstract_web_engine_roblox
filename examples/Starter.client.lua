local WebEngine = require(game.ReplicatedStorage.WebEngine)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WebEngineGui"
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(1, 0, 1, 0)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
frame.Parent = screenGui

local engine = WebEngine.new({
	renderer = {
		surface = frame,
	},
	http = {
		userAgent = "RobloxWebEngine/0.1",
	},
})

engine:navigate("https://example.com")
