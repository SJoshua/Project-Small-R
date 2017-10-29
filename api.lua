-------------------------------------------
-- Project Small R
-- Telegram Bot API
-- Au: SJoshua
-------------------------------------------
local https = require("ssl.https")
local ltn12 = require("ltn12")
local cjson = require("cjson")
local encode = require("multipart-post").encode

bot = {}

-------------------------------------------
-- Basis
-------------------------------------------

-------------------------------------------
-- function @ analyzeMessageType
-------------------------------------------
-- Parameters
-- msg: Message
-- message_id (Integer): Unique message identifier inside this chat
-- from (User): Optional. Sender, empty for messages sent to channels
-- date (Integer): Date the message was sent in Unix time
-- chat (Chat): Conversation the message belongs to
-- forward_from (User): Optional. For forwarded messages, sender of the original message
-- forward_from_chat (Chat): Optional. For messages forwarded from channels, information about the original channel
-- forward_from_message_id (Integer): Optional. For messages forwarded from channels, identifier of the original message in the channel
-- forward_signature (String): Optional. For messages forwarded from channels, signature of the post author if present
-- forward_date (Integer): Optional. For forwarded messages, date the original message was sent in Unix time
-- reply_to_message (Message): Optional. For replies, the original message. Note that the Message object in this field will not contain further reply_to_message fields even if it itself is a reply.
-- edit_date (Integer): Optional. Date the message was last edited in Unix time
-- author_signature (String): Optional. Signature of the post author for messages in channels
-- text (String): Optional. For text messages, the actual UTF-8 text of the message, 0-4096 characters.
-- entities (Array of MessageEntity): Optional. For text messages, special entities like usernames, URLs, bot commands, etc. that appear in the text
-- caption_entities (Array of MessageEntity): Optional. For messages with a caption, special entities like usernames, URLs, bot commands, etc. that appear in the caption
-- audio (Audio): Optional. Message is an audio file, information about the file
-- document (Document): Optional. Message is a general file, information about the file
-- game (Game): Optional. Message is a game, information about the game. More about games »
-- photo (Array of PhotoSize): Optional. Message is a photo, available sizes of the photo
-- sticker (Sticker): Optional. Message is a sticker, information about the sticker
-- video (Video): Optional. Message is a video, information about the video
-- voice (Voice): Optional. Message is a voice message, information about the file
-- video_note (VideoNote): Optional. Message is a video note, information about the video message
-- caption (String): Optional. Caption for the audio, document, photo, video or voice, 0-200 characters
-- contact (Contact): Optional. Message is a shared contact, information about the contact
-- location (Location): Optional. Message is a shared location, information about the location
-- venue (Venue): Optional. Message is a venue, information about the venue
-- new_chat_members (Array of User): Optional. New members that were added to the group or supergroup and information about them (the bot itself may be one of these members)
-- left_chat_member (User): Optional. A member was removed from the group, information about them (this member may be the bot itself)
-- new_chat_title (String): Optional. A chat title was changed to this value
-- new_chat_photo (Array of PhotoSize): Optional. A chat photo was change to this value
-- delete_chat_photo (True): Optional. Service message: the chat photo was deleted
-- group_chat_created (True): Optional. Service message: the group has been created
-- supergroup_chat_created (True): Optional. Service message: the supergroup has been created. This field can‘t be received in a message coming through updates, because bot can’t be a member of a supergroup when it is created. It can only be found in reply_to_message if someone replies to a very first message in a directly created supergroup.
-- channel_chat_created (True): Optional. Service message: the channel has been created. This field can‘t be received in a message coming through updates, because bot can’t be a member of a channel when it is created. It can only be found in reply_to_message if someone replies to a very first message in a channel.
-- migrate_to_chat_id (Integer): Optional. The group has been migrated to a supergroup with the specified identifier. This number may be greater than 32 bits and some programming languages may have difficulty/silent defects in interpreting it. But it is smaller than 52 bits, so a signed 64 bit integer or double-precision float type are safe for storing this identifier.
-- migrate_from_chat_id (Integer): Optional. The supergroup has been migrated from a group with the specified identifier. This number may be greater than 32 bits and some programming languages may have difficulty/silent defects in interpreting it. But it is smaller than 52 bits, so a signed 64 bit integer or double-precision float type are safe for storing this identifier.
-- pinned_message (Message): Optional. Specified message was pinned. Note that the Message object in this field will not contain further reply_to_message fields even if it is itself a reply.
-- invoice (Invoice): Optional. Message is an invoice for a payment, information about the invoice.
-- successful_payment (SuccessfulPayment): Optional. Message is a service message about a successful payment, information about the payment.
-------------------------------------------
function analyzeMessageType(upd)
	if upd.message then
		local msg = upd.message
		if msg.audio then
			return "Audio"
		elseif msg.video then
			return "Video"
		elseif msg.document then
			return "Document"
		elseif msg.game then
			return "Game"
		elseif msg.photo then
			return "Photo"
		elseif msg.sticker then
			return "Sticker"
		elseif msg.video_note then
			return "VideoNote"
		elseif msg.contact then
			return "Contact"
		elseif msg.location then
			return "Location"
		elseif msg.venue then
			return "Venue"
		elseif msg.new_chat_members then
			return "NewChatMembers"
		elseif msg.left_chat_member then
			return "LeftChatMembers"
		elseif msg.new_chat_title then
			return "NewChatTitle"
		elseif msg.new_chat_photo then
			return "NewChatPhoto"
		elseif msg.delete_chat_title then
			return "DeleteChatPhoto"
		elseif msg.group_chat_created then
			return "GroupChatCreated"
		elseif msg.supergroup_chat_created then
			return "SupergroupChatCreated"
		elseif msg.channel_chat_created then
			return "ChannelChatCreated"
		elseif msg.migrate_to_chat_id or msg.migrate_from_chat_id then
			return "MigrateToChat"
		elseif msg.pinned_message then
			return "PinnedMessage"
		elseif msg.invoice then
			return "Invoice"
		elseif msg.successful_payment then
			return "SuccessfulPayment"
		elseif msg.chat.type == "channel" then
			return "ChannelMessage"
		else
			return "Message"
		end
	elseif upd.edited_message then
		return "EditedMessage"
	elseif upd.channel_post then
		return "ChannelPost"
	elseif upd.edited_channel_post then
		return "EditedChannelPost"
	elseif upd.inline_query then
		return "InlineQuery"
	elseif upd.chosen_inline_result then
		return "ChosenInlineResult"
	elseif upd.callback_query then
		return "CallbackQuery"
	elseif upd.shipping_query then
		return "ShippingQuery"
	elseif upd.pre_checkout_query then
		return "PreCheckoutQuery"
	else
		return "Unknown"
	end
end

-------------------------------------------
-- function @ makeRequest
-- All queries to the Telegram Bot API must be served over HTTPS and need to be presented in this form:
-- > https://api.telegram.org/bot<token>/METHOD_NAME.
-- We support GET and POST HTTP methods. We support four ways of passing parameters in Bot API requests:
-- * URL query string
-- * application/x-www-form-urlencoded
-- * application/json (except for uploading files)
-- * multipart/form-data (use to upload files)
-------------------------------------------
function makeRequest(method, parameters)
	local response = {}

	for k, v in pairs(parameters) do
		if type(v) == "number" then
			parameters[k] = tostring(v)
		end
	end

	local body, boundary = encode(parameters)

	local success, code, headers, status = https.request{
		url = "https://api.telegram.org/bot" .. config.token .. "/" .. method,
		method = "POST",
		headers = {
			["Content-Type"] =  "multipart/form-data; boundary=" .. boundary,
			["Content-Length"] = string.len(body),
		},
		source = ltn12.source.string(body),
		sink = ltn12.sink.table(response),
	}

	if success then
		local status, msg = pcall(cjson.decode, table.concat(response))
		if status then
			return msg
		else
			return nil, "failed to decode."
		end
	else
		return nil, "failed to request."
	end
end


-------------------------------------------
-- function @ downloadFile
-- File
-- This object represents a file ready to be downloaded. The file can be downloaded via the link https://api.telegram.org/file/bot<token>/<file_path>. It is guaranteed that the link will be valid for at least 1 hour. When the link expires, a new one can be requested by calling getFile.
-------------------------------------------
function downloadFile(file_id, path)
	local ret = bot.getFile(file_id)
	if ret and ret.ok then
		os.execute(string.format("wget -O %s https://api.telegram.org/file/bot%s/%s", path or "tmp", config.token, ret.result.file_path))
	end
end

