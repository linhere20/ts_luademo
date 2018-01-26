require "config"

State = class("State")

State.static._version = "1.0.0"
State.static.stateLog = true
State.static.nextStateDelay = 1000

State.static.stateInjection = {
	before = function(state) end,
	after = function(state) end,
	whiteList = {}
}

State.static.createState = function(stateName, isAlone)
	local state = require(stateName)
	local instance = state:new(stateName)
	if isAlone then
		instance:setAlone(true)
	end
	return instance
end

State.static.threadWait = function(thread, thread_id)
	local ok, ret = thread.wait(thread_id)
	if not ok and ret.msg ~= "timeout" then
		error(ret.msg)
	end
	return ok, ret
end

State.static.invokeWithThread = function(state)
	local params = {}
	local thread_id = thread.create(function()
		return state(thread, params)
	end, {
		catchBack = function(exp)
			if exp.msg == "timeout" and type(params.timeoutHandler) == "function" then
				return params.timeoutHandler()
			end
		end
	})
	return State.static.threadWait(thread, thread_id)
end

State.static.inWhiteList = function(ele, whiteList)
	for _, value in pairs(whiteList) do
		if value == ele then
			return true
		end
	end
	return false
end

State.static.wellFormatedTimeout = function(second)
	second = second or 0
	if type(second) ~= "number" then
        return second
    end

    if second < 60 * 3 then
    	return string.format("%.0f", second).."s"
    elseif second < 60 * 60 then
    	return string.format("%.1f", second / 60).."m"
    elseif second < 60 * 60 * 24 then
    	return string.format("%.2f", second / 60 / 60).."h"
    end

    return second
end


function State:initialize(name)
	self.name = name
	self.thread_id = nil
	self.mgr = nil
	self.isAlone = false
	self.preState = nil
	self.state = nil
	self.outCount = 1
	self.timeoutSec = nil
	self.curTime = nil
end

function State:getName()
	return self.name
end

function State:setMgr(mgr)
	self.mgr = mgr
end

function State:getMgr()
	return self.mgr
end

function State:setAlone(flag)
	self.isAlone = flag
end

function State:enteredState(...)
end

function State:exitedState(...)
end

function State:reenteredState(...)
end

function State:configuration(...)
end

function State:findState(func)
	for k, v in pairs(self.class.__instanceDict) do
		if v == func then
			return {name = k, func = v} 
		end
	end
	return nil
end

function State:_handleThreadTimeout(exp, params)
	local state = params.timeoutHandler
	if type(state) == "function" then
		local myState = self:findState(state)
		if myState ~= nil then
			return state
		end

		return state(self)
	end
	
	return state
end

function State:isStateTimeout(millisecond)
	if self.preState and self.preState == self.state then
		self.timeoutSec = millisecond / 1000 - (os.time() - self.curTime)
		if self.timeoutSec <= 0 then
			self.timeoutSec = nil
			return true
		else
			return false
		end
	else
		self.curTime = os.time()
		self.timeoutSec = millisecond / 1000
		return false
	end
end

function State:isStateCountOut(maxCount)
	if self.preState and self.preState == self.state then
		self.outCount = self.outCount + 1
	else
		self.outCount = 1
	end
	
	return self.outCount >= maxCount
end

function State:isStateCountModZero(mod)
	if self.preState and self.preState == self.state then
		self.outCount = self.outCount + 1
	else
		self.outCount = 1
	end
	
	return self.outCount % mod == 0
end

function State:setTimeout(timeout)
	thread.setTimeout(timeout, self.thread_id)
end

function State:clearTimeout()
	thread.clearTimeout(self.thread_id)
end

function State:stop()
	thread.stop(self.thread_id)
end

function State:start(startState)
	self.state = startState or self.enteredState;
	
	while(true) do
		self.preState = nil
		
		local params = {
			stateInjection = {
				before = function() end,
				after = function() end,
				whiteList = {}
			},
			delay = State.static.nextStateDelay
		}
		
		local threadCreate = thread.createSubThread
		if self.isAlone then
			threadCreate = thread.create
		end
		
		self.thread_id = threadCreate(function()
			self:configuration(thread, params)
			
			while(true) do
				local nextState, nextStateDelay = self:nextState(self.state, params)
				self.preState = self.state
				self.state = nextState

				params.delay = State.static.nextStateDelay
				if type(nextStateDelay) == "number" then
					params.delay = nextStateDelay
				end

				if self.preState ~= self.state then
					self.timeoutSec = nil
				end
				
				if type(nextState) ~= "function" then
					return nextState
				end
			end
		end, {
			catchBack = function(exp)
				if exp.msg == "timeout" then
					self.state = self:_handleThreadTimeout(exp, params)
				end
			end
		})
	
		State.static.threadWait(thread, self.thread_id)
		if type(self.state) ~= "function" then
			return self.state
		end
	end
