package;

using api.IdeckiaApi;
using StringTools;

typedef Props = {
	@:shared
	@:editable("Server of the Mastodon instance", "https://mastodon.social")
	var server:String;
	@:shared
	@:editable("Access token value")
	var accessToken:String;
	@:editable("Text to publish")
	var tootText:String;
}

@:name("toot")
@:description("Publish a toot in mastodon")
class Toot extends IdeckiaAction {
	static inline final API_URL:String = 'api/v1';

	public override function init(initialState:ItemState):js.lib.Promise<ItemState> {
		if (!props.server.endsWith('/'))
			props.server += '/';

		return super.init(initialState);
	}

	public function execute(currentState:ItemState):js.lib.Promise<ItemState> {
		return new js.lib.Promise((resolve, reject) -> {
			var endpoint = props.server + '$API_URL/statuses';

			var http = new haxe.http.HttpNodeJs(endpoint);

			http.addHeader('Authorization', 'Bearer ' + props.accessToken);
			http.addHeader("Content-type", "application/json");

			http.setPostData(haxe.Json.stringify({
				status: props.tootText
			}));

			http.onError = reject;

			http.request(true);

			server.log.debug("Mastodon publish response: " + http.responseData);
			resolve(currentState);
		});
	}
}
