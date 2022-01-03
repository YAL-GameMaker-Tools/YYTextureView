package;
import haxe.crypto.Crc32;
import haxe.io.Bytes;
import haxe.zip.Writer;

/**
 * ...
 * @author YellowAfterlife
 */
class YyZipWriter extends Writer {
	public function writeEntrySimple(path:String, bytes:Bytes, pos:Int, len:Int) {
		var o = this.o;
		var flags = 0;
		o.writeInt32(0x04034B50);
		o.writeUInt16(0x0014); // version
		o.writeUInt16(flags); // flags
		o.writeUInt16(0);
		var time = Date.now();
		writeZipDate(time);
		var crc = new Crc32();
		crc.update(bytes, pos, len);
		var crc32 = crc.get();
		o.writeInt32(crc32);
		o.writeInt32(len);
		o.writeInt32(len);
		o.writeUInt16(path.length);
		o.writeUInt16(0);
		o.writeString(path);
		files.add({
			name : path,
			compressed : false,
			clen : len,
			size : len,
			crc : crc32,
			date : time,
			fields : Bytes.alloc(0)
		});
	}
}
