package;

import js.node.buffer.Buffer;

using StringTools;
using api.IdeckiaApi;

typedef Props = {
	@:shared('mastodon.server')
	@:editable("prop_server", "https://mastodon.social")
	var server:String;
	@:shared('mastodon.token')
	@:editable("prop_access_token")
	var access_token:String;
	@:editable("prop_toot_text")
	var toot_text:String;
	@:editable("prop_toot_image_paths")
	var toot_image_paths:Array<String>;
}

typedef Attachment = {
	// ID of the attachment
	var id:String;
	// One of: "image", "video", "gifv"
	var type:String;
	// URL of the locally hosted version of the image
	var url:String;
	// For remote images, the remote URL of the original image
	var remote_url:String;
	// URL of the preview image
	var preview_url:String;
	// Shorter URL for the image, for insertion into text (only present on local images)
	var text_url:String;
}

@:name("toot")
@:description("action_description")
@:localize
class Toot extends IdeckiaAction {
	static inline final API_URL:String = 'api/v1';
	static inline final STATUSES_PATH:String = 'statuses';
	static inline final MEDIA_PATH:String = 'media';

	public override function init(initialState:ItemState):js.lib.Promise<ItemState> {
		if (!props.server.endsWith('/'))
			props.server += '/';

		return super.init(initialState);
	}

	public function execute(currentState:ItemState):js.lib.Promise<ActionOutcome> {
		return new js.lib.Promise((resolve, reject) -> {
			var tootText = props.toot_text;

			var tootData = {
				status: tootText,
				media_ids: []
			};

			function postToot() {
				postStatus(tootData).then(d -> {
					core.log.debug("Mastodon publish response: " + d);
					resolve(new ActionOutcome({state: currentState}));
				}).catchError(reject);
			}

			if (tootText == '') {
				core.dialog.entry(Loc.dialog_toot_text_title.tr(), Loc.dialog_toot_text_body.tr()).then(response -> {
					switch response {
						case Some(t):
							tootData.status = t;
							processMedia().then(mediaIds -> {
								tootData.media_ids = mediaIds;
								postToot();
							}).catchError(reject);
						case None:
					}
				});
			} else {
				processMedia().then(mediaIds -> {
					tootData.media_ids = mediaIds;
					postToot();
				}).catchError(reject);
			}
		});
	}

	function processMedia() {
		return new js.lib.Promise<Array<String>>((resolve, reject) -> {
			if (props.toot_image_paths != null && props.toot_image_paths.length != 0) {
				var mediaPromises = [
					for (p in props.toot_image_paths)
						uploadMedia(p)
				];

				js.lib.Promise.all(mediaPromises).then(attachments -> {
					resolve([
						for (a in attachments)
							a.id
					]);
				}).catchError(reject);
			} else {
				resolve([]);
			}
		});
	}

	function prepareRequest(path:String) {
		var endpoint = props.server + '$API_URL/$path';
		var http = new haxe.Http(endpoint);
		http.addHeader('Authorization', 'Bearer ${props.access_token}');
		return http;
	}

	function postStatus(status:Any):js.lib.Promise<String> {
		return new js.lib.Promise((resolve, reject) -> {
			var http = prepareRequest(STATUSES_PATH);
			http.addHeader('Content-Type', 'application/json');
			http.setPostData(haxe.Json.stringify(status));
			http.onError = reject;
			http.onData = resolve;
			http.request(true);
		});
	}

	function uploadMedia(filePath:String):js.lib.Promise<Attachment> {
		return new js.lib.Promise((resolve, reject) -> {
			var http = prepareRequest(MEDIA_PATH);

			var boundaryKey = Std.string(Math.random() * 0xFFFFFF);
			var boundary = '--${boundaryKey}';
			http.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundary);

			var multipartBody = prepareMultipartBody(filePath, boundary);
			http.setPostBytes(multipartBody.hxToBytes());
			http.onError = (e) -> reject('Error uploading media [$filePath]: $e.');
			http.onData = (d) -> {
				var attachment:Attachment = haxe.Json.parse(d);
				core.log.debug('Uploaded attachment: ${attachment.id}');
				resolve(attachment);
			}
			http.request(true);
		});
	}

	function prepareMultipartBody(filePath:String, boundary:String) {
		var data = js.node.Fs.readFileSync(filePath);

		var crlf = "\r\n";
		var delimeter = '${crlf}--${boundary}';
		var headers = [
			'Content-Disposition: form-data; name="file"; filename="${haxe.io.Path.withoutDirectory(filePath)}"' + crlf
		];
		var closeDelimeter = '${delimeter}--';
		return Buffer.concat([
			Buffer.from(delimeter + crlf + headers.join('') + crlf),
			data,
			Buffer.from(closeDelimeter)
		]);
	}
}
