extends RefCounted

const C_KEY := "#7fd4ff"
const C_TIME := "#ffb84a"
const C_QUOTE := "#ffe08a"
const C_NUM := "#9cf08a"
const TAGS := {
	"y": "#ffd24a",
	"r": "#ff5a4a",
	"g": "#6ee06e",
	"gr": "#a3a3ad",
	"bl": "#5fb4ff",
	"o": "#ff9a3c",
}

static var _re_time: RegEx = null
static var _re_quote: RegEx = null
static var _re_num: RegEx = null
static var _re_tag: RegEx = null

static func _init_re() -> void:
	if _re_time != null:
		return
	_re_time = RegEx.new()
	_re_time.compile("(?<![\\w:])\\d{1,2}:\\d{2}(?![\\w:])")
	_re_quote = RegEx.new()
	_re_quote.compile("«[^«»]{1,40}»|\"[^\"]{1,40}\"|「[^「」]{1,40}」")
	_re_num = RegEx.new()
	_re_num.compile("(?<![\\w:])\\d+%")
	_re_tag = RegEx.new()
	_re_tag.compile("\\[(/?)(y|r|g|gr|bl|o)\\]")

static func plain(text: String) -> String:
	_init_re()
	return _re_tag.sub(text, "", true)

static func fmt(text: String, keys: Array = []) -> String:
	_init_re()
	var s = _re_tag.sub(text, "\u0002$1$2\u0003", true)
	s = s.replace("[", "\u0001")
	s = _wrap(s, _re_quote, C_QUOTE)
	s = _wrap(s, _re_time, C_TIME)
	s = _wrap(s, _re_num, C_NUM)
	for k in keys:
		var key = String(k).strip_edges()
		if key == "" or key.length() > 12:
			continue
		var re = RegEx.new()
		re.compile("(?<![\\p{L}\\p{N}\\[=#\\x{2}/])" + _esc(key) + "(?![\\p{L}\\p{N}\\]\\x{3}])")
		s = _wrap(s, re, C_KEY)
	for t in TAGS:
		s = s.replace("\u0002" + t + "\u0003", "[color=" + TAGS[t] + "]")
		s = s.replace("\u0002/" + t + "\u0003", "[/color]")
	return s.replace("\u0001", "[lb]")

static func _wrap(s: String, re: RegEx, col: String) -> String:
	var out := ""
	var last := 0
	for m in re.search_all(s):
		var a = m.get_start()
		var b = m.get_end()
		if _inside_tag(s, a):
			continue
		out += s.substr(last, a - last) + "[color=" + col + "]" + s.substr(a, b - a) + "[/color]"
		last = b
	return out + s.substr(last)

static func _inside_tag(s: String, i: int) -> bool:
	var o = s.rfind("[", i)
	if o >= 0 and s.rfind("]", i) < o:
		return true
	var o2 = s.rfind("\u0002", i)
	return o2 >= 0 and s.rfind("\u0003", i) < o2

static func _esc(k: String) -> String:
	var out := ""
	for ch in k:
		if "\\^$.|?*+()[]{}/".contains(ch):
			out += "\\" + ch
		else:
			out += ch
	return out
