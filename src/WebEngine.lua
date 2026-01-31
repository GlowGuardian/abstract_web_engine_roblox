local HttpClient = require(script.Parent.HttpClient)
local HtmlParser = require(script.Parent.HtmlParser)
local CssParser = require(script.Parent.CssParser)
local JsStub = require(script.Parent.JsStub)
local Renderer = require(script.Parent.Renderer)
local LinkRouter = require(script.Parent.LinkRouter)

local WebEngine = {}
WebEngine.__index = WebEngine

function WebEngine.new(config)
	local self = setmetatable({}, WebEngine)
	self.config = config or {}
	self.httpClient = HttpClient.new(self.config.http)
	self.htmlParser = HtmlParser.new()
	self.cssParser = CssParser.new()
	self.jsRuntime = JsStub.new()
	self.renderer = Renderer.new(self.config.renderer)
	self.linkRouter = LinkRouter.new(self)
	return self
end

function WebEngine:navigate(url)
	local response = self.httpClient:get(url)
	if not response then
		return nil, "Failed to fetch URL"
	end

	local document = self.htmlParser:parse(response.body or "")
	local styles = self.cssParser:parse(response.body or "")
	self.jsRuntime:load(response.body or "")

	self.renderer:render(document, styles, self.linkRouter)
	return document
end

function WebEngine:handleLink(url)
	return self:navigate(url)
end

return WebEngine
