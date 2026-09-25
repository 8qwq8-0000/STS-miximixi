extends Node

const MUSIC := preload("res://art/th06_04.wav")
const MUSIC_BOSS := preload("res://art/th06_05.wav")
const SHORT := preload("res://art/slash.ogg")
const TEST_QOA := preload("res://_cn_tools/loopqoa.wav")
const TEST_PCM := preload("res://_cn_tools/looppcm.wav")

var _player: AudioStreamPlayer
var _t0: int = 0
var _prev: int = 0
var _rounds: int = 0


func _ready() -> void:
	print("probe: mix_rate=%d latency=%.1fms to_next_mix=%.1fms" % [AudioServer.get_mix_rate(), AudioServer.get_output_latency() * 1000.0, AudioServer.get_time_to_next_mix() * 1000.0])
	_info("th06_04", MUSIC)
	_info("th06_05", MUSIC_BOSS)
	_info("test_qoa", TEST_QOA)
	_info("test_pcm", TEST_PCM)
	_player = AudioStreamPlayer.new()
	add_child(_player)
	_player.finished.connect(_on_finished)
	_t0 = Time.get_ticks_usec()
	_prev = _t0
	_player.stream = SHORT
	_player.play()


func _info(tag: String, s: AudioStream) -> void:
	var w := s as AudioStreamWAV
	print("probe: %s format=%d loop_mode=%d rate=%d len=%.3f bytes=%d" % [tag, w.format, w.loop_mode, w.mix_rate, w.get_length(), w.data.size()])


func _on_finished() -> void:
	var now := Time.get_ticks_usec()
	print("probe: round %d at %.1f ms, since last %.1f ms (stream %.1f ms)" % [_rounds, (now - _t0) / 1000.0, (now - _prev) / 1000.0, SHORT.get_length() * 1000.0])
	_prev = now
	_rounds += 1
	if _rounds >= 4:
		print("probe: done")
		get_tree().quit()
		return
	_player.play()

