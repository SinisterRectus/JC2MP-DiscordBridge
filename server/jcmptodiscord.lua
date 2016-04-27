-- run this script in a JC2MP module

local uv = require('luv')
local json = require('json')
local f = string.format

local colors = {
	tag = Color.DodgerBlue,
	player = Color.Orange,
	text = Color.White
}

local host = '127.0.0.1' -- localhost
local port = 7778 -- default port 7778
local delay = 1000 -- milliseconds
local queue = {}

local timer = uv.new_timer()
timer:start(delay, delay, function()
	if #queue > 0 then
		table.remove(queue, 1)()
	end
end)

Events:Subscribe('ModuleLoad', function()

	local discord = uv.new_tcp()
	print('Connecting...')
	discord:connect(host, port, function(err)
		assert(not err, err)
		print(f('Connected to Discord at %s on port %s', host, port))
		Events:Subscribe('PlayerChat', function(args)
			local data = json.encode({tostring(args.player), args.text})
			table.insert(queue, function()
				discord:write(data)
			end)
		end)
		discord:read_start(function(err, chunk)
			assert(not err, err)
			if chunk then
				local data = json.decode(chunk)
				Chat:Broadcast(
					'[Discord] ', colors.tag,
					data[1], colors.player,
					': ' .. data[2], colors.text
				)
			else
				discord:shutdown()
				discord:close()
				print('Discord disconnected')
			end
		end)
	end)

end)

Events:Subscribe('PreTick', function() uv.run('nowait') end)
