package;
import js.html.CanvasElement;
import js.html.ImageElement;

/**
 * ...
 * @author YellowAfterlife
 */
class YyTexture {
	//
	public var file:YyInput;
	public var index:Int;
	public var pos:Int;
	public var size:Int;
	public var width:Int;
	public var height:Int;
	public var base64:String = null;
	public var canvas:CanvasElement = null;
	public var name:String = null;
	//
	public var pan:{ x:Float, y:Float, z:Float };
	//
	public function new(input:YyInput) {
		file = input;
		pan = { x: 0, y: 0, z: 0 };
	}
	public function getBase64(input:YyInput, save:Bool = true) {
		var out = base64;
		if (out == null) {
			out = "data:image/png;base64," + Tools.base64of(input.bytes, pos, size);
			if (save) base64 = out;
		}
		return out;
	}
	public function fetchCanvas(fn:CanvasElement->Void) {
		if (canvas == null) {
			var canvas = js.Browser.document.createCanvasElement();
			this.canvas = canvas;
			canvas.width = width;
			canvas.height = height;
			var img = js.Browser.document.createImageElement();
			img.onload = function(_) {
				canvas.getContext2d().drawImage(img, 0, 0);
				fn(canvas);
			};
			img.src = getBase64(file);
		} else fn(canvas);
	}
	public function measure(input:YyInput) {
		input.position = pos;
		width = 0;
		height = 0;
		// %PNG:
		if (input.readByte() != 0x89) return;
		if (input.readByte() != 0x50) return;
		if (input.readByte() != 0x4E) return;
		if (input.readByte() != 0x47) return;
		//
		if (input.readByte() != 0x0D) return;
		if (input.readByte() != 0x0A) return;
		if (input.readByte() != 0x1A) return;
		if (input.readByte() != 0x0A) return;
		//
		input.readInt32();
		//
		if (input.readByte() != "I".code) return;
		if (input.readByte() != "H".code) return;
		if (input.readByte() != "D".code) return;
		if (input.readByte() != "R".code) return;
		//
		width =  input.readByte() << 24;
		width |= input.readByte() << 16;
		width |= input.readByte() << 8;
		width |= input.readByte();
		//
		height =  input.readByte() << 24;
		height |= input.readByte() << 16;
		height |= input.readByte() << 8;
		height |= input.readByte();
	}
}
