module(..., package.seeall)

local config = require("script/config")
local utils = require("script/utils")
local logger = require("script/logger")

local __END__ 	= logger.__END__
local __BEGIN__ = logger.__BEGIN__
local __DEBUG__ = logger.__DEBUG__
local __INFO__ 	= logger.__INFO__
local __ERROR__ = logger.__ERROR__

local mysql = mysql
local table = table
local G = _G
local string = string


local function clear_global_result_set()
	G["global_result_set"] = nil
end

local function is_result_empty()
	local l_t_result_set = G["global_result_set"]
	return utils.table.realsize(l_t_result_set) == 0 and true or false
end
	

function connect_mysql_svr()
    local l_ret = mysql.connect_mysql(config.MYSQL_CONF.m_host, 
    	config.MYSQL_CONF.m_user, config.MYSQL_CONF.m_password, config.MYSQL_CONF.m_db, config.MYSQL_CONF.m_port)
    if l_ret == -1 then 
		__ERROR__("connect mysql failed")
		return -1
	end
    return 0
end

function update_user_money_and_exp_level_2(in_n_uid, in_n_money_change, in_biswinner, in_n_exp, in_n_level)
	__DEBUG__("------ update_user_money_and_exp_level begin-----------")

	local l_sql_table = {}
	table.insert(l_sql_table,"UPDATE ks_membercash_info SET money=")
	local l_money_change_sql = in_n_money_change >= 0 and "money + "..in_n_money_change or "IF(money < abs("..in_n_money_change.."), 0, money"..in_n_money_change..")"
	table.insert(l_sql_table, l_money_change_sql)
	table.insert(l_sql_table, ", exp = "..in_n_exp)
	table.insert(l_sql_table, ", level = "..in_n_level)
	table.insert(l_sql_table, " where mid = ")
	table.insert(l_sql_table, tostring(in_n_uid))
	-- local l_wintimes_sql = in_biswinner and ", wintimes = wintimes + 1 where mid = "..in_n_uid or ", losetimes = losetimes + 1 where mid = "..in_n_uid
	-- table.insert(l_sql_table, l_wintimes_sql)

	local l_update_sql = table.concat(l_sql_table, nil)
	
	__DEBUG__("SQL: "..l_update_sql)

	__DEBUG__("------ update_user_money_and_exp_level end -----------")

	return mysql.query(l_update_sql)
end

-- add by Austin 2013-02-25
function update_user_money_and_exp_level(in_n_uid, in_n_money_change, in_biswinner, in_n_exp, in_n_level)
	__DEBUG__("------ update_user_money_and_exp_level begin-----------")

	local l_sql_table = {}
	table.insert(l_sql_table,"UPDATE ks_membercash_info SET money=")
	local l_money_change_sql = in_n_money_change >= 0 and " "..in_n_money_change or " "..0 
	table.insert(l_sql_table, l_money_change_sql)
	table.insert(l_sql_table, ", exp = "..in_n_exp)
	table.insert(l_sql_table, ", level = "..in_n_level)
	table.insert(l_sql_table, " where mid = ")
	table.insert(l_sql_table, tostring(in_n_uid))
	-- local l_wintimes_sql = in_biswinner and ", wintimes = wintimes + 1 where mid = "..in_n_uid or ", losetimes = losetimes + 1 where mid = "..in_n_uid
	-- table.insert(l_sql_table, l_wintimes_sql)

	local l_update_sql = table.concat(l_sql_table, nil)
	
	__DEBUG__("SQL: "..l_update_sql)

	__DEBUG__("------ update_user_money_and_exp_level end -----------")

	return mysql.query(l_update_sql)
end

function get_user_money(in_n_uid)
    local l_ret = mysql.query("select money from ks_membercash_info where mid = "..in_n_uid)
    if l_ret == -1 then
        return -1
    end
     
    local l_t_result_set = G["global_result_set"]
         
    return tonumber(l_t_result_set[1][1])
end

function get_user_mtkey(in_n_uid)
    local l_ret = mysql.query("select mtkey, tid, svid from ks_membertable where mid = " .. in_n_uid)
    
    if l_ret == -1 then
        return -1
    end
    
    local l_t_result_set = G["global_result_set"]
    
    if is_result_empty() then 
    	local l_mtkey = ""
    	local l_tid = 0
    	local l_svid = 0
    	return l_mtkey,tonumber(l_tid),tonumber(l_svid)
	else    
	    local l_mtkey = l_t_result_set[1][1]
	    local l_tid = l_t_result_set[1][2]
	    local l_svid = l_t_result_set[1][3]
    	return l_mtkey,tonumber(l_tid),tonumber(l_svid)
    end
