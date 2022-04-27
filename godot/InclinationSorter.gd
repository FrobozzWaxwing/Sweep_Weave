extends Object
class_name InclinationSorter

#Higher inclinations are ranked higher than lower inclinations.
#Reactions lower in the reactions list are ranked higher than reactions higher in the reactions list.
#a[0] = reaction, a[1] = inclination, a[2] = list index.
#This sorter is only used to fill in the reaction inclinations display table during playback, not to select reactions when executing options.
static func sort_ascending(a, b):
	#Last entry in array will be the chosen reaction.
	if (a[1] < b[1]):
		return true
	elif (a[1] == b[1]):
		if (a[2] > b[2]):
			return true
		else:
			return false
	else:
		return false
static func sort_descending(a, b):
	#First entry in array will be the chosen reaction.
	if (a[1] < b[1]):
		return false
	elif (a[1] == b[1]):
		if (a[2] > b[2]):
			return false
		else:
			return true
	else:
		return true
