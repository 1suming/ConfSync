require("script/global")

package.cpath = package.cpath .. ";./lib/?.so"

local config 		= require("script/config")
local utils 		= require("script/utils")
local json 			= require("cjson")
local logger 		= require("script/logger")
local db            = require("script/db")

local __END__ 	= logger.__END__
local __BEGIN__ = logger.__BEGIN__
local __DEBUG__ = logger.__DEBUG__
local __INFO__ 	= logger.__INFO__
local __ERROR__ = logger.__ERROR__

local G 		= _G
local packet 	= packet
local os 		= os
local timer 	= timer
local table 	= table
local pairs 	= pairs
local ipairs 	= ipairs 
local string 	= string
local redis 	= redis

local l_t_socket_map 			= g_t_socket_map
local l_t_command_args 			= global_command_args

protocal_define_table = {
	C_DATA = { 0x1003, "dds", 	"client_id, eventid, data", 	"cmd_data_sync" },
}

function cmd_data_sync(_n_socket, _n_client_id, _n_event_id, _s_data)
	__BEGIN__("cmd_data_sync")
	__DEBUG__(string.format("socket: %d client_id: %d event_id: %u", _n_socket, _n_client_id, _n_event_id))
	__DEBUG__("DATA: ".._s_data)

	local config = json.decode(_s_data)

	if config then
		db.db_config_sync(config.sql)
	else
		__ERROR__("json parse failed: ".._s_data)
	end

	__END__("cmd_data_sync")

	return 0
end

