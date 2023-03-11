extends Control

signal meta_clicked(meta)

var illustrations = []

func _ready():
	illustrations.append(preload("res://doc_illustrations/DocIllustration01.tscn"))
	illustrations.append(preload("res://doc_illustrations/DocIllustration02.tscn"))
	illustrations.append(preload("res://doc_illustrations/DocIllustrationAbsoluteValue.tscn"))
	illustrations.append(preload("res://doc_illustrations/DocIllustrationArithmeticNegation.tscn"))
	illustrations.append(preload("res://doc_illustrations/DocIllustrationBlend.tscn"))
	illustrations.append(preload("res://doc_illustrations/DocIllustrationProximity.tscn"))
	illustrations.append(preload("res://doc_illustrations/DocIllustrationNudge.tscn"))

func clear():
	for child in $Scroll/VBC.get_children():
		child.call_deferred("free")

func display(page):
	clear()
	for section in page.sections:
		if (null != section.illustration):
			if (0 <= section.illustration and section.illustration < illustrations.size()):
				var illustration = illustrations[section.illustration].instance()
				$Scroll/VBC.add_child(illustration)
		var frame = RichTextLabel.new()
		#The frame has to be added to the scene before any bbcode is appended; otherwise, special fonts, such as bold and italics, will not show up.
		#Three guesses as to how I know. If you said "The documentation?", you now have two guesses. The documentation does not appear to specify this, unless I missed it somewhere.
		$Scroll/VBC.add_child(frame)
		#Set the textbox to expand so that all text is visible:
		frame.set_fit_content_height(true)
		#Add text:
		frame.set_use_bbcode(true)
		frame.append_bbcode(section.text)
		frame.connect("meta_clicked", self, "forward_meta_clicked")

func forward_meta_clicked(meta):
	emit_signal("meta_clicked", meta)
