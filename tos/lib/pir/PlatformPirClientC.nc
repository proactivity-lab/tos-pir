/**
 * Platform PIR client configuration.
 *
 * @author Raido Pahtma
 * @license MIT
 */
generic configuration PlatformPirClientC() {
	provides {
		interface Read<float>;
		interface Notify<float> as MovementStart;
		interface Notify<float> as MovementActive;
		interface Notify<float> as MovementEnd;
	}
}
implementation {

	enum {
		PLATFORM_PIR_CLIENT_ID = unique("PlatformPirClientC")
	};

	components PlatformPirArbiterC as Arbiter;
	Read = Arbiter.Read[PLATFORM_PIR_CLIENT_ID];
	MovementStart = Arbiter.MovementStart[PLATFORM_PIR_CLIENT_ID];
	MovementActive = Arbiter.MovementActive[PLATFORM_PIR_CLIENT_ID];
	MovementEnd = Arbiter.MovementEnd[PLATFORM_PIR_CLIENT_ID];

}
