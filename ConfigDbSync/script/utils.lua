module(..., package.seeall)

local uuid = uuid

local table = table

function table.find(t, key)
    if type(t) == "table" then 
        for k, val in ipairs(t) do
            if val ~=nil then
                if type(val) == "table" and val[1] == key then
                    return k
                elseif val == key then
                    return k
                end
            end
        end 
    end 
    return 0
end

function table.merge(t1,t2)
    for i,v in pairs(t2) do
        if type(v) == "table" and 0 == table.find(t1, v[1]) then
           table.insert(t1,v) 
        elseif 0 == table.find(t1, v) then
            table.insert(t1,v)
        end
    end
    return t1 
end

-- 给库table 添加方法
function table.realsize(in_t_table)
    if in_t_table == nil then 
    	return 0
    end
    
    local l_size = 0
    
    for k,v in pairs(in_t_table) do
        l_size = l_size + 1
    end
    
    return l_size
end

function table.clear(in_t_table)
	if in_t_table == nil then
		return
	end
    
    for k, v in pairs(in_t_table) do
        in_t_table[k] = nil
    end	
end

function table.copy(in_t_dest_1, in_t_src_2)
    if nil == in_t_dest_1 or nil == in_t_src_2 then
        return 0
    end

    for k, v in pairs(in_t_src_2) do
        table.insert(in_t_dest_1, v)
    end
end



function os.sleep(in_n_sec)
	if in_n_sec == 0 then 
		return 0
	end

	os.execute("sleep "..in_n_sec)
end

function os.usleep(in_n_usec)
	if in_n_usec == 0 then
		return 0
	end
	
	os.execute("usleep "..in_n_usec)
end

function get_uuid()
	
	uuid.NewUUID()

	local l_uuid_result = global_uuid_result
	
	local l_s_uuid = l_uuid_result ~= nil and l_uuid_result or "*"
		
	log.debug("UUID:"..l_s_uuid)
	
	return l_s_uuid
end

function math.rounding(in_n_number)
    local math = math

    if in_n_number > (math.floor(in_n_number) + 0.4) then
        return math.floor(in_n_number) + 1
    else
        return math.floor(in_n_number)
    end
end