-------------------------------------------
-- function @ run
-- Start here.
-------------------------------------------
function bot.run()
	local offset = 0
	while true do
		local updates = bot.getUpdates(offset, config.limit, config.timeout)
		if updates and updates.result then
			for key, upd in pairs(updates.result) do
				soul[string.format("on%sReceive", analyzeMessageType(upd))](upd.message or upd.edited_message or upd.channel_post or upd.edited_channel_post or upd.inline_query or upd.chosen_inline_result or upd.callback_query or upd.shipping_query or upd.pre_checkout_query)
				offset = upd.update_id + 1
			end
		end
	end
end

-------------------------------------------
-- Methods
-- For most case, returns the result; returns nil and error message
-- if there is any problem communicating with telegram server.
-------------------------------------------

-------------------------------------------
-- function @ getUpdates
-- Use this method to receive incoming updates using long polling (wiki). An Array of Update objects is returned.
-------------------------------------------
-- Parameters
-- offset (Integer) [Optional]: Identifier of the first update to be returned. Must be greater by one than the highest among the identifiers of previously received updates. By default, updates starting with the earliest unconfirmed update are returned. An update is considered confirmed as soon as getUpdates is called with an offset higher than its update_id. The negative offset can be specified to retrieve updates starting from -offset update from the end of the updates queue. All previous updates will forgotten.
-- limit (Integer) [Optional]: Limits the number of updates to be retrieved. Values between 1—100 are accepted. Defaults to 100.
-- timeout (Integer) [Optional]: Timeout in seconds for long polling. Defaults to 0, i.e. usual short polling. Should be positive, short polling should be used for testing purposes only.
-- allowed_updates (Array of String) [Optional]: List the types of updates you want your bot to receive. For example, specify [“message”, “edited_channel_post”, “callback_query”] to only receive updates of these types. See Update for a complete list of available update types. Specify an empty list to receive all updates regardless of type (default). If not specified, the previous setting will be used.
-------------------------------------------
function bot.getUpdates(offset, limit, timeout, allowed_updates)
	local body = {}
	body.offset = offset
	body.limit = limit
	body.timeout = timeout
	body.allowed_updates = allowed_updates
	return makeRequest("getUpdates", body)
end

-------------------------------------------
-- Mark @ Generator
-------------------------------------------
-- function @ getMe
-- A simple method for testing your bot's auth token. Requires no parameters. Returns basic information about the bot in form of a User object.
-------------------------------------------
-- Parameters
-- none.
-------------------------------------------
function bot.getMe()
	local body = {}
	return makeRequest("getMe", body)
end

-------------------------------------------
-- function @ sendMessage
-- Use this method to send text messages. On success, the sent Message is returned.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target channel (in the format @channelusername)
-- text (String) [Yes]: Text of the message to be sent
-- parse_mode (String) [Optional]: Send Markdown or HTML, if you want Telegram apps to show bold, italic, fixed-width text or inline URLs in your bot's message.
-- disable_web_page_preview (Boolean) [Optional]: Disables link previews for links in this message
-- disable_notification (Boolean) [Optional]: Sends the message silently. Users will receive a notification with no sound.
-- reply_to_message_id (Integer) [Optional]: If the message is a reply, ID of the original message
-- reply_markup (InlineKeyboardMarkup or ReplyKeyboardMarkup or ReplyKeyboardRemove or ForceReply) [Optional]: Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.
-------------------------------------------
function bot.sendMessage(chat_id, text, parse_mode, disable_web_page_preview, disable_notification, reply_to_message_id, reply_markup)
	if not chat_id then
		return nil, "chat_id is required."
	end
	if not text then
		return nil, "text is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.text = text
	body.parse_mode = parse_mode
	body.disable_web_page_preview = disable_web_page_preview
	body.disable_notification = disable_notification
	body.reply_to_message_id = reply_to_message_id
	body.reply_markup = reply_markup
	return makeRequest("sendMessage", body)
end

-------------------------------------------
-- function @ forwardMessage
-- Use this method to forward messages of any kind. On success, the sent Message is returned.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target channel (in the format @channelusername)
-- from_chat_id (Integer or String) [Yes]: Unique identifier for the chat where the original message was sent (or channel username in the format @channelusername)
-- disable_notification (Boolean) [Optional]: Sends the message silently. Users will receive a notification with no sound.
-- message_id (Integer) [Yes]: Message identifier in the chat specified in from_chat_id
-------------------------------------------
function bot.forwardMessage(chat_id, from_chat_id, disable_notification, message_id)
	if not chat_id then
		return nil, "chat_id is required."
	end
	if not from_chat_id then
		return nil, "from_chat_id is required."
	end
	if not message_id then
		return nil, "message_id is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.from_chat_id = from_chat_id
	body.disable_notification = disable_notification
	body.message_id = message_id
	return makeRequest("forwardMessage", body)
end

-------------------------------------------
-- function @ sendPhoto
-- Use this method to send photos. On success, the sent Message is returned.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target channel (in the format @channelusername)
-- photo (InputFile or String) [Yes]: Photo to send. Pass a file_id as String to send a photo that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a photo from the Internet, or upload a new photo using multipart/form-data. More info on Sending Files »
-- caption (String) [Optional]: Photo caption (may also be used when resending photos by file_id), 0-200 characters
-- disable_notification (Boolean) [Optional]: Sends the message silently. Users will receive a notification with no sound.
-- reply_to_message_id (Integer) [Optional]: If the message is a reply, ID of the original message
-- reply_markup (InlineKeyboardMarkup or ReplyKeyboardMarkup or ReplyKeyboardRemove or ForceReply) [Optional]: Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.
-------------------------------------------
function bot.sendPhoto(chat_id, photo, caption, disable_notification, reply_to_message_id, reply_markup)
	if not chat_id then
		return nil, "chat_id is required."
	end
	if not photo then
		return nil, "photo is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.photo = photo
	body.caption = caption
	body.disable_notification = disable_notification
	body.reply_to_message_id = reply_to_message_id
	body.reply_markup = reply_markup
	return makeRequest("sendPhoto", body)
end

-------------------------------------------
-- function @ sendAudio
-- Use this method to send audio files, if you want Telegram clients to display them in the music player. Your audio must be in the .mp3 format. On success, the sent Message is returned. Bots can currently send audio files of up to 50 MB in size, this limit may be changed in the future.
-- For sending voice messages, use the sendVoice method instead.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target channel (in the format @channelusername)
-- audio (InputFile or String) [Yes]: Audio file to send. Pass a file_id as String to send an audio file that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get an audio file from the Internet, or upload a new one using multipart/form-data. More info on Sending Files »
-- caption (String) [Optional]: Audio caption, 0-200 characters
-- duration (Integer) [Optional]: Duration of the audio in seconds
-- performer (String) [Optional]: Performer
-- title (String) [Optional]: Track name
-- disable_notification (Boolean) [Optional]: Sends the message silently. Users will receive a notification with no sound.
-- reply_to_message_id (Integer) [Optional]: If the message is a reply, ID of the original message
-- reply_markup (InlineKeyboardMarkup or ReplyKeyboardMarkup or ReplyKeyboardRemove or ForceReply) [Optional]: Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.
-------------------------------------------
function bot.sendAudio(chat_id, audio, caption, duration, performer, title, disable_notification, reply_to_message_id, reply_markup)
	if not chat_id then
		return nil, "chat_id is required."
	end
	if not audio then
		return nil, "audio is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.audio = audio
	body.caption = caption
	body.duration = duration
	body.performer = performer
	body.title = title
	body.disable_notification = disable_notification
	body.reply_to_message_id = reply_to_message_id
	body.reply_markup = reply_markup
	return makeRequest("sendAudio", body)
end

-------------------------------------------
-- function @ sendDocument
-- Use this method to send general files. On success, the sent Message is returned. Bots can currently send files of any type of up to 50 MB in size, this limit may be changed in the future.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target channel (in the format @channelusername)
-- document (InputFile or String) [Yes]: File to send. Pass a file_id as String to send a file that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a file from the Internet, or upload a new one using multipart/form-data. More info on Sending Files »
-- caption (String) [Optional]: Document caption (may also be used when resending documents by file_id), 0-200 characters
-- disable_notification (Boolean) [Optional]: Sends the message silently. Users will receive a notification with no sound.
-- reply_to_message_id (Integer) [Optional]: If the message is a reply, ID of the original message
-- reply_markup (InlineKeyboardMarkup or ReplyKeyboardMarkup or ReplyKeyboardRemove or ForceReply) [Optional]: Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.
-------------------------------------------
function bot.sendDocument(chat_id, document, caption, disable_notification, reply_to_message_id, reply_markup)
	if not chat_id then
		return nil, "chat_id is required."
	end
	if not document then
		return nil, "document is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.document = document
	body.caption = caption
	body.disable_notification = disable_notification
	body.reply_to_message_id = reply_to_message_id
	body.reply_markup = reply_markup
	return makeRequest("sendDocument", body)