end

function set_player_join(in_n_user_id, in_n_table_id, in_n_server_id)
    __BEGIN__("set_player_join")
    local __sql = string.format("call p_upd_member_table(%d, %d, %d)", in_n_user_id, in_n_table_id, in_n_server_id)
    
	local l_ret = mysql.query(__sql)
    
	__DEBUG__("SQL: ".. __sql)
    
    if l_ret == -1 then
        return -1
    end
    
    __END__("set_player_join")
    return 0
end

function set_player_leave(in_n_user_id)
	__BEGIN__("set_player_leave")
   local __sql = string.format("call p_upd_member_table(%d, %d, %d)", in_n_user_id, 0, 0)
    
	local l_ret = mysql.query(__sql)

	__DEBUG__("SQL: ".. __sql)
	
	if l_ret == -1 then
        return -1
    end
    
	__END__("set_player_leave")

    return 0
end

-- get user record
function get_user_info(in_n_uid)
	local l_sql = "select level, money, exp, wintimes, losetimes FROM ks_membercash_info where mid = "..in_n_uid
	
	local l_ret = mysql.query(l_sql)
	
	print(l_result_set)
	
	if l_ret == -1 then
		return -1, -1, -1, -1, -1, -1
	end
	
	local l_t_result_set = G["global_result_set"]
	
	if l_t_result_set == nil or l_t_result_set[1] == nil then
		__DEBUG__(string.format("User %d is not found.", in_n_uid))
		return 0, 0, 0, 0, 0, 0
	end
	
	local l_level = l_t_result_set[1][1]
	local l_money = l_t_result_set[1][2]
	local l_exp = l_t_result_set[1][3]
	local l_wintimes = l_t_result_set[1][4]
	local l_losetimes = l_t_result_set[1][5]
	
	clear_global_result_set()

	return 0, tonumber(l_level), tonumber(l_money), tonumber(l_exp), tonumber(l_wintimes), tonumber(l_losetimes)
end

function get_user_member_table(in_n_uid)
	local l_sql = "select svid, tid from ks_membertable where mid = "..in_n_uid
	
	__DEBUG__("SQL: "..l_sql)

	local l_ret = mysql.query(l_sql)

	if l_ret == -1 then
		return -1, -1, -1
	end
	
	local l_t_result_set = G["global_result_set"]
	
	-- if (l_t_result_set == nil) then
	-- 	return 0, 0, 0
	-- end

	if l_t_result_set == nil or l_t_result_set[1] == nil then
		__DEBUG__("result is null.")
		return 0, 0, 0
	end
	
	local l_sid = l_t_result_set[1][1]
	local l_tid = l_t_result_set[1][2]

	__DEBUG__("l_sid: "..l_sid)
	__DEBUG__("l_tid: "..l_tid)
	
	clear_global_result_set()

	return 0, tonumber(l_sid), tonumber(l_tid)
end

function user_off_line_insert_active(in_n_uid, in_n_active_time)
	local l_sql = "UPDATE ks_memberactivetime SET activetime= activetime + "..in_n_active_time.." WHERE mid="..in_n_uid
    
	local l_ret = mysql.query(l_sql)

	__DEBUG__("SQL: ".. l_sql)
	
	if l_ret == -1 then
        return -1
    end

    return 0
end

function reset_member_online(in_n_sid)
	local l_sql = "UPDATE ks_membertable SET tid=0, svid=0 WHERE svid = "..in_n_sid
	
	local l_ret = mysql.query(l_sql)

	__DEBUG__("SQL: ".. l_sql)
	
	if l_ret == -1 then
        return -1
    end

    return 0
end

function dec_user_interact_prop_num( in_n_pid )
	__DEBUG__("----------dec_user_interact_prop_num begin -------------------- "..in_n_pid)

	local l_sql = "UPDATE ks_memberprop SET pnum = pnum - 1 WHERE pid = in_n_pid"

	local l_ret = mysql.query(l_sql)

	__DEBUG__("SQL: "..l_sql)

	if l_ret == -1 then
		__DEBUG__("----------dec_user_interact_prop_num end1 --------------------")
		return -1
	end

	__DEBUG__("----------dec_user_interact_prop_num end --------------------")
	return 0
end

function db_config_sync(_s_sql)
	__BEGIN__("db_config_sync")
	local __ret = mysql.query(_s_sql)


	if __ret == -1 then
		__DEBUG__("db execute error: ".._s_sql)
	else
		__DEBUG__("db execute success.")
	end

	__END__("db_config_sync")

	return 0
end
	