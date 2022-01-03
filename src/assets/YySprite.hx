package assets;
import YyTexture.YyTextureFormat;
import haxe.ds.Vector;

/**
 * ...
 * @author YellowAfterlife
 */
class YySprite extends YyAsset {
	public var width:Int;
	public var height:Int;
	public var xoffset:Int;
	public var yoffset:Int;
	public var imagePos:Vector<Int>;
	public function new() {
		super();
	}
	override public function proc() {
		name = file.readRefAString();
		width = file.readInt32();
		height = file.readInt32();
		file.position += 4 * 9; // bbox, transparent, smooth, preload, sepmasks?
		xoffset = file.readInt32();
		yoffset = file.readInt32();
		var imageNum = file.readInt32();
		if (file.v2) {
			var sprVersion = file.readInt32(); // version
			var type = file.readInt32();
			file.readInt32(); // playback speed (f32)
			file.readInt32(); // playback speed type
			//
			if (sprVersion >= 2) {
				file.readInt32(); // sequences data address
				if (sprVersion >= 3) {
					file.readInt32(); // 9slice data address
				}
			}
			//
			if (type == 0) {
				imageNum = file.readInt32();
			} else imageNum = 0;
		}
		imagePos = new Vector(imageNum);
		for (i in 0 ... imageNum) imagePos[i] = file.readInt32();
	}
}