end

-------------------------------------------
-- function @ sendVideo
-- Use this method to send video files, Telegram clients support mp4 videos (other formats may be sent as Document). On success, the sent Message is returned. Bots can currently send video files of up to 50 MB in size, this limit may be changed in the future.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target channel (in the format @channelusername)
-- video (InputFile or String) [Yes]: Video to send. Pass a file_id as String to send a video that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a video from the Internet, or upload a new video using multipart/form-data. More info on Sending Files »
-- duration (Integer) [Optional]: Duration of sent video in seconds
-- width (Integer) [Optional]: Video width
-- height (Integer) [Optional]: Video height
-- caption (String) [Optional]: Video caption (may also be used when resending videos by file_id), 0-200 characters
-- disable_notification (Boolean) [Optional]: Sends the message silently. Users will receive a notification with no sound.
-- reply_to_message_id (Integer) [Optional]: If the message is a reply, ID of the original message
-- reply_markup (InlineKeyboardMarkup or ReplyKeyboardMarkup or ReplyKeyboardRemove or ForceReply) [Optional]: Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.
-------------------------------------------
function bot.sendVideo(chat_id, video, duration, width, height, caption, disable_notification, reply_to_message_id, reply_markup)
	if not chat_id then
		return nil, "chat_id is required."
	end
	if not video then
		return nil, "video is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.video = video
	body.duration = duration
	body.width = width
	body.height = height
	body.caption = caption
	body.disable_notification = disable_notification
	body.reply_to_message_id = reply_to_message_id
	body.reply_markup = reply_markup
	return makeRequest("sendVideo", body)
end

-------------------------------------------
-- function @ sendVoice
-- Use this method to send audio files, if you want Telegram clients to display the file as a playable voice message. For this to work, your audio must be in an .ogg file encoded with OPUS (other formats may be sent as Audio or Document). On success, the sent Message is returned. Bots can currently send voice messages of up to 50 MB in size, this limit may be changed in the future.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target channel (in the format @channelusername)
-- voice (InputFile or String) [Yes]: Audio file to send. Pass a file_id as String to send a file that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a file from the Internet, or upload a new one using multipart/form-data. More info on Sending Files »
-- caption (String) [Optional]: Voice message caption, 0-200 characters
-- duration (Integer) [Optional]: Duration of the voice message in seconds
-- disable_notification (Boolean) [Optional]: Sends the message silently. Users will receive a notification with no sound.
-- reply_to_message_id (Integer) [Optional]: If the message is a reply, ID of the original message
-- reply_markup (InlineKeyboardMarkup or ReplyKeyboardMarkup or ReplyKeyboardRemove or ForceReply) [Optional]: Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.
-------------------------------------------
function bot.sendVoice(chat_id, voice, caption, duration, disable_notification, reply_to_message_id, reply_markup)
	if not chat_id then
		return nil, "chat_id is required."
	end
	if not voice then
		return nil, "voice is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.voice = voice
	body.caption = caption
	body.duration = duration
	body.disable_notification = disable_notification
	body.reply_to_message_id = reply_to_message_id
	body.reply_markup = reply_markup
	return makeRequest("sendVoice", body)
end

-------------------------------------------
-- function @ sendVideoNote
-- As of v.4.0, Telegram clients support rounded square mp4 videos of up to 1 minute long. Use this method to send video messages. On success, the sent Message is returned.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target channel (in the format @channelusername)
-- video_note (InputFile or String) [Yes]: Video note to send. Pass a file_id as String to send a video note that exists on the Telegram servers (recommended) or upload a new video using multipart/form-data. More info on Sending Files ». Sending video notes by a URL is currently unsupported
-- duration (Integer) [Optional]: Duration of sent video in seconds
-- length (Integer) [Optional]: Video width and height
-- disable_notification (Boolean) [Optional]: Sends the message silently. Users will receive a notification with no sound.
-- reply_to_message_id (Integer) [Optional]: If the message is a reply, ID of the original message
-- reply_markup (InlineKeyboardMarkup or ReplyKeyboardMarkup or ReplyKeyboardRemove or ForceReply) [Optional]: Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.
-------------------------------------------
function bot.sendVideoNote(chat_id, video_note, duration, length, disable_notification, reply_to_message_id, reply_markup)
	if not chat_id then
		return nil, "chat_id is required."
	end
	if not video_note then
		return nil, "video_note is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.video_note = video_note
	body.duration = duration
	body.length = length
	body.disable_notification = disable_notification
	body.reply_to_message_id = reply_to_message_id
	body.reply_markup = reply_markup
	return makeRequest("sendVideoNote", body)
end

-------------------------------------------
-- function @ sendLocation
-- Use this method to send point on the map. On success, the sent Message is returned.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target channel (in the format @channelusername)
-- latitude (Float number) [Yes]: Latitude of the location
-- longitude (Float number) [Yes]: Longitude of the location
-- live_period (Integer) [Optional]: Period in seconds for which the location will be updated (see Live Locations, should be between 60 and 86400.
-- disable_notification (Boolean) [Optional]: Sends the message silently. Users will receive a notification with no sound.
-- reply_to_message_id (Integer) [Optional]: If the message is a reply, ID of the original message
-- reply_markup (InlineKeyboardMarkup or ReplyKeyboardMarkup or ReplyKeyboardRemove or ForceReply) [Optional]: Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.
-------------------------------------------
function bot.sendLocation(chat_id, latitude, longitude, live_period, disable_notification, reply_to_message_id, reply_markup)
	if not chat_id then
		return nil, "chat_id is required."
	end
	if not latitude then
		return nil, "latitude is required."
	end
	if not longitude then
		return nil, "longitude is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.latitude = latitude
	body.longitude = longitude
	body.live_period = live_period
	body.disable_notification = disable_notification
	body.reply_to_message_id = reply_to_message_id
	body.reply_markup = reply_markup
	return makeRequest("sendLocation", body)
end

-------------------------------------------
-- function @ editMessageLiveLocation
-- Use this method to edit live location messages sent by the bot or via the bot (for inline bots). A location can be edited until its live_period expires or editing is explicitly disabled by a call to stopMessageLiveLocation. On success, if the edited message was sent by the bot, the edited Message is returned, otherwise True is returned.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Optional]: Required if inline_message_id is not specified. Unique identifier for the target chat or username of the target channel (in the format @channelusername)
-- message_id (Integer) [Optional]: Required if inline_message_id is not specified. Identifier of the sent message
-- inline_message_id (String) [Optional]: Required if chat_id and message_id are not specified. Identifier of the inline message
-- latitude (Float number) [Yes]: Latitude of new location
-- longitude (Float number) [Yes]: Longitude of new location
-- reply_markup (InlineKeyboardMarkup) [Optional]: A JSON-serialized object for a new inline keyboard.
-------------------------------------------
function bot.editMessageLiveLocation(chat_id, message_id, inline_message_id, latitude, longitude, reply_markup)
	if not latitude then
		return nil, "latitude is required."
	end
	if not longitude then
		return nil, "longitude is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.message_id = message_id
	body.inline_message_id = inline_message_id
	body.latitude = latitude
	body.longitude = longitude
	body.reply_markup = reply_markup
	return makeRequest("editMessageLiveLocation", body)
end

-------------------------------------------
-- function @ stopMessageLiveLocation
-- Use this method to stop updating a live location message sent by the bot or via the bot (for inline bots) before live_period expires. On success, if the message was sent by the bot, the sent Message is returned, otherwise True is returned.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Optional]: Required if inline_message_id is not specified. Unique identifier for the target chat or username of the target channel (in the format @channelusername)
-- message_id (Integer) [Optional]: Required if inline_message_id is not specified. Identifier of the sent message
-- inline_message_id (String) [Optional]: Required if chat_id and message_id are not specified. Identifier of the inline message
-- reply_markup (InlineKeyboardMarkup) [Optional]: A JSON-serialized object for a new inline keyboard.
-------------------------------------------
function bot.stopMessageLiveLocation(chat_id, message_id, inline_message_id, reply_markup)
	local body = {}
	body.chat_id = chat_id
	body.message_id = message_id
	body.inline_message_id = inline_message_id
	body.reply_markup = reply_markup
	return makeRequest("stopMessageLiveLocation", body)
end

