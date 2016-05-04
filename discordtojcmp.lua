-- run this script with luvit

local uv = require('uv')
local json = require('json')
local discordia = require('discordia')
local f = string.format
local client = discordia.Client:new()
local jcmp

local host = '127.0.0.1' -- localhost
local port = 7778 -- default port 7778
local serverName = '' -- enter server name here
local channelName = '' -- enter channel name here

client:on('ready', function()

	p('Logged in as ' .. client.user.username)

	local server = client:getServerByName(serverName)
	assert(server, f('Discord server with name "%s" not found', serverName))
	local channel = server:getTextChannelByName(channelName)
	assert(channel, f('Discord channel with name "%s" not found', channelName))

	local bridge = uv.new_tcp()
	bridge:bind(host, port)
	bridge:listen(128, function(err)
		assert(not err, err)
		jcmp = uv.new_tcp()
		bridge:accept(jcmp)
		p('JC2MP connected')
		jcmp:read_start(function(err, chunk)
			assert(not err, err)
			if chunk then
				coroutine.wrap(function()
					local data = json.decode(chunk)
					local content = f('[%s]: %s', data[1], data[2])
					if not pcall(function()
						channel:sendMessage(content)
					end) then
						p('Message dropped: ' .. content)
					end
				end)()
			else
				jcmp:shutdown()
				jcmp:close()
				p('JC2MP disconnected')
			end
		end)
	end)

	p(f('TCP server listening at %s on port %i', host, port))

end)

client:on('messageCreate', function(message)

	if not jcmp then return end
	if not message.server then return end
	if message.author == client.user then return end
	if message.server.name ~= serverName then return end
	if message.channel.name ~= channelName then return end

	local data = json.encode({message.author.username, message.content})
	jcmp:write(data)

end)

client:run('') -- email and password or token
