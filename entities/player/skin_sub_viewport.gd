class_name SkinSubViewport extends SubViewport

signal blob_added(blob_count: int)
signal blob_removed(blob_count: int)

const BlobAnimatableBody2DPackedScene: PackedScene = preload("blob_animatable_body_2d.tscn")
const BlobPinJoint2DPackedScene: PackedScene = preload("blob_pin_joint_2d.tscn")

const MAX_BLOBS := 5

var blob_count := 0

@onready var blobs: Node2D = %Blobs2D


func add_blob() -> void:
	blob_count = blobs.get_child_count()
	if blob_count >= MAX_BLOBS:
		return

	blob_count += 1
	var blob := (BlobAnimatableBody2DPackedScene if blob_count == 1 else BlobPinJoint2DPackedScene).instantiate()
	blob.position *= (-1 if blob_count % 2 == 0 else 1)
	blobs.add_child(blob)
	if blob_count > 1:
		blob.node_a = blob.get_path_to(blobs.get_child(0))
	blob_added.emit(blob_count)


func remove_blob() -> void:
	blob_count = blobs.get_child_count() - 1
	if blob_count < 0:
		return
	blobs.get_children().back().queue_free()
	blob_removed.emit(blob_count)