-------------------------------------------
-- function @ sendVenue
-- Use this method to send information about a venue. On success, the sent Message is returned.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target channel (in the format @channelusername)
-- latitude (Float number) [Yes]: Latitude of the venue
-- longitude (Float number) [Yes]: Longitude of the venue
-- title (String) [Yes]: Name of the venue
-- address (String) [Yes]: Address of the venue
-- foursquare_id (String) [Optional]: Foursquare identifier of the venue
-- disable_notification (Boolean) [Optional]: Sends the message silently. Users will receive a notification with no sound.
-- reply_to_message_id (Integer) [Optional]: If the message is a reply, ID of the original message
-- reply_markup (InlineKeyboardMarkup or ReplyKeyboardMarkup or ReplyKeyboardRemove or ForceReply) [Optional]: Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.
-------------------------------------------
function bot.sendVenue(chat_id, latitude, longitude, title, address, foursquare_id, disable_notification, reply_to_message_id, reply_markup)
	if not chat_id then
		return nil, "chat_id is required."
	end
	if not latitude then
		return nil, "latitude is required."
	end
	if not longitude then
		return nil, "longitude is required."
	end
	if not title then
		return nil, "title is required."
	end
	if not address then
		return nil, "address is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.latitude = latitude
	body.longitude = longitude
	body.title = title
	body.address = address
	body.foursquare_id = foursquare_id
	body.disable_notification = disable_notification
	body.reply_to_message_id = reply_to_message_id
	body.reply_markup = reply_markup
	return makeRequest("sendVenue", body)
end

-------------------------------------------
-- function @ sendContact
-- Use this method to send phone contacts. On success, the sent Message is returned.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target channel (in the format @channelusername)
-- phone_number (String) [Yes]: Contact's phone number
-- first_name (String) [Yes]: Contact's first name
-- last_name (String) [Optional]: Contact's last name
-- disable_notification (Boolean) [Optional]: Sends the message silently. Users will receive a notification with no sound.
-- reply_to_message_id (Integer) [Optional]: If the message is a reply, ID of the original message
-- reply_markup (InlineKeyboardMarkup or ReplyKeyboardMarkup or ReplyKeyboardRemove or ForceReply) [Optional]: Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove keyboard or to force a reply from the user.
-------------------------------------------
function bot.sendContact(chat_id, phone_number, first_name, last_name, disable_notification, reply_to_message_id, reply_markup)
	if not chat_id then
		return nil, "chat_id is required."
	end
	if not phone_number then
		return nil, "phone_number is required."
	end
	if not first_name then
		return nil, "first_name is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.phone_number = phone_number
	body.first_name = first_name
	body.last_name = last_name
	body.disable_notification = disable_notification
	body.reply_to_message_id = reply_to_message_id
	body.reply_markup = reply_markup
	return makeRequest("sendContact", body)
end

-------------------------------------------
-- function @ sendChatAction
-- Use this method when you need to tell the user that something is happening on the bot's side. The status is set for 5 seconds or less (when a message arrives from your bot, Telegram clients clear its typing status). Returns True on success.
-- Example: The ImageBot needs some time to process a request and upload the image. Instead of sending a text message along the lines of “Retrieving image, please wait…”, the bot may use sendChatAction with action = upload_photo. The user will see a “sending photo” status for the bot.
-- We only recommend using this method when a response from the bot will take a noticeable amount of time to arrive.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target channel (in the format @channelusername)
-- action (String) [Yes]: Type of action to broadcast. Choose one, depending on what the user is about to receive: typing for text messages, upload_photo for photos, record_video or upload_video for videos, record_audio or upload_audio for audio files, upload_document for general files, find_location for location data, record_video_note or upload_video_note for video notes.
-------------------------------------------
function bot.sendChatAction(chat_id, action)
	if not chat_id then
		return nil, "chat_id is required."
	end
	if not action then
		return nil, "action is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.action = action
	return makeRequest("sendChatAction", body)
end

-------------------------------------------
-- function @ getUserProfilePhotos
-- Use this method to get a list of profile pictures for a user. Returns a UserProfilePhotos object.
-------------------------------------------
-- Parameters
-- user_id (Integer) [Yes]: Unique identifier of the target user
-- offset (Integer) [Optional]: Sequential number of the first photo to be returned. By default, all photos are returned.
-- limit (Integer) [Optional]: Limits the number of photos to be retrieved. Values between 1—100 are accepted. Defaults to 100.
-------------------------------------------
function bot.getUserProfilePhotos(user_id, offset, limit)
	if not user_id then
		return nil, "user_id is required."
	end
	local body = {}
	body.user_id = user_id
	body.offset = offset
	body.limit = limit
	return makeRequest("getUserProfilePhotos", body)
end

-------------------------------------------
-- function @ getFile
-- Use this method to get basic info about a file and prepare it for downloading. For the moment, bots can download files of up to 20MB in size. On success, a File object is returned. The file can then be downloaded via the link https://api.telegram.org/file/bot/, where  is taken from the response. It is guaranteed that the link will be valid for at least 1 hour. When the link expires, a new one can be requested by calling getFile again.
-------------------------------------------
-- Parameters
-- file_id (String) [Yes]: File identifier to get info about
-------------------------------------------
function bot.getFile(file_id)
	if not file_id then
		return nil, "file_id is required."
	end
	local body = {}
	body.file_id = file_id
	return makeRequest("getFile", body)
end

-------------------------------------------
-- function @ kickChatMember
-- Use this method to kick a user from a group, a supergroup or a channel. In the case of supergroups and channels, the user will not be able to return to the group on their own using invite links, etc., unless unbanned first. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns True on success.
-- Note: In regular groups (non-supergroups), this method will only work if the ‘All Members Are Admins’ setting is off in the target group. Otherwise members may only be removed by the group's creator or by the member that added them.
--
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target group or username of the target supergroup or channel (in the format @channelusername)
-- user_id (Integer) [Yes]: Unique identifier of the target user
-- until_date (Integer) [No]: Date when the user will be unbanned, unix time. If user is banned for more than 366 days or less than 30 seconds from the current time they are considered to be banned forever
-------------------------------------------
function bot.kickChatMember(chat_id, user_id, until_date)
	if not chat_id then
		return nil, "chat_id is required."
	end
	if not user_id then
		return nil, "user_id is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.user_id = user_id
	body.until_date = until_date
	return makeRequest("kickChatMember", body)
end

-------------------------------------------
-- function @ unbanChatMember
-- Use this method to unban a previously kicked user in a supergroup or channel. The user will not return to the group or channel automatically, but will be able to join via link, etc. The bot must be an administrator for this to work. Returns True on success.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target group or username of the target supergroup or channel (in the format @username)
-- user_id (Integer) [Yes]: Unique identifier of the target user
-------------------------------------------
function bot.unbanChatMember(chat_id, user_id)
	if not chat_id then
		return nil, "chat_id is required."
	end
	if not user_id then
		return nil, "user_id is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.user_id = user_id
	return makeRequest("unbanChatMember", body)
end

-------------------------------------------
-- function @ restrictChatMember
-- Use this method to restrict a user in a supergroup. The bot must be an administrator in the supergroup for this to work and must have the appropriate admin rights. Pass True for all boolean parameters to lift restrictions from a user. Returns True on success.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target supergroup (in the format @supergroupusername)
-- user_id (Integer) [Yes]: Unique identifier of the target user
-- until_date (Integer) [No]: Date when restrictions will be lifted for the user, unix time. If user is restricted for more than 366 days or less than 30 seconds from the current time, they are considered to be restricted forever
-- can_send_messages (Boolean) [No]: Pass True, if the user can send text messages, contacts, locations and venues
-- can_send_media_messages (Boolean) [No]: Pass True, if the user can send audios, documents, photos, videos, video notes and voice notes, implies can_send_messages
-- can_send_other_messages (Boolean) [No]: Pass True, if the user can send animations, games, stickers and use inline bots, implies can_send_media_messages
-- can_add_web_page_previews (Boolean) [No]: Pass True, if the user may add web page previews to their messages, implies can_send_media_messages
-------------------------------------------
function bot.restrictChatMember(chat_id, user_id, until_date, can_send_messages, can_send_media_messages, can_send_other_messages, can_add_web_page_previews)
	if not chat_id then
		return nil, "chat_id is required."
	end
	if not user_id then
		return nil, "user_id is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.user_id = user_id
	body.until_date = until_date
	body.can_send_messages = can_send_messages
	body.can_send_media_messages = can_send_media_messages
	body.can_send_other_messages = can_send_other_messages
	body.can_add_web_page_previews = can_add_web_page_previews
	return makeRequest("restrictChatMember", body)
end

