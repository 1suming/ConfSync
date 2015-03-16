module(..., package.seeall)

MYSQL_CONF = {
	m_host 		= "192.168.100.167",
	m_port 		= 3388,
	m_db 		= "kslave",
	m_user 		= "root",
	m_password 	= "",
}

REDIS_CONF = {
	m_s_host 	= "192.168.100.167",
	m_n_port 	= 4501,
	m_n_timeout = 5,
}

REDIS_CONF_PLAY = {
    m_s_host 	= "10.66.46.174",
    m_n_port 	= 4502,
    m_n_timeout = 5,
}
