class_name HeightmapSampler

var image: Image
var img_width: int
var img_height: int

# Call this before using the sampler.
# Load your heightmap as an Image, not a Texture.
func load_from_path(path: String) -> bool:
	var texture := load(path) as Texture2D
	if texture == null:
		push_error("HeightmapSampler: failed to load texture at %s" % path)
		return false
	image = texture.get_image()
	if image == null:
		push_error("HeightmapSampler: texture has no image data at %s" % path)
		return false
	img_width = image.get_width()
	img_height = image.get_height()
	print("HeightmapSampler: loaded %dx%d format=%d" % [img_width, img_height, image.get_format()])
	return true

# Given a point on the unit sphere, return a height value in [0, 1].
# Caller is responsible for scaling by displacement amount.
func sample(unit_dir: Vector3) -> float:
	var uv := _dir_to_uv(unit_dir)
	return _sample_bilinear(uv.x, uv.y)

# Equirectangular: longitude -> U, latitude -> V
func _dir_to_uv(d: Vector3) -> Vector2:
	var lon := atan2(d.x, d.z)           # -PI to PI
	var lat := asin(clamp(d.y, -1.0, 1.0))  # -PI/2 to PI/2
	var u := (lon / (2.0 * PI)) + 0.5
	var v := 1.0 - ((lat / PI) + 0.5)  # flip V
	return Vector2(u, v)

func _sample_bilinear(u: float, v: float) -> float:
	# Pixel coordinates in [0, width/height)
	var px := u * float(img_width)
	var py := v * float(img_height)

	# Integer pixel coords of the four neighbors
	var x0 := int(px) % img_width
	var y0 := int(py) % img_height
	var x1 := (x0 + 1) % img_width
	var y1 := (y0 + 1) % img_height

	# Fractional part for interpolation
	var fx: float = px - floor(px)
	var fy: float = py - floor(py)

	var c00 := _get_height(x0, y0)
	var c10 := _get_height(x1, y0)
	var c01 := _get_height(x0, y1)
	var c11 := _get_height(x1, y1)

	return lerp(lerp(c00, c10, fx), lerp(c01, c11, fx), fy)

# Reads the red channel. For 16-bit single-channel images Godot
# packs the value into the red channel as a float in [0,1].
func _get_height(x: int, y: int) -> float:
	return image.get_pixel(x, y).r
