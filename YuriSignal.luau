--!strict
--!optimize 2
--[[
    Copyright © 2025 gopher town
    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    Distrubted under MIT license
--]]

--[[
	utility focused signal lib
	
	--YuriSignal
	new<T...>() -> (YuriSignal<T...>)
		Disconnect all connections. Clears the linked list and relevent items get GC'd.
			disconnectAll: (signal: YuriSignal<T...>) -> (),

		Bind a function to the signal. This is the default connection which all other connection types inherit from.
			connect: (signal: YuriSignal<T...>, callback: (T...) -> ()) -> (YuriConnection<T...>),
			
		Bind a function to the signal, after one usage it will be automatically disconnected and gc'd.
			once: (signal: YuriSignal<T...>, callback: (T...) -> ()) -> (YuriConnection<T...>),
		
		Bind a function to the signal, after <amount: number> uses, it will automatically disconnect.
			limit: (signal: YuriSignal<T...>, amount: number, callback: (T...) -> ()) -> (YuriConnection<T...>),
			
		Bind a function to the signal, after each signal fire <evaluationFunction: () -> (boolean)> will be executed. 
		If it returns true it will automatically disconnect.
			each: (signal: YuriSignal<T...>, evaluationFunction: () -> (boolean), callback: (T...) -> ()) -> (YuriConnection<T...>),
			
		Bind a function to the signal, after <disconnectAfterSeconds: number> seconds, it will automatically disconnect.
			after: (signal: YuriSignal<T...>, disconnectAfterSeconds: number, callback: (T...) -> ()) -> (YuriConnection<T...>),
			
		Yields execution until the signal is fired. Returns T... after the signal has been fired.
			wait: (signal: YuriSignal<T...>) -> (T...),
			
		Yields execution until the signal has been fired or <timeOut: number> has elapsed. If it times out, nil will be returned in place of T...
			waitUntil: (signal: YuriSignal<T...>, timeOut: number) -> (T...),
			
		Fires the signal with T... as arguments. 
			fire: (signal: YuriSignal<T...>, T...) -> (),
			
		Destroys the signal and connections.
			destroy: (signal: YuriSignal<T...>) -> ()
		
	--YuriConnection
	connect: (signal: YuriSignal<T...>, callback: (T...) -> ()) -> (YuriConnection<T...>),
		Disconnects the connection.
			disconnect: (connection: YuriConnection<T...>) -> ()
		Whether or not the signal is currently connected.
			connected: boolean,
		The amount of times the signal has been called.
			calls: number,
			
	The private types are internal types. It's best to ignore them as they do not display in
	intellisense, but I am not your mom so do as you'd wish. It's not like luau has a clean way
	to do clean private elements or methods.
	
	If you have questions or issues message @sodere on discord or any other member of the gopher town team.
]]


export type YuriSignal<T...> = {
	disconnectAll: (signal: YuriSignal<T...>) -> (),
	connect: (signal: YuriSignal<T...>, callback: (T...) -> ()) -> (YuriConnection<T...>),
	once: (signal: YuriSignal<T...>, callback: (T...) -> ()) -> (YuriConnection<T...>),
	limit: (signal: YuriSignal<T...>, amount: number, callback: (T...) -> ()) -> (YuriConnection<T...>),
	each: (signal: YuriSignal<T...>, evaluationFunction: () -> (boolean), callback: (T...) -> ()) -> (YuriConnection<T...>),
	after: (signal: YuriSignal<T...>, disconnectAfterSeconds: number, callback: (T...) -> ()) -> (YuriConnection<T...>),
	wait: (signal: YuriSignal<T...>) -> (T...),
	waitUntil: (signal: YuriSignal<T...>, timeOut: number) -> (T...),
	fire: (signal: YuriSignal<T...>, T...) -> (),
	
	destroy: (signal: YuriSignal<T...>) -> ()
}

export type YuriConnection<T...> = {	
	connected: boolean,
	calls: number,
	disconnect: (connection: YuriConnection<T...>) -> ()
}

type privateYuriSignal<T...> = YuriSignal<T...> & {
	tail: privateYuriConnection<T...>?,
	head: privateYuriConnection<T...>?,
}

