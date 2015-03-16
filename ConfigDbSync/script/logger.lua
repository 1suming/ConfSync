module(..., package.seeall)

local log = log

local G = _G
local l_flag_log_level = G["g_flag_log_level"]
local l_t_log_level = G["g_t_log_level"]

local function _debug(in_s_msg)
	if l_flag_log_level < l_t_log_level.DEBUG then
		return
	else
		log.debug(in_s_msg)
	end
end

local function _info(in_s_msg)
	if l_flag_log_level < l_t_log_level.INFO then
		return
	else
		log.debug(in_s_msg)
	end	
end

local function _error(in_s_msg)
	log.debug(in_s_msg)
end

function __BEGIN__(in_s_msg, in_s_tag)
	local __tag = in_s_tag and tostring(in_s_tag) or ""
	_debug("---------- "..in_s_msg.." begin "..__tag.." ----------")
end

function __END__(in_s_msg, in_s_tag)
	local __tag = in_s_tag and tostring(in_s_tag) or ""
	_debug("---------- "..in_s_msg.." end "..__tag.." ----------")	
end

function __DEBUG__(in_s_msg)
	_debug(in_s_msg)
end

function __INFO__(in_s_msg)
	_info(in_s_msg)
end

function __ERROR__(in_s_msg)
	_error(in_s_msg)
end
	
	