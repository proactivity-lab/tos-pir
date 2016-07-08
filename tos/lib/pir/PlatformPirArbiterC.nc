/**
 * Platform PIR arbitration configuration.
 *
 * @author Raido Pahtma
 * @license MIT
 */
configuration PlatformPirArbiterC {
	provides {
		interface Read<float>[uint8_t id];
		interface Notify<float> as MovementStart[uint8_t id];
		interface Notify<float> as MovementActive[uint8_t id];
		interface Notify<float> as MovementEnd[uint8_t id];
	}
}
implementation {

	components new PlatformPirArbiterP(uniqueCount("PlatformPirClientC"));
	Read = PlatformPirArbiterP.Read;
	MovementStart = PlatformPirArbiterP.MovementStart;
	MovementActive = PlatformPirArbiterP.MovementActive;
	MovementEnd = PlatformPirArbiterP.MovementEnd;

	components PlatformPirC;
	PlatformPirArbiterP.SubRead -> PlatformPirC.Read;
	PlatformPirArbiterP.SubMovementStart -> PlatformPirC.MovementStart;
	PlatformPirArbiterP.SubMovementActive -> PlatformPirC.MovementActive;
	PlatformPirArbiterP.SubMovementEnd -> PlatformPirC.MovementEnd;

	components MainC;
	MainC.SoftwareInit -> PlatformPirArbiterP.Init;

}
