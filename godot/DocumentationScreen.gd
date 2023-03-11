extends Control

var documentation = {}
var chapters = []
var page_directory = {}
var current_page = null

func _ready():
	load_documentation_from_file()
	display_contents()

func refresh_contents():
	$Background/Contents.clear()
	var root = $Background/Contents.create_item()
	$Background/Contents.set_hide_root(true)
	for chapter in chapters:
		var chapter_entry = $Background/Contents.create_item(root)
		chapter_entry.set_text(0, chapter.display_title())
		chapter_entry.set_metadata(0, chapter)
		for page in chapter.pages:
			var page_entry = $Background/Contents.create_item(chapter_entry)
			page_entry.set_text(0, page.display_title())
			page_entry.set_metadata(0, page)

func clear_data():
	documentation.clear()
	for chapter in chapters:
		chapter.clear()
	chapters.clear()
	current_page = null

func display_contents():
	refresh_contents()
	current_page = null
	$Background/Contents.visible = true
	$Background/PageDisplay.visible = false

func load_page(page):
	if (null == page):
		display_contents()
	else:
		current_page = page
		$Background/Contents.visible = false
		$Background/PageDisplay.visible = true
		$Background/PageDisplay/PageTitle.set_text(page.display_title())
		$Background/PageDisplay/PageText.display(page)

func load_documentation_from_file():
	#Load data from file:
	var path = "res://custom_resources/writing_with_sweepweave.json"
	var file = File.new()
	file.open(path, File.READ)
	var file_text = file.get_as_text()
	file.close()
	clear_data()
	documentation = JSON.parse(file_text).result
	#Translate dictionary into objects:
	for chapter_data in documentation["chapters"]:
		var chapter = DocChapter.new(chapter_data["title"])
		chapters.append(chapter)
		for page_data in chapter_data["pages"]:
			var page = DocPage.new(chapter, page_data["id"], page_data["title"])
			page_directory[page.id] = page
			for section_data in page_data["sections"]:
				var section = DocSection.new(page, section_data["id"], section_data["title"], section_data["text"], section_data["illustration"])
				page.sections.append(section)
			chapter.pages.append(page)

func _on_Contents_item_selected():
	var item = $Background/Contents.get_selected()
	var selection = item.get_metadata(0)
	if (selection is DocPage):
		load_page(selection)
	elif (selection is DocChapter):
		load_page(selection.pages.front())

func _on_GoToContents_pressed():
	display_contents()

func _on_GoToPrevious_pressed():
	if (null == current_page):
		display_contents()
	elif (null == current_page.chapter):
		display_contents()
	var current_chapter = current_page.chapter
	var page_index = current_chapter.pages.find(current_page)
	var chapter_index = chapters.find(current_chapter)
	if (-1 == page_index or -1 == chapter_index):
		#Error
		display_contents()
	elif (0 == page_index):
		if (0 == chapter_index):
			#The current page is already the first page of the documentation.
			display_contents()
		else:
			var previous_chapter = chapters[chapter_index - 1]
			load_page(previous_chapter.pages.back())
	else:
		load_page(current_chapter.pages[page_index - 1])

func _on_GoToNext_pressed():
	if (null == current_page):
		display_contents()
	elif (null == current_page.chapter):
		display_contents()
	var current_chapter = current_page.chapter
	var page_index = current_chapter.pages.find(current_page)
	var chapter_index = chapters.find(current_chapter)
	if (-1 == page_index or -1 == chapter_index):
		#Error
		display_contents()
	elif (current_chapter.pages.size() - 1 == page_index):
		if (chapters.size() - 1 == chapter_index):
			#The current page is already the last page of the documentation.
			display_contents()
		else:
			var next_chapter = chapters[chapter_index + 1]
			load_page(next_chapter.pages.front())
	else:
		load_page(current_chapter.pages[page_index + 1])

func _on_PageText_meta_clicked(meta):
	if ("http" == meta.left(4)):
		OS.shell_open(meta)
	elif (page_directory.has(meta)):
		var page = page_directory[meta]
		load_page(page)

#GUI Themes:

onready var previous_icon_light = preload("res://custom_resources/arrow-left.svg")
onready var previous_icon_dark = preload("res://custom_resources/arrow-left_dark.svg")
onready var next_icon_light = preload("res://custom_resources/arrow-right.svg")
onready var next_icon_dark = preload("res://custom_resources/arrow-right_dark.svg")

func set_gui_theme(theme_name, background_color):
	match theme_name:
		"Clarity":
			$Background/PageDisplay/Footer/GoToPrevious.icon = previous_icon_dark
			$Background/PageDisplay/Footer/GoToNext.icon = next_icon_dark
		"Lapis Lazuli":
			$Background/PageDisplay/Footer/GoToPrevious.icon = previous_icon_light
			$Background/PageDisplay/Footer/GoToNext.icon = next_icon_light
	$Background.color = background_color
