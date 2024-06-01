extends Area2D

@export var life = 10
signal hurt
signal death


func receive_damage(amount):
	life -= amount
	print("Life: ", life, ", Damage: ", amount)
	if life <= 0:
		death.emit()
		pass
	else: 
		hurt.emit()


func _on_body_entered(body: Node):
	var hitbox = body.find_child("Hitbox")
	if hitbox != null && hitbox.get_parent() != self.get_parent():
		print("*This body: ", self.get_parent().name, " || Body encountered: ", body.name, "*")
		receive_damage(hitbox.damage)
		hitbox.impact.emit()
