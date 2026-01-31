local Renderer = {}
Renderer.__index = Renderer

local DEFAULT_IMAGE = "rbxasset://textures/ui/GuiImagePlaceholder.png"

local function parseColor(value, fallback)
	if not value then
		return fallback
	end

	local hex = value:match("^#([%x]+)$")
	if hex then
		if #hex == 3 then
			local r = tonumber(hex:sub(1, 1), 16) * 17
			local g = tonumber(hex:sub(2, 2), 16) * 17
			local b = tonumber(hex:sub(3, 3), 16) * 17
			return Color3.fromRGB(r, g, b)
		elseif #hex == 6 then
			local r = tonumber(hex:sub(1, 2), 16)
			local g = tonumber(hex:sub(3, 4), 16)
			local b = tonumber(hex:sub(5, 6), 16)
			return Color3.fromRGB(r, g, b)
		end
	end

	local r, g, b = value:match("rgb%((%d+),%s*(%d+),%s*(%d+)%)")
	if r and g and b then
		return Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
	end

	return fallback
end

local function parseFontSize(value, fallback)
	if not value then
		return fallback
	end

	local size = value:match("^(%d+)%s*px")
	if size then
		return tonumber(size)
	end

	return fallback
end

local function findFirstElement(node, tagName)
	for _, child in ipairs(node.children or {}) do
		if child.type == "element" and child.tag == tagName then
			return child
		end
		local found = findFirstElement(child, tagName)
		if found then
			return found
		end
	end
	return nil
end

local function collectText(node, buffer)
	buffer = buffer or {}
	if node.type == "text" then
		table.insert(buffer, node.text)
	end
	for _, child in ipairs(node.children or {}) do
		collectText(child, buffer)
	end
	return buffer
end

function Renderer.new(config)
	local self = setmetatable({}, Renderer)
	self.config = config or {}
	self.surface = self.config.surface
	self.theme = self.config.theme or {}
	return self
end

function Renderer:render(document, styles, linkRouter, layout)
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

	local bodyNode = findFirstElement(document, "body")
	local bodyStyle = bodyNode and bodyNode.computedStyle or {}
	local bodyText = bodyNode and table.concat(collectText(bodyNode), " ") or document.rawHtml or ""
	local bodyLayout = layout and bodyNode and layout[bodyNode]
	local bodyHeight = bodyLayout and bodyLayout.height or 200

	local body = Instance.new("TextLabel")
	body.Size = UDim2.new(1, -20, 0, bodyHeight)
	body.Position = UDim2.new(0, 10, 0, 250)
	body.BackgroundTransparency = 1
	body.TextColor3 = parseColor(bodyStyle.color, Color3.fromRGB(230, 230, 230))
	body.BackgroundColor3 = parseColor(bodyStyle["background-color"], Color3.fromRGB(20, 20, 20))
	body.BackgroundTransparency = bodyStyle["background-color"] and 0 or 1
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextWrapped = true
	body.TextSize = parseFontSize(bodyStyle["font-size"], 14)
	body.Font = Enum.Font.Gotham
	body.Text = "Rendered HTML preview (template).\n\n" .. bodyText
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
