package;
import js.html.CanvasElement;

enum YyTextureFormat {
	PNG;
	QOIF;
	QOZ2;
}

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
	public static var texformat:YyTextureFormat = YyTextureFormat.PNG;
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
			if (texformat == YyTextureFormat.PNG) {
				out = "data:image/png;base64," + Tools.base64of(input.bytes, pos, size);
			}
			else if (texformat == YyTextureFormat.QOIF) {
				out = Tools.decodeQoif(input.bytes, pos);
			}
			else if (texformat == YyTextureFormat.QOZ2) {
				out = Tools.decodeQoz2(input.bytes, pos, size);
			}

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
		// peek at the first four bytes to try and guess the image type.
		// as for now, there are three of them:
		// %PNG - old GM or Texture Preview .win
		// qoif - QOI without a Bzip2 pass (Run-mode or Debug-mode wins)
		// qoz2 - QOI with a Bzip2 pass (Create Executable/Installer wins)
		// can't you tell I am wasting my life ;-;
		var filesig = input.readInt32();
		input.position -= 4;
		if (filesig == 0x474e5089) {
			// Just do the old code:
			texformat = YyTextureFormat.PNG;
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
			input.readInt32(); // crc
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
		else if (filesig == 0x716f6966) {
			// QOIF no bzip2 pass
			texformat = YyTextureFormat.QOIF;
			//
			input.readInt32(); // "fioq"
			//
			width = input.readUInt16();
			height = input.readUInt16();
		}
		else if (filesig == 0x716f7a32) {
			// QOIF+bzip2 level 9
			texformat = YyTextureFormat.QOZ2;
			//
			input.readInt32(); // "2zoq"
			//
			width = input.readUInt16();
			height = input.readUInt16();
		}
	}
}
