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
	local decoded = text
		:gsub("&lt;", "<")
		:gsub("&gt;", ">")
		:gsub("&amp;", "&")
		:gsub("&quot;", '"')
		:gsub("&#39;", "'")

	decoded = decoded:gsub("&#x([%x]+);", function(hex)
		local code = tonumber(hex, 16)
		if code and code > 0 then
			return utf8.char(code)
		end
		return ""
	end)

	decoded = decoded:gsub("&#([0-9]+);", function(num)
		local code = tonumber(num, 10)
		if code and code > 0 then
			return utf8.char(code)
		end
		return ""
	end)

	return decoded
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

local function tokenize(html)
	local tokens = {}
	local pos = 1
	local length = #html

	local function emit(token)
		table.insert(tokens, token)
	end

	while pos <= length do
		local nextTagStart = string.find(html, "<", pos, true)
		if not nextTagStart then
			local remaining = string.sub(html, pos)
			if remaining ~= "" then
				emit({ type = "character", data = remaining })
			end
			break
		end

		if nextTagStart > pos then
			emit({ type = "character", data = string.sub(html, pos, nextTagStart - 1) })
		end

		local tagEnd = string.find(html, ">", nextTagStart + 1, true)
		if not tagEnd then
			break
		end

		local tagText = string.sub(html, nextTagStart + 1, tagEnd - 1)
		local trimmed = string.match(tagText, "^%s*(.-)%s*$") or ""

		if string.sub(trimmed, 1, 3) == "!--" then
			local commentClose = string.find(html, "-->", nextTagStart + 4, true)
			if commentClose then
				local commentContent = string.sub(html, nextTagStart + 4, commentClose - 1)
				emit({ type = "comment", data = commentContent })
				pos = commentClose + 3
			else
				emit({ type = "comment", data = string.sub(trimmed, 4) })
				pos = tagEnd + 1
			end
		elseif string.sub(trimmed, 1, 1) == "!" then
			emit({ type = "doctype", data = trimmed })
			pos = tagEnd + 1
		elseif string.sub(trimmed, 1, 1) == "/" then
			local name = string.lower(string.match(trimmed, "^/\s*([%w-_:]+)") or "")
			emit({ type = "endTag", name = name })
			pos = tagEnd + 1
		else
			local name = string.lower(string.match(trimmed, "^([%w-_:]+)") or "")
			local attrText = string.match(trimmed, "^[%w-_:]+%s*(.*)$") or ""
			local selfClosing = string.sub(trimmed, -1) == "/"

			local attributes = {}
			local index = 1
			while index <= #attrText do
				local _, nextIndex = string.find(attrText, "^%s+", index)
				if nextIndex then
					index = nextIndex + 1
				end

				local keyStart, keyEnd, key = string.find(attrText, "^([%w-_:]+)", index)
				if not keyStart then
					break
				end

				index = keyEnd + 1
				local _, eqEnd = string.find(attrText, "^%s*=%s*", index)
				if not eqEnd then
					attributes[string.lower(key)] = true
				else
					index = eqEnd + 1
					local quote = string.sub(attrText, index, index)
					if quote == '"' or quote == "'" then
						local valueStart = index + 1
						local valueEnd = string.find(attrText, quote, valueStart, true)
						if valueEnd then
							attributes[string.lower(key)] = string.sub(attrText, valueStart, valueEnd - 1)
							index = valueEnd + 1
						else
							attributes[string.lower(key)] = string.sub(attrText, valueStart)
							break
						end
					else
						local valueStart, valueEnd, value = string.find(attrText, "^([^%s>]+)", index)
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

			emit({
				type = "startTag",
				name = name,
				attributes = attributes,
				selfClosing = selfClosing or VOID_ELEMENTS[name],
			})
			pos = tagEnd + 1

			if RAW_TEXT_ELEMENTS[name] then
				local closePattern = "</" .. name .. ">"
				local closeStart = string.find(string.lower(html), closePattern, pos, true)
				if closeStart then
					local rawText = string.sub(html, pos, closeStart - 1)
					if rawText ~= "" then
						emit({ type = "character", data = rawText, raw = true })
					end
					pos = closeStart
				else
					pos = length + 1
				end
			end
		end
	end

	return tokens
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
	for _, token in ipairs(tokenize(html)) do
		if token.type == "startTag" then
			local element = createNode("element", {
				tag = token.name,
				attributes = token.attributes,
			})
			appendChild(stack[#stack], element)
			if not token.selfClosing then
				table.insert(stack, element)
			end
		elseif token.type == "endTag" then
			for i = #stack, 2, -1 do
				if stack[i].tag == token.name then
					table.remove(stack, i)
					break
				end
			end
		elseif token.type == "comment" then
			appendChild(stack[#stack], createNode("comment", {
				text = token.data,
			}))
		elseif token.type == "doctype" then
			appendChild(stack[#stack], createNode("doctype", {
				text = token.data,
			}))
		elseif token.type == "character" then
			local textContent = token.raw and token.data or decodeEntities(token.data)
			if textContent ~= "" then
				local lastChild = stack[#stack].children[#stack[#stack].children]
				if lastChild and lastChild.type == "text" then
					lastChild.text = lastChild.text .. textContent
				else
					appendChild(stack[#stack], createNode("text", {
						text = textContent,
					}))
				end
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