-------------------------------------------
-- function @ promoteChatMember
-- Use this method to promote or demote a user in a supergroup or a channel. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Pass False for all boolean parameters to demote a user. Returns True on success.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target channel (in the format @channelusername)
-- user_id (Integer) [Yes]: Unique identifier of the target user
-- can_change_info (Boolean) [No]: Pass True, if the administrator can change chat title, photo and other settings
-- can_post_messages (Boolean) [No]: Pass True, if the administrator can create channel posts, channels only
-- can_edit_messages (Boolean) [No]: Pass True, if the administrator can edit messages of other users, channels only
-- can_delete_messages (Boolean) [No]: Pass True, if the administrator can delete messages of other users
-- can_invite_users (Boolean) [No]: Pass True, if the administrator can invite new users to the chat
-- can_restrict_members (Boolean) [No]: Pass True, if the administrator can restrict, ban or unban chat members
-- can_pin_messages (Boolean) [No]: Pass True, if the administrator can pin messages, supergroups only
-- can_promote_members (Boolean) [No]: Pass True, if the administrator can add new administrators with a subset of his own privileges or demote administrators that he has promoted, directly or indirectly (promoted by administrators that were appointed by him)
-------------------------------------------
function bot.promoteChatMember(chat_id, user_id, can_change_info, can_post_messages, can_edit_messages, can_delete_messages, can_invite_users, can_restrict_members, can_pin_messages, can_promote_members)
	if not chat_id then
		return nil, "chat_id is required."
	end
	if not user_id then
		return nil, "user_id is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.user_id = user_id
	body.can_change_info = can_change_info
	body.can_post_messages = can_post_messages
	body.can_edit_messages = can_edit_messages
	body.can_delete_messages = can_delete_messages
	body.can_invite_users = can_invite_users
	body.can_restrict_members = can_restrict_members
	body.can_pin_messages = can_pin_messages
	body.can_promote_members = can_promote_members
	return makeRequest("promoteChatMember", body)
end

-------------------------------------------
-- function @ exportChatInviteLink
-- Use this method to export an invite link to a supergroup or a channel. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns exported invite link as String on success.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target channel (in the format @channelusername)
-------------------------------------------
function bot.exportChatInviteLink(chat_id)
	if not chat_id then
		return nil, "chat_id is required."
	end
	local body = {}
	body.chat_id = chat_id
	return makeRequest("exportChatInviteLink", body)
end

-------------------------------------------
-- function @ setChatPhoto
-- Use this method to set a new profile photo for the chat. Photos can't be changed for private chats. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns True on success.
-- Note: In regular groups (non-supergroups), this method will only work if the ‘All Members Are Admins’ setting is off in the target group.
--
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target channel (in the format @channelusername)
-- photo (InputFile) [Yes]: New chat photo, uploaded using multipart/form-data
-------------------------------------------
function bot.setChatPhoto(chat_id, photo)
	if not chat_id then
		return nil, "chat_id is required."
	end
	if not photo then
		return nil, "photo is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.photo = photo
	return makeRequest("setChatPhoto", body)
end

-------------------------------------------
-- function @ deleteChatPhoto
-- Use this method to delete a chat photo. Photos can't be changed for private chats. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns True on success.
-- Note: In regular groups (non-supergroups), this method will only work if the ‘All Members Are Admins’ setting is off in the target group.
--
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target channel (in the format @channelusername)
-------------------------------------------
function bot.deleteChatPhoto(chat_id)
	if not chat_id then
		return nil, "chat_id is required."
	end
	local body = {}
	body.chat_id = chat_id
	return makeRequest("deleteChatPhoto", body)
end

-------------------------------------------
-- function @ setChatTitle
-- Use this method to change the title of a chat. Titles can't be changed for private chats. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns True on success.
-- Note: In regular groups (non-supergroups), this method will only work if the ‘All Members Are Admins’ setting is off in the target group.
--
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target channel (in the format @channelusername)
-- title (String) [Yes]: New chat title, 1-255 characters
-------------------------------------------
function bot.setChatTitle(chat_id, title)
	if not chat_id then
		return nil, "chat_id is required."
	end
	if not title then
		return nil, "title is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.title = title
	return makeRequest("setChatTitle", body)
end

-------------------------------------------
-- function @ setChatDescription
-- Use this method to change the description of a supergroup or a channel. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns True on success.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target channel (in the format @channelusername)
-- description (String) [No]: New chat description, 0-255 characters
-------------------------------------------
function bot.setChatDescription(chat_id, description)
	if not chat_id then
		return nil, "chat_id is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.description = description
	return makeRequest("setChatDescription", body)
end

-------------------------------------------
-- function @ pinChatMessage
-- Use this method to pin a message in a supergroup. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns True on success.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target supergroup (in the format @supergroupusername)
-- message_id (Integer) [Yes]: Identifier of a message to pin
-- disable_notification (Boolean) [No]: Pass True, if it is not necessary to send a notification to all group members about the new pinned message
-------------------------------------------
function bot.pinChatMessage(chat_id, message_id, disable_notification)
	if not chat_id then
		return nil, "chat_id is required."
	end
	if not message_id then
		return nil, "message_id is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.message_id = message_id
	body.disable_notification = disable_notification
	return makeRequest("pinChatMessage", body)
end

-------------------------------------------
-- function @ unpinChatMessage
-- Use this method to unpin a message in a supergroup chat. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns True on success.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target supergroup (in the format @supergroupusername)
-------------------------------------------
function bot.unpinChatMessage(chat_id)
	if not chat_id then
		return nil, "chat_id is required."
	end
	local body = {}
	body.chat_id = chat_id
	return makeRequest("unpinChatMessage", body)
end

-------------------------------------------
-- function @ leaveChat
-- Use this method for your bot to leave a group, supergroup or channel. Returns True on success.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target supergroup or channel (in the format @channelusername)
-------------------------------------------
function bot.leaveChat(chat_id)
	if not chat_id then
		return nil, "chat_id is required."
	end
	local body = {}
	body.chat_id = chat_id
	return makeRequest("leaveChat", body)
end

-------------------------------------------
-- function @ getChat
-- Use this method to get up to date information about the chat (current name of the user for one-on-one conversations, current username of a user, group or channel, etc.). Returns a Chat object on success.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target supergroup or channel (in the format @channelusername)
-------------------------------------------
function bot.getChat(chat_id)
	if not chat_id then
		return nil, "chat_id is required."
	end
	local body = {}
	body.chat_id = chat_id
	return makeRequest("getChat", body)
end

-------------------------------------------
-- function @ getChatAdministrators
-- Use this method to get a list of administrators in a chat. On success, returns an Array of ChatMember objects that contains information about all chat administrators except other bots. If the chat is a group or a supergroup and no administrators were appointed, only the creator will be returned.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target supergroup or channel (in the format @channelusername)
-------------------------------------------
function bot.getChatAdministrators(chat_id)
	if not chat_id then
		return nil, "chat_id is required."
	end
	local body = {}
	body.chat_id = chat_id
	return makeRequest("getChatAdministrators", body)
end

-------------------------------------------
-- function @ getChatMembersCount
-- Use this method to get the number of members in a chat. Returns Int on success.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target supergroup or channel (in the format @channelusername)
-------------------------------------------
function bot.getChatMembersCount(chat_id)
	if not chat_id then
		return nil, "chat_id is required."
	end
	local body = {}
	body.chat_id = chat_id
	return makeRequest("getChatMembersCount", body)
end

-------------------------------------------
-- function @ getChatMember
-- Use this method to get information about a member of a chat. Returns a ChatMember object on success.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target supergroup or channel (in the format @channelusername)
-- user_id (Integer) [Yes]: Unique identifier of the target user
-------------------------------------------
function bot.getChatMember(chat_id, user_id)
	if not chat_id then
		return nil, "chat_id is required."
	end
	if not user_id then
		return nil, "user_id is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.user_id = user_id
	return makeRequest("getChatMember", body)
end

-------------------------------------------
-- function @ setChatStickerSet
-- Use this method to set a new group sticker set for a supergroup. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Use the field can_set_sticker_set optionally returned in getChat requests to check if the bot can use this method. Returns True on success.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target supergroup (in the format @supergroupusername)
-- sticker_set_name (String) [Yes]: Name of the sticker set to be set as the group sticker set
-------------------------------------------
function bot.setChatStickerSet(chat_id, sticker_set_name)
	if not chat_id then
		return nil, "chat_id is required."
	end
	if not sticker_set_name then
		return nil, "sticker_set_name is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.sticker_set_name = sticker_set_name
	return makeRequest("setChatStickerSet", body)
