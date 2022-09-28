# Action for ideckia: toot

## Definition

Publish a predefined text to a mastodon instance

## Properties

| Name | Type | Description | Shared | Default | Possible values |
| ----- |----- | ----- | ----- | ----- | ----- |
| server | String | Server of the Mastodon instance | true | "https://mastodon.social" | null |
| access_token | String | Access token value | true | null | null |
| toot_text | String | Text to publish | false | null | null |
| toot_image_paths | Array&lt;String&gt; | Image paths | false | [] | null |

## On single click

Publishes a toot with the given text in the given server

## On long press

Does nothing

## Example in layout file

```json
{
    "text": "toot action example",
    "actions": [
        {
            "name": "toot",
            "props": {
                "server": "https://mastodon.social",
                "access_token": null,
                "toot_text": null,
                "toot_image_paths": [
                    "/path/to/image.jpg"
                ]
            }
        }
    ]
}
```

## Get the access token

* Login in the server where you want to publish.
* Go to Settings (the gear icon) -> Development -> New application
  * Give the application a descriptive name
  * Check the "write:statuses" checkbox
  * If you want to publish images, check the "write:media" checkbox too
  * Click SUBMIT
* Click in the newly created application and there is "Your access token" that you need.