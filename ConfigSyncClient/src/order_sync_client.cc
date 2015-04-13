#include "order_sync_client.h"
#include "packet.h"
#include "log.h"
#include "fetcher.h"
#include "TcpClient.h"
#include "MysqlHelper.h"
#include "poller.h"
#include "json/json.h"
#include "conf.h"
#define __STDC_FORMAT_MACROS // PRIu64
#include <inttypes.h>
#include <sys/epoll.h>
#include <errno.h>

#ident "\\n$@           ID : chenbo.o v1.3 (25/08/07)@$\\n"


using namespace Json;

extern conf_t g_conf;

#define __FREE_TIME		1000 * 1000 // 1s 无数据时休眠时间
#define __EXEC_TIME 	10 * 1000 // 10ms  处理完一条记录后睡眠的时间
#define __CMD_DATA_SYNC 0x0002
#define __ERROR_TIMES 	200
#define __ERROR_TIME 	25 * 1000

#ifndef ALLOC
#define ALLOC(P, SZ) P = (__typeof__(P))malloc(SZ); if (P) memset(P, 0, SZ)
#endif

#define UNUSED(x) (void)x

order_sync_client_t::
~order_sync_client_t()
{
	delete _f;delete _c;delete _m;delete _p;
}

int
order_sync_client_t::run()
{
	packet_t 			out, in;
	string 				json;
	int					r, rr;
	Reader				reader;
	Value 				value;
	FastWriter			writer;
	struct epoll_event 	*events;
	int					ev_nums;
	char				*rbuff;
	int 				r_errs;
	string 				table;
	
	ALLOC(rbuff, 1024);

	_c->readable(true);
	_c->writeable(true);
	_p->attach(_c);
	
	UNUSED(rr);	
	
	while (1) {
		ev_nums = _p->wait(100);

		if (ev_nums <= 0) continue;

		events = _p->get_events();

		r_errs = 0;

		if (events[0].events & READABLE) {
			if (_c->check() == 0) {
				_c->Disconneced();
				_c->Close();
				_p->detach(_c);
				log_error("Tcp connection closed.");

				sleep(1);

				if (_c->Reconnect() == 0) {
					_c->readable(true);
					_c->writeable(true);
					_p->attach(_c);
				}
			}
		}

		if (events[0].events & WRITEABLE) {
			if (_f) {
				json = _f->fetch(g_conf.redis_key);
				
				if (!json.empty()) {
					if (!reader.parse(json, value)) {
						log_error("json: %s parse failed.", json.c_str());
						continue;
					}
					
					log_debug("JSON: %s LEN: %d", json.c_str(), json.size());
			
					out.begin(__CMD_DATA_SYNC);
					out.write_int(g_conf.client_id);
					out.write_string(json);
					out.end();

					if (_c) {
					send:
						r = _c->Send(out.get_data(), out.get_len());
						log_debug("SEND: %d", r);
						if (r == 0) {
							_c->Disconneced();
							_c->Close();
							if (_c->Reconnect() == 0) {
								_c->readable(true);
								_c->writeable(true);
								_p->attach(_c);

								goto send;
							} else {
								log_error("connected server failed");
								sleep(5);/*  重连失败后等待5s*/
								goto send;
							}
						}

						out.clean();
						usleep(__EXEC_TIME);
					} else {
						usleep(__FREE_TIME);
					}
				}
			} 
		}
	} // while
	
	free(rbuff);
	return 0;
}
