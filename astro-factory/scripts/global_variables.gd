extends Node

var saved_chunk_position = {}
var collision_RID_pool = []
var render_RID_pool = []
var chunk_count = 100
var chunk_size = Vector3i(10,20,10)
var collision_distance = 12
var render_distance = 100
#var active_chunks = {}
