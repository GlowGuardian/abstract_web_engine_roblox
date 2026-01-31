local HtmlParser = {}
HtmlParser.__index = HtmlParser

function HtmlParser.new()
	return setmetatable({}, HtmlParser)
end

function HtmlParser:parse(html)
	-- Template parsing logic.
	-- Replace this with a real HTML tokenizer + DOM builder.
	local document = {
		tag = "document",
		children = {},
		metadata = {
			title = "Untitled",
		},
	}

	-- Example: naive title extraction placeholder
	local title = string.match(html, "<title>(.-)</title>")
	if title then
		document.metadata.title = title
	end

	document.rawHtml = html
	return document
end

return HtmlParser
