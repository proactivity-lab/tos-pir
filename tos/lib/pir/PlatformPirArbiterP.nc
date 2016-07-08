/**
 * Platform PIR arbitration module.
 *
 * @author Raido Pahtma
 * @license MIT
 */
generic module PlatformPirArbiterP(uint8_t client_count) {
	provides {
		interface Read<float>[uint8_t id];
		interface Notify<float> as MovementStart[uint8_t id];
		interface Notify<float> as MovementActive[uint8_t id];
		interface Notify<float> as MovementEnd[uint8_t id];
		interface Init @exactlyonce();
	}
	uses {
		interface Read<float> as SubRead;
		interface Notify<float> as SubMovementStart;
		interface Notify<float> as SubMovementActive;
		interface Notify<float> as SubMovementEnd;
	}
}
implementation {

	#define __MODUUL__ "pira"
	#define __LOG_LEVEL__ ( LOG_LEVEL_PlatformPirArbiterP & BASE_LOG_LEVEL )
	#include "log.h"

	typedef struct arbiter_state {
		bool reading      : 1;
		bool notify_start : 1;
		bool notify_active: 1;
		bool notify_end   : 1;
	} arbiter_state_t;

	arbiter_state_t m[client_count];
	bool m_reading;

	bool startRequired() {
		uint8_t i;
		for(i=0;i<client_count;i++) {
			if(m[i].notify_start) {
				return TRUE;
			}
		}
		return FALSE;
	}

	bool activeRequired() {
		uint8_t i;
		for(i=0;i<client_count;i++) {
			if(m[i].notify_active) {
				return TRUE;
			}
		}
		return FALSE;
	}

	bool endRequired() {
		uint8_t i;
		for(i=0;i<client_count;i++) {
			if(m[i].notify_end) {
				return TRUE;
			}
		}
		return FALSE;
	}

	command error_t Init.init() {
		uint8_t i;
		for(i=0;i<client_count;i++) {
			m[i].reading       = FALSE;
			m[i].notify_start  = FALSE;
			m[i].notify_active = FALSE;
			m[i].notify_end    = FALSE;
		}
		m_reading = FALSE;
		return SUCCESS;
	}

	command error_t Read.read[uint8_t id]() {
		debug1("r[%u]", id);
		if(m[id].reading == FALSE) {
			error_t err = m_reading ? SUCCESS : call SubRead.read();
			if(err == SUCCESS) {
				m_reading = TRUE;
				m[id].reading = TRUE;
			}
			return err;
		}
		return EALREADY;
	}

	event void SubRead.readDone(error_t result, float value) {
		uint8_t i;
		for(i=0;i<client_count;i++) {
			if(m[i].reading) {
				m[i].reading = FALSE;
				debug1("rd[%u]", i);
				signal Read.readDone[i](result, value);
			}
		}
		m_reading = FALSE;
	}

	default event void Read.readDone[uint8_t id](error_t result, float value) { }

	command error_t MovementStart.enable[uint8_t id]() {
		error_t err = SUCCESS;
		if(startRequired() == FALSE) {
			err = call SubMovementStart.enable();
		}
		if((err == SUCCESS) || (err == EALREADY)) {
			m[id].notify_start = TRUE;
		}
		return err;
	}

	command error_t MovementStart.disable[uint8_t id]() {
		m[id].notify_start = FALSE;
		if(startRequired() == FALSE) {
			call SubMovementStart.disable();
		}
		return SUCCESS;
	}

	event void SubMovementStart.notify(float value) {
		uint8_t i;
		for(i=0;i<client_count;i++) {
			if(m[i].notify_start) {
				debug1("ms[%u]", i);
				signal MovementStart.notify[i](value);
			}
		}
	}

	default event void MovementStart.notify[uint8_t id](float value) { }

	command error_t MovementActive.enable[uint8_t id]() {
		error_t err = SUCCESS;
		if(activeRequired() == FALSE) {
			err = call SubMovementActive.enable();
		}
		if((err == SUCCESS) || (err == EALREADY)) {
			m[id].notify_active = TRUE;
		}
		return err;
	}

	command error_t MovementActive.disable[uint8_t id]() {
		m[id].notify_active = FALSE;
		if(activeRequired() == FALSE) {
			call SubMovementActive.disable();
		}
		return SUCCESS;
	}

	event void SubMovementActive.notify(float value) {
		uint8_t i;
		for(i=0;i<client_count;i++) {
			if(m[i].notify_active) {
				debug1("ma[%u]", i);
				signal MovementActive.notify[i](value);
			}
		}
	}

	default event void MovementActive.notify[uint8_t id](float value) { }

	command error_t MovementEnd.enable[uint8_t id]() {
		error_t err = SUCCESS;
		if(endRequired() == FALSE) {
			err = call SubMovementEnd.enable();
		}
		if((err == SUCCESS) || (err == EALREADY)) {
			m[id].notify_end = TRUE;
		}
		return err;
	}

	command error_t MovementEnd.disable[uint8_t id]() {
		m[id].notify_end = FALSE;
		if(endRequired() == FALSE) {
			call SubMovementEnd.disable();
		}
		return SUCCESS;
	}

	event void SubMovementEnd.notify(float value) {
		uint8_t i;
		for(i=0;i<client_count;i++) {
			if(m[i].notify_end) {
				debug1("me[%u]", i);
				signal MovementEnd.notify[i](value);
			}
		}
	}

	default event void MovementEnd.notify[uint8_t id](float value) { }

}
