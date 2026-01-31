local HtmlParser = {}
HtmlParser.__index = HtmlParser

local VOID_ELEMENTS = {
	area = true,
	base = true,
	br = true,
	col = true,
	embed = true,
	hr = true,
	img = true,
	input = true,
	link = true,
	meta = true,
	param = true,
	source = true,
	track = true,
	wbr = true,
}

function HtmlParser.new()
	return setmetatable({}, HtmlParser)
end

local function decodeEntities(text)
	return text
		:gsub("&lt;", "<")
		:gsub("&gt;", ">")
		:gsub("&amp;", "&")
		:gsub("&quot;", '"')
		:gsub("&#39;", "'")
end

local function parseAttributes(raw)
	local attributes = {}
	for key, value in string.gmatch(raw, "([%w-_:]+)%s*=%s*\"(.-)\"") do
		attributes[string.lower(key)] = value
	end
	for key, value in string.gmatch(raw, "([%w-_:]+)%s*=%s*'(.-)'") do
		attributes[string.lower(key)] = value
	end
	for key in string.gmatch(raw, "([%w-_:]+)%s*=") do
		if attributes[string.lower(key)] == nil then
			attributes[string.lower(key)] = true
		end
	end
	return attributes
end

local function createNode(nodeType, data)
	local node = {
		type = nodeType,
		children = {},
	}
	for key, value in pairs(data or {}) do
		node[key] = value
	end
	return node
end

local function appendChild(parent, child)
	table.insert(parent.children, child)
	child.parent = parent
end

function HtmlParser:parse(html)
	local document = createNode("document", {
		metadata = {
			title = "Untitled",
		},
		rawHtml = html,
	})

	local root = createNode("element", {
		tag = "root",
		attributes = {},
	})
	appendChild(document, root)

	local stack = { root }
	local pos = 1

	while true do
		local startPos, endPos, tagText = string.find(html, "<([^>]-)>", pos)
		if not startPos then
			local remaining = string.sub(html, pos)
			if remaining ~= "" then
				appendChild(stack[#stack], createNode("text", {
					text = decodeEntities(remaining),
				}))
			end
			break
		end

		if startPos > pos then
			local textChunk = string.sub(html, pos, startPos - 1)
			if textChunk ~= "" then
				appendChild(stack[#stack], createNode("text", {
					text = decodeEntities(textChunk),
				}))
			end
		end

		local tag = tagText
		local isClosing = string.sub(tag, 1, 1) == "/"
		local isComment = string.sub(tag, 1, 3) == "!--"

		if isComment then
			appendChild(stack[#stack], createNode("comment", {
				text = tag,
			}))
		elseif isClosing then
			local closeTag = string.lower(string.match(tag, "^/\s*([%w-_:]+)") or "")
			for i = #stack, 2, -1 do
				if stack[i].tag == closeTag then
					table.remove(stack, i)
					break
				end
			end
		else
			local tagName = string.lower(string.match(tag, "^%s*([%w-_:]+)") or "")
			local attrText = string.match(tag, "^[%w-_:]+%s*(.*)$") or ""
			local selfClosing = string.sub(tag, -1) == "/" or VOID_ELEMENTS[tagName]

			local element = createNode("element", {
				tag = tagName,
				attributes = parseAttributes(attrText),
			})
			appendChild(stack[#stack], element)

			if tagName == "title" then
				element._captureTitle = true
			end

			if not selfClosing then
				table.insert(stack, element)
			end
		end

		pos = endPos + 1
	end

	-- Extract title from the first title element text.
	local function findTitle(node)
		for _, child in ipairs(node.children or {}) do
			if child.type == "element" and child.tag == "title" then
				for _, inner in ipairs(child.children or {}) do
					if inner.type == "text" then
						return inner.text
					end
				end
			end
			local found = findTitle(child)
			if found then
				return found
			end
		end
		return nil
	end

	local title = findTitle(document)
	if title then
		document.metadata.title = title
	end

	return document
end

return HtmlParser
