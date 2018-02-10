gc = gc or {}

gc.ok = "ok"

gc.states = {
	MainState = "MainState",
	Page1State = "Page1State",
	Page2State = "Page2State"
}

gc.taskFlow = {

	BeforeStartState = function(params)
		ilog("execute this function before each task.")
	end,
	
	mainTask = {
		--默认初始状态
		StartState = gc.states.MainState,
	},

	demoTask = {
		--超时，毫秒
		Timeout = 1000 * 60 * 10,

		BeforeStartState = function(params)
			ilog("execute this function before specific task. UserData:"..params.userData)
		end,
		
		StartState = gc.states.Page1State,

		Page1State = {
			ok = gc.states.Page2State,
		},
		Page2State = {
			ok = nil,
		},
	}
}
