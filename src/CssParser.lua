local CssParser = {}
CssParser.__index = CssParser

function CssParser.new()
	return setmetatable({}, CssParser)
end

function CssParser:parse(html)
	-- Template CSS parser: scan for <style> blocks and return a rule table.
	local styles = {
		inline = {},
		rules = {},
	}

	for styleBlock in string.gmatch(html, "<style[^>]*>(.-)</style>") do
		table.insert(styles.rules, {
			selector = "*",
			declarations = {
				text = styleBlock,
			},
		})
	end

	return styles
end

return CssParser
