local Page1State = class("Page1State", State)

function Page1State:configuration(thread, params)
	thread.setTimeout(1000 * 10)  --整个Page1State超时10秒
	
	--params.timeoutHandler 指定超时如何处理，有3种指定方法

	--1、跳转到本状态类的其他状态单元
	--params.timeoutHandler = self.wait2 

	--2、跳出本状态类，流程回到StateMgr
	--params.timeoutHandler = gc.ok

	--3、指定一个函数，注意函数里不要写mSleep
	params.timeoutHandler = function()
		ilog("Page1State timeout")
		return self.wait2
	end

	--hook本状态类的状态单元
	params.stateHook = {
		before = function()
			ilog(self.name.." state before", false)
		end,
		after = function()
			ilog(self.name.." state after", false)
		end,
		hookList = {".*"},
		whiteList = {"wait1"}
	}
end

function Page1State:enteredState()
	self.count = 1
	return self.wait1, 500
end

function Page1State:reenteredState()
	return self.enteredState
end

function Page1State:wait1()
	if self:isStateUnitTimeout(1000 * 10) then
		ilog(self.name.. " wait1 timeout")
		return self.enteredState
	end

	if self.count > 5 then
		return self.wait2
	end
	self.count = self.count + 1

	return self.wait1
end

function Page1State:wait2()
	if self:isStateUnitTimeout(1000 * 5) then
		ilog(self.name.. " wait2 timeout")
		return gc.ok
	end
	
	return self.wait2
end

return Page1State