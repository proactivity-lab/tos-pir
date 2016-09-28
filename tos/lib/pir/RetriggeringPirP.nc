/**
 * PIR module. Fires separate events for start and end. Also fires an active
 * event periodically every g_retrigger_ms if motion event does not end.
 *
 * @author Raido Pahtma
 * @license MIT
 */
generic module RetriggeringPirP(bool g_pullup, bool g_rising_edge, uint32_t g_timeout_ms, uint32_t g_retrigger_ms) {
	provides {
		interface Read<float>;
		interface Notify<float> as MovementStart;
		interface Notify<float> as MovementActive;
		interface Notify<float> as MovementEnd;
	}
	uses {
		interface GeneralIO as InterruptGPIO;
		interface GeneralIO as PowerGPIO;
		interface GpioInterrupt as Interrupt;
		interface Timer<TMilli>;
	}
}
implementation {

	#define __MODUUL__ "rpir"
	#define __LOG_LEVEL__ ( LOG_LEVEL_RetriggeringPirP & BASE_LOG_LEVEL )
	#include "log.h"

	enum state {
		ST_DISABLED,
		ST_WAITING_START,
		ST_TIMEOUT,
		ST_WAITING_END
	};

	typedef struct pir_state_t {
		uint8_t state: 5;
		bool start : 1;
		bool active : 1;
		bool end : 1;
	} pir_state_t;

	pir_state_t m_pir = { ST_DISABLED, FALSE, FALSE, FALSE};

	uint32_t m_timestamp = 0;

	float m_count = 0;

	task void readDone()
	{
		signal Read.readDone(SUCCESS, m_count);
	}

	command error_t Read.read()
	{
		post readDone();
		return SUCCESS;
	}

	/**
	 * Enable rising edge, if event starts with rising edge and start detection is requested.
	 * Enable falling edge, if evnet starts with falling edge and start detection is requested.
	 * @param start - request start detection
	 */
	void enable(bool start)
	{
		if(g_rising_edge)
		{
			if(start)
			{
				debug1("rer");
				call Interrupt.enableRisingEdge();
			}
			else
			{
				debug1("ref");
				call Interrupt.enableFallingEdge();
			}
		}
		else
		{
			if(start)
			{
				debug1("fef");
				call Interrupt.enableFallingEdge();
			}
			else
			{
				debug1("fer");
				call Interrupt.enableRisingEdge();
			}
		}
	}

	task void enableTask()
	{
		enable(TRUE);
	}

	void enableNotify()
	{
		if((m_pir.start || m_pir.active || m_pir.end) && (m_pir.state == ST_DISABLED))
		{
			m_pir.state = ST_WAITING_START;
			if(g_pullup)
			{
				debug1("set");
				call InterruptGPIO.set();
			}
			else
			{
				debug1("clr");
				call InterruptGPIO.clr();
			}
			call PowerGPIO.makeOutput();
			call PowerGPIO.set();
			post enableTask();
			// TODO wait for the PIR to actually start up
		}
	}

	command error_t MovementStart.enable()
	{
		if(!m_pir.start)
		{
			m_pir.start = TRUE;
			enableNotify();
			return SUCCESS;
		}
		return EALREADY;
	}

	command error_t MovementActive.enable()
	{
		if(!m_pir.active)
		{
			m_pir.active = TRUE;
			enableNotify();
			return SUCCESS;
		}
		return EALREADY;
	}

	command error_t MovementEnd.enable()
	{
		if(!m_pir.end)
		{
			m_pir.end = TRUE;
			enableNotify();
			return SUCCESS;
		}
		return EALREADY;
	}

	void disableNotify()
	{
		if(!m_pir.start && !m_pir.active && !m_pir.end && (m_pir.state != ST_DISABLED))
		{
			m_pir.state = ST_DISABLED;
			m_count = 0;
			call Timer.stop();
			call Interrupt.disable();
			call InterruptGPIO.clr();
			call PowerGPIO.makeInput();
			call PowerGPIO.clr();
		}
	}

	command error_t MovementStart.disable()
	{
		if(m_pir.start)
		{
			m_pir.start = FALSE;
			disableNotify();
			return SUCCESS;
		}
		return EALREADY;
	}

	command error_t MovementActive.disable()
	{
		if(m_pir.active)
		{
			m_pir.active = FALSE;
			disableNotify();
			return SUCCESS;
		}
		return EALREADY;
	}

	command error_t MovementEnd.disable()
	{
		if(m_pir.end)
		{
			m_pir.end = FALSE;
			disableNotify();
			return SUCCESS;
		}
		return EALREADY;
	}

	event void Timer.fired()
	{
		switch(m_pir.state)
		{
			case ST_TIMEOUT:
				if(call InterruptGPIO.get() == g_rising_edge)
				{
					debug1("t wait end");
					m_pir.state = ST_WAITING_END;
					enable(FALSE);
					if(call Timer.getNow() - m_timestamp >= g_retrigger_ms)
					{
						debug1("t retrig");
						m_count++;
						if(m_pir.active)
						{
							signal MovementActive.notify(m_count);
						}
					}
					call Timer.startOneShot(g_retrigger_ms);
				}
				else
				{
					info2("t end %"PRIu32, call Timer.getNow() - m_timestamp);
					info1("input[0]");
					if(m_pir.end)
					{
						signal MovementEnd.notify(m_count);
					}
					m_pir.state = ST_WAITING_START;
					enable(TRUE);
				}
				break;
			case ST_WAITING_END:
				info2("t active %"PRIu32, (uint32_t)m_count);
				m_count++;
				if(m_pir.active)
				{
					signal MovementActive.notify(m_count);
				}
				call Timer.startOneShot(g_retrigger_ms);
				break;
			default:
				err1("dflt");
				break;
		}
	}

	task void fired()
	{
		switch(m_pir.state)
		{
			case ST_WAITING_START:
				m_count++;
				m_timestamp = call Timer.getNow();
				info2("i start %"PRIu32, (uint32_t)m_count);
				info1("input[1]");
				m_pir.state = ST_TIMEOUT;
				if(m_pir.start)
				{
					signal MovementStart.notify(m_count);
				}
				call Timer.startOneShot(g_timeout_ms);
				break;
			case ST_WAITING_END:
				info2("i end %"PRIu32, call Timer.getNow() - m_timestamp);
				info1("input[0]");
				call Timer.stop();
				if(m_pir.end)
				{
					signal MovementEnd.notify(m_count);
				}
				m_pir.state = ST_WAITING_START;
				enable(TRUE);
				break;
			default:
				err1("dflt");
		}
	}

    async event void Interrupt.fired()
    {
    	call Interrupt.disable();
		post fired();
    }

    default event void Read.readDone(error_t result, float value) { }
    default event void MovementStart.notify(float value) { }
    default event void MovementActive.notify(float value) { }
    default event void MovementEnd.notify(float value) { }

}
