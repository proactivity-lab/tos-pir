/**
 * RetriggeringPir configuration.
 *
 * @author Raido Pahtma
 * @license ProLab
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
		interface GpioInterrupt as Interrupt;
	}
}
implementation {

	components new RetriggeringPirP(pullup, rising_edge, timeout_ms, retrigger_ms) as PIR;

	Read = PIR.Read;
	MovementStart = PIR.MovementStart;
	MovementActive = PIR.MovementActive;
	MovementEnd = PIR.MovementEnd;

	PIR.GeneralIO = InterruptPin;
	PIR.Interrupt = Interrupt;

	components new TimerMilliC();
	PIR.Timer -> TimerMilliC;

}