end

-------------------------------------------
-- function @ deleteChatStickerSet
-- Use this method to delete a group sticker set from a supergroup. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Use the field can_set_sticker_set optionally returned in getChat requests to check if the bot can use this method. Returns True on success.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target supergroup (in the format @supergroupusername)
-------------------------------------------
function bot.deleteChatStickerSet(chat_id)
	if not chat_id then
		return nil, "chat_id is required."
	end
	local body = {}
	body.chat_id = chat_id
	return makeRequest("deleteChatStickerSet", body)
end

-------------------------------------------
-- function @ answerCallbackQuery
-- Use this method to send answers to callback queries sent from inline keyboards. The answer will be displayed to the user as a notification at the top of the chat screen or as an alert. On success, True is returned.
-- Alternatively, the user can be redirected to the specified Game URL. For this option to work, you must first create a game for your bot via @Botfather and accept the terms. Otherwise, you may use links like t.me/your_bot?start=XXXX that open your bot with a parameter.
--
-------------------------------------------
-- Parameters
-- callback_query_id (String) [Yes]: Unique identifier for the query to be answered
-- text (String) [Optional]: Text of the notification. If not specified, nothing will be shown to the user, 0-200 characters
-- show_alert (Boolean) [Optional]: If true, an alert will be shown by the client instead of a notification at the top of the chat screen. Defaults to false.
-- url (String) [Optional]: URL that will be opened by the user's client. If you have created a Game and accepted the conditions via @Botfather, specify the URL that opens your game – note that this will only work if the query comes from a callback_game button.Otherwise, you may use links like t.me/your_bot?start=XXXX that open your bot with a parameter.
-- cache_time (Integer) [Optional]: The maximum amount of time in seconds that the result of the callback query may be cached client-side. Telegram apps will support caching starting in version 3.14. Defaults to 0.
-------------------------------------------
function bot.answerCallbackQuery(callback_query_id, text, show_alert, url, cache_time)
	if not callback_query_id then
		return nil, "callback_query_id is required."
	end
	local body = {}
	body.callback_query_id = callback_query_id
	body.text = text
	body.show_alert = show_alert
	body.url = url
	body.cache_time = cache_time
	return makeRequest("answerCallbackQuery", body)
end

-------------------------------------------
-- function @ editMessageText
-- Use this method to edit text and game messages sent by the bot or via the bot (for inline bots). On success, if edited message is sent by the bot, the edited Message is returned, otherwise True is returned.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Optional]: Required if inline_message_id is not specified. Unique identifier for the target chat or username of the target channel (in the format @channelusername)
-- message_id (Integer) [Optional]: Required if inline_message_id is not specified. Identifier of the sent message
-- inline_message_id (String) [Optional]: Required if chat_id and message_id are not specified. Identifier of the inline message
-- text (String) [Yes]: New text of the message
-- parse_mode (String) [Optional]: Send Markdown or HTML, if you want Telegram apps to show bold, italic, fixed-width text or inline URLs in your bot's message.
-- disable_web_page_preview (Boolean) [Optional]: Disables link previews for links in this message
-- reply_markup (InlineKeyboardMarkup) [Optional]: A JSON-serialized object for an inline keyboard.
-------------------------------------------
function bot.editMessageText(chat_id, message_id, inline_message_id, text, parse_mode, disable_web_page_preview, reply_markup)
	if not text then
		return nil, "text is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.message_id = message_id
	body.inline_message_id = inline_message_id
	body.text = text
	body.parse_mode = parse_mode
	body.disable_web_page_preview = disable_web_page_preview
	body.reply_markup = reply_markup
	return makeRequest("editMessageText", body)
end

-------------------------------------------
-- function @ editMessageCaption
-- Use this method to edit captions of messages sent by the bot or via the bot (for inline bots). On success, if edited message is sent by the bot, the edited Message is returned, otherwise True is returned.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Optional]: Required if inline_message_id is not specified. Unique identifier for the target chat or username of the target channel (in the format @channelusername)
-- message_id (Integer) [Optional]: Required if inline_message_id is not specified. Identifier of the sent message
-- inline_message_id (String) [Optional]: Required if chat_id and message_id are not specified. Identifier of the inline message
-- caption (String) [Optional]: New caption of the message
-- reply_markup (InlineKeyboardMarkup) [Optional]: A JSON-serialized object for an inline keyboard.
-------------------------------------------
function bot.editMessageCaption(chat_id, message_id, inline_message_id, caption, reply_markup)
	local body = {}
	body.chat_id = chat_id
	body.message_id = message_id
	body.inline_message_id = inline_message_id
	body.caption = caption
	body.reply_markup = reply_markup
	return makeRequest("editMessageCaption", body)
end

-------------------------------------------
-- function @ editMessageReplyMarkup
-- Use this method to edit only the reply markup of messages sent by the bot or via the bot (for inline bots).  On success, if edited message is sent by the bot, the edited Message is returned, otherwise True is returned.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Optional]: Required if inline_message_id is not specified. Unique identifier for the target chat or username of the target channel (in the format @channelusername)
-- message_id (Integer) [Optional]: Required if inline_message_id is not specified. Identifier of the sent message
-- inline_message_id (String) [Optional]: Required if chat_id and message_id are not specified. Identifier of the inline message
-- reply_markup (InlineKeyboardMarkup) [Optional]: A JSON-serialized object for an inline keyboard.
-------------------------------------------
function bot.editMessageReplyMarkup(chat_id, message_id, inline_message_id, reply_markup)
	local body = {}
	body.chat_id = chat_id
	body.message_id = message_id
	body.inline_message_id = inline_message_id
	body.reply_markup = reply_markup
	return makeRequest("editMessageReplyMarkup", body)
end

-------------------------------------------
-- function @ deleteMessage
-- Use this method to delete a message, including service messages, with the following limitations:- A message can only be deleted if it was sent less than 48 hours ago.- Bots can delete outgoing messages in groups and supergroups.- Bots granted can_post_messages permissions can delete outgoing messages in channels.- If the bot is an administrator of a group, it can delete any message there.- If the bot has can_delete_messages permission in a supergroup or a channel, it can delete any message there.Returns True on success.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target channel (in the format @channelusername)
-- message_id (Integer) [Yes]: Identifier of the message to delete
-------------------------------------------
function bot.deleteMessage(chat_id, message_id)
	if not chat_id then
		return nil, "chat_id is required."
	end
	if not message_id then
		return nil, "message_id is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.message_id = message_id
	return makeRequest("deleteMessage", body)
end

-------------------------------------------
-- function @ sendSticker
-- Use this method to send .webp stickers. On success, the sent Message is returned.
-------------------------------------------
-- Parameters
-- chat_id (Integer or String) [Yes]: Unique identifier for the target chat or username of the target channel (in the format @channelusername)
-- sticker (InputFile or String) [Yes]: Sticker to send. Pass a file_id as String to send a file that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a .webp file from the Internet, or upload a new one using multipart/form-data. More info on Sending Files »
-- disable_notification (Boolean) [Optional]: Sends the message silently. Users will receive a notification with no sound.
-- reply_to_message_id (Integer) [Optional]: If the message is a reply, ID of the original message
-- reply_markup (InlineKeyboardMarkup or ReplyKeyboardMarkup or ReplyKeyboardRemove or ForceReply) [Optional]: Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.
-------------------------------------------
function bot.sendSticker(chat_id, sticker, disable_notification, reply_to_message_id, reply_markup)
	if not chat_id then
		return nil, "chat_id is required."
	end
	if not sticker then
		return nil, "sticker is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.sticker = sticker
	body.disable_notification = disable_notification
	body.reply_to_message_id = reply_to_message_id
	body.reply_markup = reply_markup
	return makeRequest("sendSticker", body)
end

-------------------------------------------
-- function @ getStickerSet
-- Use this method to get a sticker set. On success, a StickerSet object is returned.
-------------------------------------------
-- Parameters
-- name (String) [Yes]: Name of the sticker set
-------------------------------------------
function bot.getStickerSet(name)
	if not name then
		return nil, "name is required."
	end
	local body = {}
	body.name = name
	return makeRequest("getStickerSet", body)
end

-------------------------------------------
-- function @ uploadStickerFile
-- Use this method to upload a .png file with a sticker for later use in createNewStickerSet and addStickerToSet methods (can be used multiple times). Returns the uploaded File on success.
-------------------------------------------
-- Parameters
-- user_id (Integer) [Yes]: User identifier of sticker file owner
-- png_sticker (InputFile) [Yes]: Png image with the sticker, must be up to 512 kilobytes in size, dimensions must not exceed 512px, and either width or height must be exactly 512px. More info on Sending Files »
-------------------------------------------
function bot.uploadStickerFile(user_id, png_sticker)
	if not user_id then
		return nil, "user_id is required."
	end
	if not png_sticker then
		return nil, "png_sticker is required."
	end
	local body = {}
	body.user_id = user_id
	body.png_sticker = png_sticker
	return makeRequest("uploadStickerFile", body)
