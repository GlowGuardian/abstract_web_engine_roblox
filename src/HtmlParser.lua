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

local RAW_TEXT_ELEMENTS = {
	script = true,
	style = true,
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

local function parseAttributes(raw)
	local attributes = {}
	local index = 1

	while index <= #raw do
		local _, nextIndex = string.find(raw, "^%s+", index)
		if nextIndex then
			index = nextIndex + 1
		end

		local keyStart, keyEnd, key = string.find(raw, "^([%w-_:]+)", index)
		if not keyStart then
			break
		end
		index = keyEnd + 1

		local _, eqEnd = string.find(raw, "^%s*=%s*", index)
		if not eqEnd then
			attributes[string.lower(key)] = true
		else
			index = eqEnd + 1
			local quote = string.sub(raw, index, index)
			if quote == '"' or quote == "'" then
				local valueStart = index + 1
				local valueEnd = string.find(raw, quote, valueStart, true)
				if valueEnd then
					attributes[string.lower(key)] = string.sub(raw, valueStart, valueEnd - 1)
					index = valueEnd + 1
				else
					attributes[string.lower(key)] = string.sub(raw, valueStart)
					break
				end
			else
				local valueStart, valueEnd, value = string.find(raw, "^([^%s>]+)", index)
				if valueStart then
					attributes[string.lower(key)] = value
					index = valueEnd + 1
				else
					attributes[string.lower(key)] = true
					break
				end
			end
		end
	end

	return attributes
end

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

	while pos <= #html do
		local nextTagStart = string.find(html, "<", pos, true)
		if not nextTagStart then
			local remaining = string.sub(html, pos)
			if remaining ~= "" then
				appendChild(stack[#stack], createNode("text", {
					text = decodeEntities(remaining),
				}))
			end
			break
		end

		if nextTagStart > pos then
			local textChunk = string.sub(html, pos, nextTagStart - 1)
			if textChunk ~= "" then
				appendChild(stack[#stack], createNode("text", {
					text = decodeEntities(textChunk),
				}))
			end
		end

		local tagEnd = string.find(html, ">", nextTagStart + 1, true)
		if not tagEnd then
			break
		end

		local tagText = string.sub(html, nextTagStart + 1, tagEnd - 1)
		local isComment = string.sub(tagText, 1, 3) == "!--"

		if isComment then
			local commentClose = string.find(html, "-->", nextTagStart + 4, true)
			if commentClose then
				local commentContent = string.sub(html, nextTagStart + 4, commentClose - 1)
				appendChild(stack[#stack], createNode("comment", {
					text = commentContent,
				}))
				pos = commentClose + 3
			else
				appendChild(stack[#stack], createNode("comment", {
					text = string.sub(tagText, 4),
				}))
				pos = tagEnd + 1
			end
		elseif string.sub(tagText, 1, 1) == "/" then
			local closeTag = string.lower(string.match(tagText, "^/\s*([%w-_:]+)") or "")
			for i = #stack, 2, -1 do
				if stack[i].tag == closeTag then
					table.remove(stack, i)
					break
				end
			end
			pos = tagEnd + 1
		elseif string.sub(tagText, 1, 1) == "!" then
			appendChild(stack[#stack], createNode("doctype", {
				text = tagText,
			}))
			pos = tagEnd + 1
		else
			local tagName = string.lower(string.match(tagText, "^%s*([%w-_:]+)") or "")
			local attrText = string.match(tagText, "^[%w-_:]+%s*(.*)$") or ""
			local selfClosing = string.sub(tagText, -1) == "/" or VOID_ELEMENTS[tagName]

			local element = createNode("element", {
				tag = tagName,
				attributes = parseAttributes(attrText),
			})
			appendChild(stack[#stack], element)

			pos = tagEnd + 1

			if RAW_TEXT_ELEMENTS[tagName] then
				local closePattern = "</" .. tagName .. ">"
				local closeStart = string.find(string.lower(html), closePattern, pos, true)
				if closeStart then
					local rawText = string.sub(html, pos, closeStart - 1)
					if rawText ~= "" then
						appendChild(element, createNode("text", {
							text = rawText,
						}))
					end
					pos = closeStart + #closePattern
				else
					pos = #html + 1
				end
			elseif not selfClosing then
				table.insert(stack, element)
			end
		end
	end

	local title = findTitle(document)
	if title then
		document.metadata.title = title
	end

	return document
end

return HtmlParser
