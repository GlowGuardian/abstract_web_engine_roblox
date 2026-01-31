local LinkRouter = {}
LinkRouter.__index = LinkRouter

function LinkRouter.new(engine)
	local self = setmetatable({}, LinkRouter)
	self.engine = engine
	return self
end

function LinkRouter:open(url)
	if not url then
		return
	end

	self.engine:handleLink(url)
end

return LinkRouter
