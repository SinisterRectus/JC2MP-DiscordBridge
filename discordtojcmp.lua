-- run this script with luvit

-- config ----------------------------------------------------------------------
local host = '127.0.0.1' -- localhost
local port = 7778 -- default port 7778
local guildId = '' -- enter guild ID here
local channelId = '' -- enter channel ID here
local token = '' -- your bot token
--------------------------------------------------------------------------------

local uv = require('uv')
local json = require('json')
local discordia = require('discordia')

local encode, decode = json.encode, json.decode
local f = string.format
local client = discordia.Client()
local udp = uv.new_udp()
local jcmp

client:on('ready', function()

	p('Logged in as ' .. client.user.username)

	local guild = client:getGuild(guildId)
	assert(guild, f('Discord guild with ID "%s" not found', guildId))
	local channel = guild:getTextChannel(channelId)
	assert(channel, f('Discord channel with ID "%s" not found', channelId))

	udp:bind(host, port)

	udp:recv_start(function(err, data, sender)
		assert(not err, err)
		if data == 'handshake' then
			jcmp = sender
			p(f('Connected to JCMP at %s on port %i', jcmp.ip, jcmp.port))
		elseif data then
			coroutine.wrap(function()
				data = decode(data)
				local content = f('[%s]: %s', data[1], data[2])
				if not channel:sendMessage(content) then
					client:warning('JCMP message dropped: ' .. content)
				end
			end)()
		end
	end)

	p(f('Listening for connections at %s on port %i', host, port))

end)

client:on('messageCreate', function(message)

	if not jcmp then return end
	local author = message.author
	if author == client.user then return end
	if not message.guild then return end
	if message.channel.id ~= channelId then return end

	udp:send(encode{author.username, message.content}, jcmp.ip, jcmp.port)

end)

client:run(token)
