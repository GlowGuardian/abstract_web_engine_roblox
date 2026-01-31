local StyleResolver = {}
StyleResolver.__index = StyleResolver

local function trim(value)
	return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function parseInlineStyle(styleText)
	local declarations = {}
	for property, value in styleText:gmatch("([%w%-]+)%s*:%s*([^;]+)") do
		declarations[string.lower(trim(property))] = trim(value)
	end
	return declarations
end

local function splitSelector(selector)
	local tag = selector:match("^[%w-]+")
	local id = selector:match("#([%w-_]+)")
	local classList = {}
	for className in selector:gmatch("%.([%w-_]+)") do
		table.insert(classList, className)
	end
	return {
		tag = tag and string.lower(tag) or nil,
		id = id,
		classes = classList,
	}
end

local function matchesSelector(node, selector)
	if node.type ~= "element" then
		return false
	end

	if selector.tag and node.tag ~= selector.tag then
		return false
	end

	if selector.id then
		local nodeId = node.attributes and node.attributes.id
		if nodeId ~= selector.id then
			return false
		end
	end

	if selector.classes and #selector.classes > 0 then
		local classAttr = node.attributes and node.attributes.class or ""
		local classSet = {}
		for className in classAttr:gmatch("%S+") do
			classSet[className] = true
		end
		for _, className in ipairs(selector.classes) do
			if not classSet[className] then
				return false
			end
		end
	end

	return true
end

local function specificity(selector)
	local score = 0
	if selector.id then
		score = score + 100
	end
	if selector.classes then
		score = score + (#selector.classes * 10)
	end
	if selector.tag then
		score = score + 1
	end
	return score
end

local function applyDeclarations(target, declarations, priority)
	for property, value in pairs(declarations) do
		local existing = target[property]
		if not existing or priority >= existing.priority then
			target[property] = { value = value, priority = priority }
		end
	end
end

local function finalizeStyle(styleMap)
	local style = {}
	for property, data in pairs(styleMap) do
		style[property] = data.value
	end
	return style
end

function StyleResolver.new()
	return setmetatable({}, StyleResolver)
end

function StyleResolver:compute(document, styles)
	local rules = styles and styles.rules or {}

	local function walk(node)
		if node.type == "element" then
			local collected = {}

			for _, rule in ipairs(rules) do
				for _, selectorText in ipairs(rule.selectors) do
					local selector = splitSelector(selectorText)
					if matchesSelector(node, selector) then
						applyDeclarations(collected, rule.declarations, specificity(selector))
					end
				end
			end

			local inlineStyle = node.attributes and node.attributes.style
			if inlineStyle then
				applyDeclarations(collected, parseInlineStyle(inlineStyle), 1000)
			end

			node.computedStyle = finalizeStyle(collected)
		end

		for _, child in ipairs(node.children or {}) do
			walk(child)
		end
	end

	walk(document)
	return document
end

return StyleResolver
