gc = gc or {}

gc.states = {
	MainState = "MainState",
	Page1State = "Page1State",
	Page2State = "Page2State"
}

gc.taskFlow = {
	
	
	mainTask = {
		--默认初始状态
		StartState = gc.states.MainState,
	},

	demoTask = {
		--超时，毫秒
		Timeout = 1000 * 60 * 10,
		
		StartState = gc.states.Page1State,

		Page1State = {
			ok = gc.states.Page2State,
		},
		Page2State = {
			ok = nil,
		},
	}
}

gc.ok = "ok"
