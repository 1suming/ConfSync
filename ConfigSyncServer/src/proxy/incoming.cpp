#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <errno.h>
#include "incoming.h"
#include "memcheck.h"
#include "listener.h"
#include <config.h>
#include "log.h"
#include "Singleton.h"
#include "MarkupSTL.h"
#include "helper_unit.h"
#include <string>
using std::string;
#include "CHelper_pool.h"
#include "RealTimer.h"
#include "redis_helper.h"

#include <sstream>
#include <iostream>
#include <fstream>


HTTP_SVR_NS_BEGIN


extern CHelperPool*			_helperpool;
extern CRealTimer* 			_RealTimer;
extern CLevelCountTimer*	_LevelCountTimer;
extern server_stat_t		*gSvrStat;

CIncoming::CIncoming (void) :
_pollerunit (NULL),
_listener (NULL),
_timerunit (NULL),
_webtimerlist (NULL),
_helpertimerlist (NULL),
_epwaittimeout (1000)
{  
}

CIncoming::~CIncoming (void) 
{
    DELETE (_timerunit);
    DELETE (_listener);
    DELETE (_pollerunit);
}

CIncoming* CIncoming::Instance (void)
{
    return CSingleton<CIncoming>::Instance ();
}

void CIncoming::Destroy (void)
{
    return CSingleton<CIncoming>::Destroy ();
}

int CIncoming::open (void)
{ 
    //create poller unit
    NEW (CPollerUnit(TGlobal::_maxpoller), _pollerunit);

    if (NULL == _pollerunit)
    {
        log_boot ("create CPollerUnit object failed.");

        return -1;
    }

    //create listener
    NEW (CListener(TGlobal::_addr, TGlobal::_port, MAX_ACCEPT_COUNT), _listener);

    if (NULL == _listener)
    {
        log_boot ("create CListener object failed.");

        return -1;
    }

    //create CTimerUnit object
    NEW (CTimerUnit(), _timerunit);
    if (NULL == _timerunit)
    {
        log_boot ("create CTimerUnit object failed.");
        return -1;
    }

	_realtimerlist = _timerunit->GetTimerList(60);
	
	_RealTimer->realTimerlist = _realtimerlist;
	_RealTimer->AttachTimer(_realtimerlist);

    //create web timer list
    _webtimerlist = _timerunit->GetTimerList (TGlobal::_webtimeout);
	
    if (NULL == _webtimerlist)
    {
        log_boot ("create web CTimerList object failed.");
        return -1;
    }

    _helpertimerlist = _timerunit->GetTimerList (TGlobal::_helpertimeout);

    if (NULL == _helpertimerlist)
    {
        log_boot ("create helper CTimerList object failed.");
        return -1;
    }
           
    //init poller unit
    if(_pollerunit->InitializePollerUnit() < 0) // _pollerunit 初始化
    {
        log_boot ("poller unit init failed.");
      	return -1;
    }
    
    //attach decoder unit  listener 关联 epoll
    if (_listener->Attach (_pollerunit, _webtimerlist, _helpertimerlist, TGlobal::_backlog) < 0)
    {
        log_boot ("invoke CListener::Attach() failed.");
        return -1;
    }
	
	//init hall connect logic server
	if(InitHelperUnit() < 0) {
		log_boot ("InitHelperUnit failed.");
        return -1;
	}
	/* _LevelCountTimer->SetTimerList(_timerunit->GetTimerList(60*5));
	_LevelCountTimer->SetHelperTimerList(_helpertimerlist);
	_LevelCountTimer->StartTimer();
	_LevelCountTimer->SendGetLevelCount(); 
	*/ 
    return 0;

}

int CIncoming::InitHelperUnit() // called by CIncoming::open()  初始化 server.xml
{
	CMarkupSTL  markup;
    if(!markup.Load("../conf/server.xml")) {       
        log_boot("Load server.xml failed.");
        return -1;
    }

    if(!markup.FindElem("SYSTEM")) {
        log_boot("Can not FindElem [SYSTEM] in server.xml failed.");
        return -1;
    }

	if (!markup.IntoElem()) {        
		log_boot ("IntoElem [SYSTEM] failed.");       
		return -1;    
	}
	
	if(markup.FindElem("Node")) {
		if (!markup.IntoElem()) {        
			log_boot ("IntoElem failed.");       
			return -1;    
		}

		if(!markup.FindElem("ServerList")) {
			log_boot ("FindElem [ServerList] failed.");     
			return -1; 
		}
		
		if (!markup.IntoElem()) {        
			log_boot ("IntoElem [ServerList] failed.");       
			return -1;    
		}
		
		while(markup.FindElem("Server")) {
			int 		svid 	=  atoi(markup.GetAttrib("svid").c_str());
			string 		ip 		= markup.GetAttrib("ip");
			int 		port 	= atoi(markup.GetAttrib("port").c_str());
			CHelperUnit *helper = NULL;

			map<int, CHelperUnit*>::iterator iter = _helperpool->m_helpermap.find(svid);
			if(iter != _helperpool->m_helpermap.end()) {
				helper = iter->second;
			} else {
				helper = new CHelperUnit(_pollerunit);
				_helperpool->m_helpermap[svid] = helper;
			}

			_helperpool->m_svidlist.push_back(svid);

			helper->addr = ip;
			helper->port = port;

			if (helper->connect() != 0) {
				log_boot("svid:[%d] ip:[%s] port:[%d] connect failed.", svid, ip.c_str(), port);
				return -1;
			}

			log_boot("redis id:[%d], ip:[%s], port:[%d]", svid, ip.c_str(), port);
		}

		if (!markup.OutOfElem()) {        
			log_boot ("OutOfElem [RedisList] failed.");       
			return -1;    
		}
	}

	if (!markup.OutOfElem()) {        
		log_boot ("OutOfElem [Node] failed.");       
		return -1;    
	}

	return 0;
}

int CIncoming::run(void)
{
    while(!(*(TGlobal::_module_close))) {
        _pollerunit->WaitPollerEvents (_timerunit->ExpireMicroSeconds(_epwaittimeout));
        //uint64_t now = GET_TIMESTAMP();
        _pollerunit->ProcessPollerEvents();
        //_timerunit->CheckExpired(now);
        //_timerunit->CheckPending();
    }

    return 0;
}

int
CIncoming::_active_helper(const int _level, const int _svid)
{
	CHelperUnit		*h;
	NETOutputPacket out;
	CEncryptDecrypt ed;


	log_debug("-------- CIncoming::_active_helper begin --------");
	switch (_level) {
		case 1:
			log_debug("active waiter begin [%d]", _svid);
			h = _helperpool->m_helpermap[_svid];
			if (h) {
				out.Begin(INTER_CMD_WAITER_STAT_REQ);
				out.End();
				ed.EncryptBuffer(&out);

				h->append_pkg(out.packet_buf(), out.packet_size());
				h->send_to_logic();
			}
			log_debug("active waiter end");
			break; 
		case 2:
			log_debug("active notify begin [%d]", _svid);
			h = _helperpool->m_helpermap[_svid];
			if (h) {
				out.Begin(INTER_CMD_NOTIFY_STAT_REQ);
				out.End();
				ed.EncryptBuffer(&out);

				h->append_pkg(out.packet_buf(), out.packet_size());
				h->send_to_logic();
			}
			log_debug("active notify end");
			break;
		default:
			break;
	}

	log_debug("-------- CIncoming::_active_helper end --------");
	return 0;
}

HTTP_SVR_NS_END

