local Renderer = {}
Renderer.__index = Renderer

local DEFAULT_IMAGE = "rbxasset://textures/ui/GuiImagePlaceholder.png"

function Renderer.new(config)
	local self = setmetatable({}, Renderer)
	self.config = config or {}
	self.surface = self.config.surface
	self.theme = self.config.theme or {}
	return self
end

function Renderer:render(document, styles, linkRouter)
	-- Template renderer: convert the parsed document into Roblox UI.
	-- Replace this with a full DOM-to-UI renderer.
	if not self.surface then
		warn("Renderer surface not configured")
		return
	end

	self.surface:ClearAllChildren()

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 40)
	header.BackgroundTransparency = 0.1
	header.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	header.TextColor3 = Color3.fromRGB(240, 240, 240)
	header.Font = Enum.Font.GothamBold
	header.TextSize = 18
	header.Text = document.metadata.title or "Web Page"
	header.Parent = self.surface

	local placeholder = Instance.new("ImageLabel")
	placeholder.Size = UDim2.new(1, -20, 0, 180)
	placeholder.Position = UDim2.new(0, 10, 0, 60)
	placeholder.BackgroundTransparency = 1
	placeholder.Image = DEFAULT_IMAGE
	placeholder.Parent = self.surface

	local body = Instance.new("TextLabel")
	body.Size = UDim2.new(1, -20, 1, -260)
	body.Position = UDim2.new(0, 10, 0, 250)
	body.BackgroundTransparency = 1
	body.TextColor3 = Color3.fromRGB(230, 230, 230)
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextWrapped = true
	body.TextSize = 14
	body.Font = Enum.Font.Gotham
	body.Text = "Rendered HTML preview (placeholder).\n\n" .. (document.rawHtml or "")
	body.Parent = self.surface

	local linkButton = Instance.new("TextButton")
	linkButton.Size = UDim2.new(0, 240, 0, 32)
	linkButton.Position = UDim2.new(0, 10, 1, -40)
	linkButton.Text = "Open first link (template)"
	linkButton.TextSize = 14
	linkButton.Font = Enum.Font.Gotham
	linkButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	linkButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	linkButton.Parent = self.surface

	linkButton.MouseButton1Click:Connect(function()
		linkRouter:open("https://example.com")
	end)
end

return Renderer
