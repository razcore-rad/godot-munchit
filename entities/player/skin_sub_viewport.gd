class_name SkinSubViewport extends SubViewport

signal blob_added(blob_count: int)
signal blob_removed(blob_count: int)

const BlobPinJoint2DPackedScene: PackedScene = preload("blob_pin_joint_2d.tscn")

const MAX_BLOBS := 5

@onready var blobs: Node2D = %Blobs2D
@onready var blob_animatable_body: AnimatableBody2D = %BlobAnimatableBody2D


func add_blob() -> void:
	var blob_count := blobs.get_child_count() - 1
	if blob_count >= MAX_BLOBS:
		return

	var blob_pin_joint: PinJoint2D = BlobPinJoint2DPackedScene.instantiate()
	blob_pin_joint.position *= (-1 if blob_count % 2 == 0 else 1)
	blobs.add_child(blob_pin_joint)
	blob_pin_joint.node_a = blob_pin_joint.get_path_to(blob_animatable_body)
	blob_added.emit(blob_count)


func remove_blob() -> void:
	var blob_count := blobs.get_child_count() - 1
	blobs.get_children().back().queue_free()
	blob_removed.emit(blob_count)
