class_name SkinSubViewport extends SubViewport

signal blobs_removed

const BlobPinJoint2DPackedScene: PackedScene = preload("blob_pin_joint_2d.tscn")

@onready var blobs: Node2D = %Blobs2D
@onready var blob_animatable_body: AnimatableBody2D = %BlobAnimatableBody2D


func add_blob() -> void:
	var child_count := blobs.get_child_count()
	if child_count >= 4:
		return

	var blob_pin_joint: PinJoint2D = BlobPinJoint2DPackedScene.instantiate()
	blob_pin_joint.position *= (-1 if child_count % 2 == 0 else 1)
	blobs.add_child(blob_pin_joint)
	blob_pin_joint.node_a = blob_pin_joint.get_path_to(blob_animatable_body)


func remove_blob() -> void:
	var child_count := blobs.get_child_count()
	blobs.get_child(child_count - 1).queue_free()
	if child_count < 2:
		blobs_removed.emit()
