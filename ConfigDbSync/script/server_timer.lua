--module(..., package.seeall)

require("script/global")

local game_timer = require("script/game_timer")
local cb = require("script/callback")
local logger = require("script/logger")
local G = _G

local __END__ 	= logger.__END__
local __BEGIN__ = logger.__BEGIN__
local __DEBUG__ = logger.__DEBUG__
local __INFO__ 	= logger.__INFO__
local __ERROR__ = logger.__ERROR__

function start_conn_timer(in_n_socket)
	__DEBUG__("start_conn_timer")
	if G["g_t_conn_timer_map"][in_n_socket] ~= nil then
		stop_conn_timer(in_n_socket)
	end
	
	G["g_t_conn_timer_map"][in_n_socket] = 
		game_timer.start_timer{ m_n_second = TIME_OUT_VALUE.TIME_HEART, 
								m_t_params = { in_n_socket, }, 
								m_f_callback = cb.cb_server_conn_timeout
		}
end

function stop_conn_timer(in_n_socket)
	if in_n_socket == nil then
		return 0
	end
	
	if G["g_t_conn_timer_map"][in_n_socket] ~= nil then
		game_timer.stop_timer(G["g_t_conn_timer_map"][in_n_socket])
	end 
	
	return 0
end