end

-------------------------------------------
-- function @ createNewStickerSet
-- Use this method to create new sticker set owned by a user. The bot will be able to edit the created sticker set. Returns True on success.
-------------------------------------------
-- Parameters
-- user_id (Integer) [Yes]: User identifier of created sticker set owner
-- name (String) [Yes]: Short name of sticker set, to be used in t.me/addstickers/ URLs (e.g., animals). Can contain only english letters, digits and underscores. Must begin with a letter, can't contain consecutive underscores and must end in “_by_”.  is case insensitive. 1-64 characters.
-- title (String) [Yes]: Sticker set title, 1-64 characters
-- png_sticker (InputFile or String) [Yes]: Png image with the sticker, must be up to 512 kilobytes in size, dimensions must not exceed 512px, and either width or height must be exactly 512px. Pass a file_id as a String to send a file that already exists on the Telegram servers, pass an HTTP URL as a String for Telegram to get a file from the Internet, or upload a new one using multipart/form-data. More info on Sending Files »
-- emojis (String) [Yes]: One or more emoji corresponding to the sticker
-- contains_masks (Boolean) [Optional]: Pass True, if a set of mask stickers should be created
-- mask_position (MaskPosition) [Optional]: A JSON-serialized object for position where the mask should be placed on faces
-------------------------------------------
function bot.createNewStickerSet(user_id, name, title, png_sticker, emojis, contains_masks, mask_position)
	if not user_id then
		return nil, "user_id is required."
	end
	if not name then
		return nil, "name is required."
	end
	if not title then
		return nil, "title is required."
	end
	if not png_sticker then
		return nil, "png_sticker is required."
	end
	if not emojis then
		return nil, "emojis is required."
	end
	local body = {}
	body.user_id = user_id
	body.name = name
	body.title = title
	body.png_sticker = png_sticker
	body.emojis = emojis
	body.contains_masks = contains_masks
	body.mask_position = mask_position
	return makeRequest("createNewStickerSet", body)
end

-------------------------------------------
-- function @ addStickerToSet
-- Use this method to add a new sticker to a set created by the bot. Returns True on success.
-------------------------------------------
-- Parameters
-- user_id (Integer) [Yes]: User identifier of sticker set owner
-- name (String) [Yes]: Sticker set name
-- png_sticker (InputFile or String) [Yes]: Png image with the sticker, must be up to 512 kilobytes in size, dimensions must not exceed 512px, and either width or height must be exactly 512px. Pass a file_id as a String to send a file that already exists on the Telegram servers, pass an HTTP URL as a String for Telegram to get a file from the Internet, or upload a new one using multipart/form-data. More info on Sending Files »
-- emojis (String) [Yes]: One or more emoji corresponding to the sticker
-- mask_position (MaskPosition) [Optional]: A JSON-serialized object for position where the mask should be placed on faces
-------------------------------------------
function bot.addStickerToSet(user_id, name, png_sticker, emojis, mask_position)
	if not user_id then
		return nil, "user_id is required."
	end
	if not name then
		return nil, "name is required."
	end
	if not png_sticker then
		return nil, "png_sticker is required."
	end
	if not emojis then
		return nil, "emojis is required."
	end
	local body = {}
	body.user_id = user_id
	body.name = name
	body.png_sticker = png_sticker
	body.emojis = emojis
	body.mask_position = mask_position
	return makeRequest("addStickerToSet", body)
end

-------------------------------------------
-- function @ setStickerPositionInSet
-- Use this method to move a sticker in a set created by the bot to a specific position . Returns True on success.
-------------------------------------------
-- Parameters
-- sticker (String) [Yes]: File identifier of the sticker
-- position (Integer) [Yes]: New sticker position in the set, zero-based
-------------------------------------------
function bot.setStickerPositionInSet(sticker, position)
	if not sticker then
		return nil, "sticker is required."
	end
	if not position then
		return nil, "position is required."
	end
	local body = {}
	body.sticker = sticker
	body.position = position
	return makeRequest("setStickerPositionInSet", body)
end

-------------------------------------------
-- function @ deleteStickerFromSet
-- Use this method to delete a sticker from a set created by the bot. Returns True on success.
-------------------------------------------
-- Parameters
-- sticker (String) [Yes]: File identifier of the sticker
-------------------------------------------
function bot.deleteStickerFromSet(sticker)
	if not sticker then
		return nil, "sticker is required."
	end
	local body = {}
	body.sticker = sticker
	return makeRequest("deleteStickerFromSet", body)
end

-------------------------------------------
-- function @ answerInlineQuery
-- Use this method to send answers to an inline query. On success, True is returned.No more than 50 results per query are allowed.
-------------------------------------------
-- Parameters
-- inline_query_id (String) [Yes]: Unique identifier for the answered query
-- results (Array of InlineQueryResult) [Yes]: A JSON-serialized array of results for the inline query
-- cache_time (Integer) [Optional]: The maximum amount of time in seconds that the result of the inline query may be cached on the server. Defaults to 300.
-- is_personal (Boolean) [Optional]: Pass True, if results may be cached on the server side only for the user that sent the query. By default, results may be returned to any user who sends the same query
-- next_offset (String) [Optional]: Pass the offset that a client should send in the next query with the same text to receive more results. Pass an empty string if there are no more results or if you don‘t support pagination. Offset length can’t exceed 64 bytes.
-- switch_pm_text (String) [Optional]: If passed, clients will display a button with specified text that switches the user to a private chat with the bot and sends the bot a start message with the parameter switch_pm_parameter
-- switch_pm_parameter (String) [Optional]: Deep-linking parameter for the /start message sent to the bot when user presses the switch button. 1-64 characters, only A-Z, a-z, 0-9, _ and - are allowed.Example: An inline bot that sends YouTube videos can ask the user to connect the bot to their YouTube account to adapt search results accordingly. To do this, it displays a ‘Connect your YouTube account’ button above the results, or even before showing any. The user presses the button, switches to a private chat with the bot and, in doing so, passes a start parameter that instructs the bot to return an oauth link. Once done, the bot can offer a switch_inline button so that the user can easily return to the chat where they wanted to use the bot's inline capabilities.
-------------------------------------------
function bot.answerInlineQuery(inline_query_id, results, cache_time, is_personal, next_offset, switch_pm_text, switch_pm_parameter)
	if not inline_query_id then
		return nil, "inline_query_id is required."
	end
	if not results then
		return nil, "results is required."
	end
	local body = {}
	body.inline_query_id = inline_query_id
	body.results = results
	body.cache_time = cache_time
	body.is_personal = is_personal
	body.next_offset = next_offset
	body.switch_pm_text = switch_pm_text
	body.switch_pm_parameter = switch_pm_parameter
	return makeRequest("answerInlineQuery", body)
end