end

function State:nextState(func, params)
	params = params or {}
	local state = nil

	local skipGlobalStateInjection = State.static.inWhiteList(self.name, State.static.stateInjection.whiteList)
	local skipStateInjection = State.static.inWhiteList(func, params.stateInjection.whiteList)

	-- global state before
	local globalStateBefore = State.static.stateInjection.before
	if not skipGlobalStateInjection and globalStateBefore and type(globalStateBefore) == "function" then
		local aState = globalStateBefore(self)
		if aState ~= nil then
			state = aState
			return
		end
	end

	-- state before
	local stateBefore = params.stateInjection.before
	if not skipStateInjection and stateBefore and type(stateBefore) == "function" then
		local aState = stateBefore(self)
		if aState ~= nil then
			state = aState
			return
		end
	end

	if State.static.stateLog then
		local stateMapping = self:findState(func)
		if stateMapping then
			local info = self.name.."."..stateMapping.name
			if self.timeoutSec then
				info = info.."_"..State.static.wellFormatedTimeout(self.timeoutSec)
			end
			
			ilog(info)
		end
	end
	mSleep(params.delay)
	state, delay = func(self)
	
	-- state after
	local stateAfter = params.stateInjection.after
	if not skipStateInjection and stateAfter and type(stateAfter) == "function" then
		local aState = stateAfter(self)
		if aState ~= nil then
			state = aState
		end
	end
	
	-- global state after
	local globalStateAfter = State.static.stateInjection.after
	if not skipGlobalStateInjection and globalStateAfter and type(globalStateAfter) == "function" then
		local aState = globalStateAfter(self)
		if aState ~= nil then
			state = aState
		end
	end

	return state, delay
end


StateMgr = class("StateMgr")

function StateMgr:initialize(name)
	self.name = name
	self.states = {}
	self.current = nil
	self.thread_id = nil
end

function StateMgr:getName()
	return self.name
end

function StateMgr:addState(state)
	self.states[state:getName()] = state
end

function StateMgr:removeStateByName(stateName)
	if stateName == self.current:getName() then
		return
	end
	self.states[stateName] = nil
end

function StateMgr:findStateByName(name)
	return self.states[name]
end

function StateMgr:getCurrentState()
	return self.current
end

function StateMgr:isState(stateName)
	if not self.current then
		return false
	end

	return self.current:getName() == stateName
end

function StateMgr:nextState(stateName, ...)
	local nextState = self.states[stateName]
	if not nextState then
		nextState = State.static.createState(stateName)
		nextState:setMgr(self)
		self.states[stateName] = nextState
	end

	ilog("------------------------------------", false)

	if not self.current then
		self.current = nextState
		return self.current:start(self.current.enteredState)
	else
		if self.current == nextState then
			return self.current:start(self.current.reenteredState)
		else
			self.current:exitedState(...)
			self.current = nextState
			return self.current:start(self.current.enteredState)
		end
	end
end

function StateMgr:setTimeout(timeout)
	thread.setTimeout(timeout, self.thread_id)
end

function StateMgr:clearTimeout()
	thread.clearTimeout(self.thread_id)
end

function StateMgr:stop()
	thread.stop(self.thread_id)
end

function StateMgr:start(params)
	params = params or {}
	local stateStatus = nil
	local flow = gc.taskFlow[self.name]
	
	if not flow then  
		error("no configuration task flow: "..self.name) 
	end
	
	local stateName = params.stateName or flow.StartState

	self.thread_id = thread.create(function()
		if params.timeout and type(params.timeout) == "number" then
			thread.setTimeout(params.timeout)
		elseif flow.Timeout and type(flow.Timeout) == "number" then
			thread.setTimeout(flow.Timeout)
		end

		while(true) do
			if not self.current then
				stateStatus = self:nextState(stateName)
			else
				local nextStateName = nil
				if type(stateStatus) == "string" then
					local cur = flow[self.current:getName()]
					nextStateName = cur[stateStatus]
				elseif type(stateStatus) == "table" and State.isInstanceOf(stateStatus, State) then
					nextStateName = stateStatus.name
				end
			
				if not nextStateName then
					return
				end

				stateStatus = self:nextState(nextStateName)
			end
		end
	end, {
		catchBack = function(exp)
			if exp.msg == "timeout" then
				if params.timeoutHandler ~= nil and type(params.timeoutHandler) == "function" then
					params.timeoutHandler(self)
				end
			end
		end
	})

	State.static.threadWait(thread, self.thread_id)
end
