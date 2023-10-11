extends Node2D

@onready var client: NakamaClient = Nakama.create_client("defaultkey", "server", 7350, "http")
@onready var socket := Nakama.create_socket_from(client)
@onready var session: NakamaSession

var channel: NakamaRTAPI.Channel
var username: String

func _ready():
	client.timeout = 10
	
	var device_id = OS.get_unique_id() + Time.get_datetime_string_from_system(true)
	var session_vars = {
		"device_os": OS.get_name(),
		"device_model": OS.get_model_name(),
		"user_id": randi_range(1000, 9999)
	}
	session = await client.authenticate_device_async(device_id, null, true, session_vars)
	if session.is_exception():
		print("An error occurred on user auth: %s" % session)
		return
		
	username = session.username
		
	var connected: NakamaAsyncResult = await socket.connect_async(session)
	if connected.is_exception():
		print("An error occurred on user connection: %s" % connected)
		return
		
	print("Socket connected!!")
	
	var room_name = "test_room"
	var persistence = true
	var hidden = false
	var type = NakamaSocket.ChannelType.Room
	channel = await socket.join_chat_async(room_name, type, persistence, hidden)
	if channel.is_exception():
		print("An error occurred joining channel: %s" % channel)
		return
		
	socket.received_channel_message.connect(_on_message_received)
		
func _on_message_send():
	if channel == null or channel.is_exception():
		print("Channel not ready. Can't send message")
		return
	var msg = $Panel/TextEdit.text
	var content = {"message": msg}
	var message_ack: NakamaRTAPI.ChannelMessageAck = await socket.write_chat_message_async(channel.id, content)
	if message_ack.is_exception():
		print("Error sending chat message: %s" % message_ack)
		return
	print("Message sent!")
	var msg_display = "[ME]: " + msg
	var label = Label.new()
	label.text = msg_display
	$Panel/ScrollContainer/VBoxContainer.add_child(label)
	
func _on_message_received(message: NakamaAPI.ApiChannelMessage):
	print("Received message: %s" % message)
	if message.username != username:
		var msg = JSON.parse_string(message.content)
		var msg_display = "[%s]: %s" % [message.username, msg["message"]]
		var label = Label.new()
		label.text = msg_display
		$Panel/ScrollContainer/VBoxContainer.add_child(label)
