package;
import assets.YyAsset;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.Constraints.Constructible;
import haxe.ds.Vector;

/**
 * ...
 * @author YellowAfterlife
 */
class YyInput extends BytesInput {
	public var bytes:Bytes;
	public var start:Int = 0;
	public var chunks:Map<String, Int>;
	public var textures:Vector<YyTexture>;
	public var v2:Bool = false;
	public function new(b:Bytes) {
		bytes = b;
		super(b);
	}
	public function readInt32Vector():Vector<Int> {
		var n = readInt32();
		var r = new Vector<Int>(n);
		for (i in 0 ... n) r[i] = readInt32();
		return r;
	}
	public function readCString():String {
		var q = position, n = 0;
		while (readByte() != 0) n++;
		position = q;
		var r = readString(n);
		readByte();
		return r;
	}
	public function readRefCString():String {
		var q = position;
		position = start + readInt32();
		var r = readCString();
		position = q + 4;
		return r;
	}
	//
	public function readAString():String {
		var q = position;
		var s = "";
		var b = readByte();
		while (b != 0) {
			s += String.fromCharCode(b);
			b = readByte();
		}
		return s;
	}
	public function readRefAString():String {
		var q = position;
		position = start + readInt32();
		var s = readAString();
		position = q + 4;
		return s;
	}
	//
	@:generic public function readAssets<T:YyAsset&Constructible<Void->Void>>(chunk:String, ?type:Class<T>):Vector<T> {
		var chPos = chunks[chunk];
		if (chPos == null) return null;
		var oldPos = position;
		position = chPos;
		var count = readInt32();
		var items = new Vector<T>(count);
		for (i in 0 ... count) {
			var item = new T();
			item.file = this;
			item.index = i;
			item.position = start + this.readInt32();
			items[i] = item;
		}
		for (item in items) {
			position = item.position;
			item.proc();
		}
		position = oldPos;
		return items;
	}
}
