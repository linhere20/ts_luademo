local Page1State = class("Page1State", State)

function Page1State:configuration(thread, params)
	thread.setTimeout(100000)
	params.timeoutHandler = self.wait2

	params.stateInjection.before = function()
		ilog(self.name.." state before", false)
	end

	params.stateInjection.after = function()
		ilog(self.name.." state after", false)
	end

	params.stateInjection.whiteList = {self.wait1}
end

function Page1State:enteredState()
	return self.wait1
end

function Page1State:reenteredState()
	return self.enteredState
end

function Page1State:wait1()
	if self:isStateTimeout(1000 * 10) then
		ilog(self.name.. " wait1 timeout")
		return self.wait2
	end
	
	return self.wait1
end

function Page1State:wait2()
	if self:isStateTimeout(1000 * 10) then
		ilog(self.name.. " wait2 timeout")
		return gc.ok
	end
	
	return self.wait2
end

return Page1State