State = class("State")

State.static._version = "2.0.0"
State.static.stateLog = true
State.static.nextStateDelay = 1000

State.static.stateHooks = {}

State.static.addHook = function(hook)
	--[[
		hook: {
			id = "1", --移除时需用id
			before = function(state) --调用State目标函数前先调用此函数，返回非空值中断后续流程
			end,
			after = function(state) --调用State目标函数后调用此函数，返回非空值替换目标函数返回值
			end,
			hookList = {".*"}, --作用列表，State.name匹配则生效
			whiteList = {gc.states.InitState} --白名单列表，State.name匹配则过滤
		}
	]]
	assert(type(hook) == "table", "hook must be a table")
	assert(type(hook.id) == "string", "hook.id must be a string")
	for _, v in pairs(State.static.stateHooks) do
		if v.id == hook.id then
			return false
		end
	end
	
	table.insert(State.static.stateHooks, hook)
	return true
end

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
	local returnValue = nil
	local thread_id = thread.create(function()
		returnValue = state(thread, params)
	end, {
		catchBack = function(exp)
			if exp.msg == "timeout" and type(params.timeoutHandler) == "function" then
				returnValue = params.timeoutHandler()
			end
		end
	})
	State.static.threadWait(thread, thread_id)
	return returnValue
end


local StateUtils = {
	inList = function(ele, list)
		if ele == nil or list == nil then
			return false
		end

		assert(type(list) == "table", "list must be a table")

		for _, value in pairs(list) do
			if type(value) == "string" and string.match(ele, value) ~= nil then
				return true
			end
		end
		return false
	end,
	wellFormatedTimeout = function(second)
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
}


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
	self.cache = {}
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

function State:_findStateUnit(func)
	for k, v in pairs(self.class.__instanceDict) do
		if v == func then
			return {name = k, func = v} 
		end
	end
	return nil
end

function State:_handleThreadTimeout(exp, params)
	self.timeoutSec = nil
	if State.static.stateLog then
		ilog(self.name.." has been timeout!")
	end
	
	local state = params.timeoutHandler
	if type(state) == "function" then
		local myState = self:_findStateUnit(state)
		if myState ~= nil then
			return state
		end
		
		return state(self)
	end
	
	return state
end

function State:isStateUnitTimeout(millisecond)
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

function State:isStateUnitCountOut(maxCount)
	if self.preState and self.preState == self.state then
		self.outCount = self.outCount + 1
	else
		self.outCount = 1
	end
	
	return self.outCount >= maxCount
end

function State:isStateUnitCountModZero(mod)
	if self.preState and self.preState == self.state then
		self.outCount = self.outCount + 1
	else
		self.outCount = 1
	end
	
	return self.outCount % mod == 0
end

function State:isStateMgrCountOut(maxCount, forState)
	assert(self.mgr, "StateMgr can not be null")
	return self.mgr:isStateMgrCountOut(maxCount, forState)
end

function State:setStateTimeout(timeout)
	thread.setTimeout(timeout, self.thread_id)
end

function State:clearStateTimeout()
	thread.clearTimeout(self.thread_id)
end

function State:clearStateUnitTimeout()
	if self.curTime ~= nil then
		self.curTime = os.time()
	end
end

function State:stop()
	thread.stop(self.thread_id)
end

function State:start(startState)
	self.state = startState or self.enteredState;
	
	while(true) do
		self.preState = nil
		
		local params = {
			stateHooks = {},
			delay = State.static.nextStateDelay
		}
		
		local threadCreate = thread.createSubThread
		if self.isAlone then
			threadCreate = thread.create
		end
		
		self.thread_id = threadCreate(function()
			self:configuration(params)
			
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

function State:beforeHooks(params)
	if type(State.static.stateHooks) == "table" then
		for _, hook in pairs(State.static.stateHooks) do
			if type(hook) == "table" and type(hook.before) == "function" and not StateUtils.inList(self.name, hook.whiteList) and StateUtils.inList(self.name, hook.hookList) then
				local state = hook.before(self)
				if state ~= nil then
					return state
				end
			end
		end
	end

	if type(params.stateHooks) == "table" then
		for _, unitHook in pairs(params.stateHooks) do
			if type(unitHook) == "table" and type(unitHook.before) == "function" and not StateUtils.inList(params.stateName, unitHook.whiteList) and StateUtils.inList(params.stateName, unitHook.hookList) then
				local state = unitHook.before(self)
				if state ~= nil then
					return state
				end
			end
		end
	end
end

function State:afterHooks(params)
	local aState = nil

	if type(params.stateHooks) == "table" then
		for _, unitHook in pairs(params.stateHooks) do
			if type(unitHook) == "table" and type(unitHook.after) == "function" and not StateUtils.inList(params.stateName, unitHook.whiteList) and StateUtils.inList(params.stateName, unitHook.hookList)  then
				local state = unitHook.after(self)
				if state ~= nil then
					aState = state
				end
			end			
		end
	end

	if type(State.static.stateHooks) == "table" then
		for _, hook in pairs(State.static.stateHooks) do
			if type(hook) == "table" and type(hook.after) == "function" and not StateUtils.inList(self.name, hook.whiteList) and StateUtils.inList(self.name, hook.hookList) then
				local state = hook.after(self)
				if state ~= nil then
					aState = state
				end
			end
		end
	end	

	return aState
end

function State:nextState(func, params)
	params = params or {}
	params.stateName = nil
	local stateMapping = self:_findStateUnit(func)
	if stateMapping then
		params.stateName = stateMapping.name
	end

	local state = nil
	local delay = nil

	local beforeResult = self:beforeHooks(params)
	if beforeResult ~= nil then
		return beforeResult
	end

	if State.static.stateLog then
		if params.stateName then
			local info = self.name.."."..params.stateName
			if self.timeoutSec then
				info = info.."_"..StateUtils.wellFormatedTimeout(self.timeoutSec)
			end
			
			if self.preState ~= self.state then
				ilog(info)
			else
				itoast(info)
			end
		end
	end
	mSleep(params.delay)

	state, delay = func(self)

	local afterResult = self:afterHooks(params)
	if afterResult ~= nil then
		return afterResult
	end
	
	return state, delay
end
