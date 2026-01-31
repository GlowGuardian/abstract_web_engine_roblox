local CssParser = {}
CssParser.__index = CssParser

local function trim(value)
	return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function stripComments(css)
	return css:gsub("/%*.-%*/", "")
end

local function parseDeclarations(block)
	local declarations = {}
	for property, value in block:gmatch("([%w%-]+)%s*:%s*([^;]+)") do
		declarations[string.lower(trim(property))] = trim(value)
	end
	return declarations
end

function CssParser.new()
	return setmetatable({}, CssParser)
end

function CssParser:parse(html)
	local styles = {
		rules = {},
	}

	for styleBlock in string.gmatch(html, "<style[^>]*>(.-)</style>") do
		local css = stripComments(styleBlock)
		for selectorText, declarationBlock in css:gmatch("([^{}]+){([^{}]+)}") do
			local selectors = {}
			for selector in selectorText:gmatch("[^,]+") do
				table.insert(selectors, trim(selector))
			end
			table.insert(styles.rules, {
				selectors = selectors,
				declarations = parseDeclarations(declarationBlock),
			})
		end
	end

	return styles
end

return CssParser
