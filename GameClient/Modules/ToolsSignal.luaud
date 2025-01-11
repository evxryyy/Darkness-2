local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)

local module = {}
module.__index = module
module.liveConnectedEvent = {}

function module:RegisterConnection(rbx_script_signal,fn)
	if(self.liveConnectedEvent[rbx_script_signal]) then return self.liveConnectedEvent[rbx_script_signal] end
	self.liveConnectedEvent[rbx_script_signal] = rbx_script_signal:Connect(fn)
	return self.liveConnectedEvent[rbx_script_signal]
end

function module:RegisterConnectionWithPromise(rbx_script_signal,fn)
	if(self.liveConnectedEvent[rbx_script_signal]) then return self.liveConnectedEvent[rbx_script_signal] end
	self.liveConnectedEvent[rbx_script_signal] = Promise.fromEvent(rbx_script_signal,function(...)
		local contains_args = {...}
		fn()
		return true
	end):catch(warn)
	return self.liveConnectedEvent[rbx_script_signal]
end

function module:RegisterConnectionWithSignal(rbx_script_signal,fn)
	if(self.liveConnectedEvent[rbx_script_signal]) then return self.liveConnectedEvent[rbx_script_signal] end
	self.liveConnectedEvent[rbx_script_signal] = Signal.new()
	self.liveConnectedEvent[rbx_script_signal]:Connect(fn)
	return self.liveConnectedEvent[rbx_script_signal]
end

function module:UnregisterConnection(rbx_script_signal)
	if(self.liveConnectedEvent[rbx_script_signal]) then
		self.liveConnectedEvent[rbx_script_signal]:Disconnect()
		self.liveConnectedEvent[rbx_script_signal] = nil
	end
end

function module:UnregisterConnectionFromPromise(rbx_script_signal)
	if(self.liveConnectedEvent[rbx_script_signal]) then
		if(Promise.is(self.liveConnectedEvent[rbx_script_signal])) then
			self.liveConnectedEvent[rbx_script_signal]:cancel()
			self.liveConnectedEvent[rbx_script_signal] = nil
			return true
		else
			return false
		end
	end
	return false
end

function module:UnregisterConnectionFromSignal(rbx_script_signal)
	if(self.liveConnectedEvent[rbx_script_signal]) then
		if(Signal.Is(self.liveConnectedEvent[rbx_script_signal])) then
			self.liveConnectedEvent[rbx_script_signal]:Destroy()
			self.liveConnectedEvent[rbx_script_signal] = nil
		end
	end
end

function module:UnregisterAll()
	for signal,connection in pairs(self.liveConnectedEvent) do
		if(Signal.Is(connection)) then
			connection:Destroy()
			connection = nil
		elseif(Promise.is(connection)) then
			connection:cancel()
			connection = nil
		else
			connection:Disconnect()
			connection = nil
		end
	end
	table.clear(self.liveConnectedEvent)
	return self.liveConnectedEvent,#self.liveConnectedEvent
end

return module
