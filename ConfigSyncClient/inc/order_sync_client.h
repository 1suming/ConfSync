#ifndef __ORDER_SYNC_CLIENT_H_
#define __ORDER_SYNC_CLIENT_H_

#include <stdint.h>
#include <string>

using std::string;

class fetcher_t;
class CTcpClient;
class CMysqlHelper;
class poller_t;

typedef class CTcpClient 	tcp_client_t;
typedef class CMysqlHelper 	mysql_helper_t;

class order_sync_client_t {
public:
	order_sync_client_t(fetcher_t* f, tcp_client_t* c, mysql_helper_t* m, poller_t* p)
		:_f(f),
		_c(c),
		_m(m),
		_p(p)
	{
	}
	~order_sync_client_t();
public:
	int run();
private:
	fetcher_t 		*_f;
	tcp_client_t 	*_c;
	mysql_helper_t	*_m;
	poller_t		*_p;
};

#endif 
