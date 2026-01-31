local LayoutEngine = {}
LayoutEngine.__index = LayoutEngine

local DEFAULT_WIDTH = 800
local DEFAULT_HEIGHT = 600

local function measureText(text, fontSize)
	local length = #text
	local width = math.min(DEFAULT_WIDTH, math.max(120, length * (fontSize * 0.6)))
	local lines = math.ceil((length * (fontSize * 0.6)) / DEFAULT_WIDTH)
	local height = math.max(fontSize * 1.4, lines * fontSize * 1.4)
	return width, height
end

local function getDisplay(node)
	local style = node.computedStyle or {}
	return style.display or "block"
end

local function getFontSize(node)
	local style = node.computedStyle or {}
	local size = style["font-size"]
	if size then
		local px = size:match("^(%d+)%s*px")
		if px then
			return tonumber(px)
		end
	end
	return 14
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

function LayoutEngine.new(config)
	local self = setmetatable({}, LayoutEngine)
	self.config = config or {}
	self.viewportWidth = self.config.width or DEFAULT_WIDTH
	self.viewportHeight = self.config.height or DEFAULT_HEIGHT
	return self
end

function LayoutEngine:layout(document)
	local layout = {}
	local cursorY = 0

	local function layoutNode(node)
		if node.type ~= "element" then
			return
		end

		local display = getDisplay(node)
		if display == "none" then
			return
		end

		local fontSize = getFontSize(node)
		local textContent = table.concat(collectText(node), " ")
		local width, height = measureText(textContent, fontSize)

		layout[node] = {
			x = 0,
			y = cursorY,
			width = math.min(width, self.viewportWidth),
			height = height,
		}

		cursorY = cursorY + height + 12

		for _, child in ipairs(node.children or {}) do
			layoutNode(child)
		end
	end

	layoutNode(document)
	return layout
end

return LayoutEngine