-------------------------------------------
-- function @ sendInvoice
-- Use this method to send invoices. On success, the sent Message is returned.
-------------------------------------------
-- Parameters
-- chat_id (Integer) [Yes]: Unique identifier for the target private chat
-- title (String) [Yes]: Product name, 1-32 characters
-- description (String) [Yes]: Product description, 1-255 characters
-- payload (String) [Yes]: Bot-defined invoice payload, 1-128 bytes. This will not be displayed to the user, use for your internal processes.
-- provider_token (String) [Yes]: Payments provider token, obtained via Botfather
-- start_parameter (String) [Yes]: Unique deep-linking parameter that can be used to generate this invoice when used as a start parameter
-- currency (String) [Yes]: Three-letter ISO 4217 currency code, see more on currencies
-- prices (Array of LabeledPrice) [Yes]: Price breakdown, a list of components (e.g. product price, tax, discount, delivery cost, delivery tax, bonus, etc.)
-- photo_url (String) [Optional]: URL of the product photo for the invoice. Can be a photo of the goods or a marketing image for a service. People like it better when they see what they are paying for.
-- photo_size (Integer) [Optional]: Photo size
-- photo_width (Integer) [Optional]: Photo width
-- photo_height (Integer) [Optional]: Photo height
-- need_name (Boolean) [Optional]: Pass True, if you require the user's full name to complete the order
-- need_phone_number (Boolean) [Optional]: Pass True, if you require the user's phone number to complete the order
-- need_email (Boolean) [Optional]: Pass True, if you require the user's email to complete the order
-- need_shipping_address (Boolean) [Optional]: Pass True, if you require the user's shipping address to complete the order
-- is_flexible (Boolean) [Optional]: Pass True, if the final price depends on the shipping method
-- disable_notification (Boolean) [Optional]: Sends the message silently. Users will receive a notification with no sound.
-- reply_to_message_id (Integer) [Optional]: If the message is a reply, ID of the original message
-- reply_markup (InlineKeyboardMarkup) [Optional]: A JSON-serialized object for an inline keyboard. If empty, one 'Pay total price' button will be shown. If not empty, the first button must be a Pay button.
-------------------------------------------
function bot.sendInvoice(chat_id, title, description, payload, provider_token, start_parameter, currency, prices, photo_url, photo_size, photo_width, photo_height, need_name, need_phone_number, need_email, need_shipping_address, is_flexible, disable_notification, reply_to_message_id, reply_markup)
	if not chat_id then
		return nil, "chat_id is required."
	end
	if not title then
		return nil, "title is required."
	end
	if not description then
		return nil, "description is required."
	end
	if not payload then
		return nil, "payload is required."
	end
	if not provider_token then
		return nil, "provider_token is required."
	end
	if not start_parameter then
		return nil, "start_parameter is required."
	end
	if not currency then
		return nil, "currency is required."
	end
	if not prices then
		return nil, "prices is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.title = title
	body.description = description
	body.payload = payload
	body.provider_token = provider_token
	body.start_parameter = start_parameter
	body.currency = currency
	body.prices = prices
	body.photo_url = photo_url
	body.photo_size = photo_size
	body.photo_width = photo_width
	body.photo_height = photo_height
	body.need_name = need_name
	body.need_phone_number = need_phone_number
	body.need_email = need_email
	body.need_shipping_address = need_shipping_address
	body.is_flexible = is_flexible
	body.disable_notification = disable_notification
	body.reply_to_message_id = reply_to_message_id
	body.reply_markup = reply_markup
	return makeRequest("sendInvoice", body)
end

-------------------------------------------
-- function @ answerShippingQuery
-- If you sent an invoice requesting a shipping address and the parameter is_flexible was specified, the Bot API will send an Update with a shipping_query field to the bot. Use this method to reply to shipping queries. On success, True is returned.
-------------------------------------------
-- Parameters
-- shipping_query_id (String) [Yes]: Unique identifier for the query to be answered
-- ok (Boolean) [Yes]: Specify True if delivery to the specified address is possible and False if there are any problems (for example, if delivery to the specified address is not possible)
-- shipping_options (Array of ShippingOption) [Optional]: Required if ok is True. A JSON-serialized array of available shipping options.
-- error_message (String) [Optional]: Required if ok is False. Error message in human readable form that explains why it is impossible to complete the order (e.g. "Sorry, delivery to your desired address is unavailable'). Telegram will display this message to the user.
-------------------------------------------
function bot.answerShippingQuery(shipping_query_id, ok, shipping_options, error_message)
	if not shipping_query_id then
		return nil, "shipping_query_id is required."
	end
	if not ok then
		return nil, "ok is required."
	end
	local body = {}
	body.shipping_query_id = shipping_query_id
	body.ok = ok
	body.shipping_options = shipping_options
	body.error_message = error_message
	return makeRequest("answerShippingQuery", body)
end

-------------------------------------------
-- function @ answerPreCheckoutQuery
-- Once the user has confirmed their payment and shipping details, the Bot API sends the final confirmation in the form of an Update with the field pre_checkout_query. Use this method to respond to such pre-checkout queries. On success, True is returned. Note: The Bot API must receive an answer within 10 seconds after the pre-checkout query was sent.
-------------------------------------------
-- Parameters
-- pre_checkout_query_id (String) [Yes]: Unique identifier for the query to be answered
-- ok (Boolean) [Yes]: Specify True if everything is alright (goods are available, etc.) and the bot is ready to proceed with the order. Use False if there are any problems.
-- error_message (String) [Optional]: Required if ok is False. Error message in human readable form that explains the reason for failure to proceed with the checkout (e.g. "Sorry, somebody just bought the last of our amazing black T-shirts while you were busy filling out your payment details. Please choose a different color or garment!"). Telegram will display this message to the user.
-------------------------------------------
function bot.answerPreCheckoutQuery(pre_checkout_query_id, ok, error_message)
	if not pre_checkout_query_id then
		return nil, "pre_checkout_query_id is required."
	end
	if not ok then
		return nil, "ok is required."
	end
	local body = {}
	body.pre_checkout_query_id = pre_checkout_query_id
	body.ok = ok
	body.error_message = error_message
	return makeRequest("answerPreCheckoutQuery", body)
end

-------------------------------------------
-- function @ sendGame
-- Use this method to send a game. On success, the sent Message is returned.
-------------------------------------------
-- Parameters
-- chat_id (Integer) [Yes]: Unique identifier for the target chat
-- game_short_name (String) [Yes]: Short name of the game, serves as the unique identifier for the game. Set up your games via Botfather.
-- disable_notification (Boolean) [Optional]: Sends the message silently. Users will receive a notification with no sound.
-- reply_to_message_id (Integer) [Optional]: If the message is a reply, ID of the original message
-- reply_markup (InlineKeyboardMarkup) [Optional]: A JSON-serialized object for an inline keyboard. If empty, one ‘Play game_title’ button will be shown. If not empty, the first button must launch the game.
-------------------------------------------
function bot.sendGame(chat_id, game_short_name, disable_notification, reply_to_message_id, reply_markup)
	if not chat_id then
		return nil, "chat_id is required."
	end
	if not game_short_name then
		return nil, "game_short_name is required."
	end
	local body = {}
	body.chat_id = chat_id
	body.game_short_name = game_short_name
	body.disable_notification = disable_notification
	body.reply_to_message_id = reply_to_message_id
	body.reply_markup = reply_markup
	return makeRequest("sendGame", body)
end

-------------------------------------------
-- function @ setGameScore
-- Use this method to set the score of the specified user in a game. On success, if the message was sent by the bot, returns the edited Message, otherwise returns True. Returns an error, if the new score is not greater than the user's current score in the chat and force is False.
-------------------------------------------
-- Parameters
-- user_id (Integer) [Yes]: User identifier
-- score (Integer) [Yes]: New score, must be non-negative
-- force (Boolean) [Optional]: Pass True, if the high score is allowed to decrease. This can be useful when fixing mistakes or banning cheaters
-- disable_edit_message (Boolean) [Optional]: Pass True, if the game message should not be automatically edited to include the current scoreboard
-- chat_id (Integer) [Optional]: Required if inline_message_id is not specified. Unique identifier for the target chat
-- message_id (Integer) [Optional]: Required if inline_message_id is not specified. Identifier of the sent message
-- inline_message_id (String) [Optional]: Required if chat_id and message_id are not specified. Identifier of the inline message
-------------------------------------------
function bot.setGameScore(user_id, score, force, disable_edit_message, chat_id, message_id, inline_message_id)
	if not user_id then
		return nil, "user_id is required."
	end
	if not score then
		return nil, "score is required."
	end
	local body = {}
	body.user_id = user_id
	body.score = score
	body.force = force
	body.disable_edit_message = disable_edit_message
	body.chat_id = chat_id
	body.message_id = message_id
	body.inline_message_id = inline_message_id
	return makeRequest("setGameScore", body)
end

-------------------------------------------
-- function @ getGameHighScores
-- Use this method to get data for high score tables. Will return the score of the specified user and several of his neighbors in a game. On success, returns an Array of GameHighScore objects.
-- This method will currently return scores for the target user, plus two of his closest neighbors on each side. Will also return the top three users if the user and his neighbors are not among them. Please note that this behavior is subject to change.
--
-------------------------------------------
-- Parameters
-- user_id (Integer) [Yes]: Target user id
-- chat_id (Integer) [Optional]: Required if inline_message_id is not specified. Unique identifier for the target chat
-- message_id (Integer) [Optional]: Required if inline_message_id is not specified. Identifier of the sent message
-- inline_message_id (String) [Optional]: Required if chat_id and message_id are not specified. Identifier of the inline message
-------------------------------------------
function bot.getGameHighScores(user_id, chat_id, message_id, inline_message_id)
	if not user_id then
		return nil, "user_id is required."
	end
	local body = {}
	body.user_id = user_id
	body.chat_id = chat_id
	body.message_id = message_id
	body.inline_message_id = inline_message_id
	return makeRequest("getGameHighScores", body)
end
