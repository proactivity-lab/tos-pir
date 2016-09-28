/**
 * RetriggeringPir configuration.
 *
 * @author Raido Pahtma
 * @license MIT
 */
generic configuration RetriggeringPirC(bool pullup, bool rising_edge, uint32_t timeout_ms, uint32_t retrigger_ms) {
	provides {
		interface Read<float>;
		interface Notify<float> as MovementStart;
		interface Notify<float> as MovementActive;
		interface Notify<float> as MovementEnd;
	}
	uses {
		interface GeneralIO as InterruptPin;
		interface GeneralIO as PowerPin;
		interface GpioInterrupt as Interrupt;
	}
}
implementation {

	components new RetriggeringPirP(pullup, rising_edge, timeout_ms, retrigger_ms) as PIR;

	Read = PIR.Read;
	MovementStart = PIR.MovementStart;
	MovementActive = PIR.MovementActive;
	MovementEnd = PIR.MovementEnd;

	PIR.PowerGPIO = PowerPin; // Wire to DummyGeneralIOC if not needed.
	PIR.InterruptGPIO = InterruptPin;
	PIR.Interrupt = Interrupt;

	components new TimerMilliC();
	PIR.Timer -> TimerMilliC;

}
