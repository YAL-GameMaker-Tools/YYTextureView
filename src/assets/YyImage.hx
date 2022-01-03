package assets;

/**
 * ...
 * @author YellowAfterlife
 */
class YyImage extends YyAsset {
	//
	public var srcLeft:Int;
	public var srcTop:Int;
	public var srcWidth:Int;
	public var srcHeight:Int;
	//
	public var dstLeft:Int;
	public var dstTop:Int;
	public var dstWidth:Int;
	public var dstHeight:Int;
	//
	public var outWidth:Int;
	public var outHeight:Int;
	//
	public var texture:Int;
	public var sprite:Int = -1;
	public var base64:String = null;
	//
	override public function proc() {
		srcLeft = file.readUInt16();
		srcTop = file.readUInt16();
		srcWidth = file.readUInt16();
		srcHeight = file.readUInt16();
		//
		dstLeft = file.readUInt16();
		dstTop = file.readUInt16();
		dstWidth = file.readUInt16();
		dstHeight = file.readUInt16();
		//
		outWidth = file.readUInt16();
		outHeight = file.readUInt16();
		texture = file.readUInt16();
	}
	public function getBase64() {
		if (base64 == null) {
			var cnv = js.Browser.document.createCanvasElement();
			cnv.width = outWidth;
			cnv.height = outHeight;
			var ctx = cnv.getContext2d();
			ctx.imageSmoothingEnabled = false;
			ctx.drawImage(file.textures[texture].canvas,
				srcLeft, srcTop, srcWidth, srcHeight,
				dstLeft, dstTop, dstWidth, dstHeight);
			base64 = cnv.toDataURL();
		}
		return base64;
	}
}
