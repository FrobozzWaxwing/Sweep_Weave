extends Object
class_name IFIDGenerator

func _init():
	pass

static func IFID_from_creation_time(creation_time):
	var id = "SW-"
	id += str(creation_time).sha1_text().left(4).to_upper() + "-"
	id += UUID.v4()
	return id