type privateYuriConnection<T...> = YuriConnection<T...> & {
	next: privateYuriConnection<T...>?,
	previous: privateYuriConnection<T...>?,
	signal: privateYuriSignal<T...>,
	disconnectAfter: number?,
	callback: (T...) -> (),
	eval: () -> ()?
}

local function disconnect<T...>(connection: privateYuriConnection<T...>)
	if not connection.connected then
		return
	end
	
	local nextConnection, previousConnection, signal = connection.next, connection.previous, connection.signal
	
	if nextConnection then
		nextConnection.previous = previousConnection
	else
		signal.head = previousConnection
	end
	
	if previousConnection then
		previousConnection.next = nextConnection
	else
		signal.tail = nextConnection
	end
	
	connection.connected = false
end

local function disconnectAll<T...>(signal: privateYuriSignal<T...>)
	signal.head = nil
	signal.tail = nil 
end

local function connect<T...>(signal: privateYuriSignal<T...>, callback: (T...) -> ()): (privateYuriConnection<T...>)
	local connection: privateYuriConnection<T...> = {
		disconnect = disconnect :: any,
		calls = 0,
		connected = true,
		signal = signal,
		next = signal.tail,
		callback = callback
	}
	
	if signal.tail then
		signal.tail.previous = connection
		signal.tail = connection
	else
		signal.head = connection
		signal.tail = connection
	end
	
	return connection
end

local function limit<T...>(signal: privateYuriSignal<T...>, amount: number, callback: (T...) -> ()): (privateYuriConnection<T...>)
	local connection = connect(signal, callback)
	
	connection.disconnectAfter = amount
	
	return connection
end

local function once<T...>(signal: privateYuriSignal<T...>, callback: (T...) -> ()): (privateYuriConnection<T...>)
	return limit(signal, 1, callback)
end


local function each<T...>(signal: privateYuriSignal<T...>, evaluationFunction: () -> (boolean), callback: (T...) -> ()): (privateYuriConnection<T...>)
	local connection = connect(signal, callback)

	connection.eval = evaluationFunction

	return connection
end

local function after<T...>(signal: privateYuriSignal<T...>, disconnectAfterSeconds: number, callback: (T...) -> ()): (privateYuriConnection<T...>)
	local connection = connect(signal, callback)
	
	task.delay(disconnectAfterSeconds, connection.disconnect, connection)
	
	return connection
end

local function wait<T...> (signal: privateYuriSignal<T...>): (T...)
	local t = coroutine.running()
	
	once(signal, function(...) 
		task.spawn(t, ...)	
	end)
	
	return coroutine.yield()
end

local function waitUntil<T...> (signal: privateYuriSignal<T...>, timeOut: number?): (T...)
	local t = coroutine.running()

	timeOut = timeOut or 5

	local connection = once(signal, function(...) 
		task.spawn(t, ...)	
	end)

	task.delay(timeOut, function()
		if not connection.connected then
			return
		end
		connection:disconnect()
		coroutine.resume(t)
	end)

	return coroutine.yield()
end

local function fire<T...>(signal: privateYuriSignal<T...>, ...: T...): ()
	local connection = signal.tail
	
	while connection do
		connection.calls += 1
		
		task.spawn(connection.callback, ...)
		
		if connection.eval and connection.eval() then
			local con = connection
			connection = connection.next
			con:disconnect()
			continue
		elseif connection.disconnectAfter and connection.calls >= connection.disconnectAfter then
			local con = connection
			connection = connection.next
			con:disconnect()
			continue
		end

		connection = connection.next
	end
end

local function destroy<T...>(signal: privateYuriSignal<T...>): ()
	signal:disconnectAll()
	table.clear(signal)
end

local yuriSignal = {}

function yuriSignal.new<T...>(): YuriSignal<T...>
	local signal: any = {
		connect = connect,
		limit = limit,
		once = once,
		each = each,
		after = after,
		
		wait = wait,
		waitUntil = waitUntil,
		
		fire = fire,
		disconnectAll = disconnectAll,
		destroy = destroy,
		
		tail = nil,
		head = nil
	}
	
	return signal :: YuriSignal<T...>
end

return yuriSignal
