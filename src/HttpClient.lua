local HttpService = game:GetService("HttpService")

local HttpClient = {}
HttpClient.__index = HttpClient

function HttpClient.new(config)
	local self = setmetatable({}, HttpClient)
	self.config = config or {}
	self.userAgent = self.config.userAgent or "RobloxWebEngine/0.1"
	self.timeout = self.config.timeout or 10
	return self
end

function HttpClient:get(url)
	local ok, result = pcall(function()
		return HttpService:RequestAsync({
			Url = url,
			Method = "GET",
			Headers = {
				["User-Agent"] = self.userAgent,
			},
		})
	end)

	if not ok then
		warn("HTTP request failed", result)
		return nil
	end

	if not result.Success then
		warn("HTTP error", result.StatusCode, result.StatusMessage)
		return nil
	end

	return {
		statusCode = result.StatusCode,
		body = result.Body,
		headers = result.Headers,
	}
end

return HttpClient
