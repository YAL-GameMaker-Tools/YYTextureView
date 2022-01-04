package;
import haxe.io.BytesData;
import haxe.io.BytesBuffer;
import js.lib.Uint8Array;
import haxe.io.Bytes;
import js.Browser;
import js.html.Blob;
import haxe.io.UInt8Array;
/**
 * ...
 * @author YellowAfterlife
 */
class Tools {
	public static function decodeQoGeneric(input:Uint8Array, offset:Int, width:Int, height:Int) {
		var cnv = js.Browser.document.createCanvasElement();
		cnv.width = width;
		cnv.height = height;
		var rawpixlen = width * height * 4;
		var cnv_ctx = cnv.getContext2d();
		var imgdat = new js.html.ImageData(width, height);
		var rgbapixels = imgdat.data;

		// indexed color buffer
		var workbuff = new js.lib.Int32Array(64);

		// the rest of this function has been copy&pasted from
		// YoYoImage.dll:GMAssetCompiler.YoYoImage.ReadQOIF(Stream _stream);
		// sorry yoyo
		// god help us.
		var repeats = 0;
		var num6 = 0xff000000;
		var num7 = offset;
		var num8 = 0;

		while (num8 < rawpixlen) {
			var num9 = input[num7++];
			if ((num9 & 0x80) != 0) {
				if ((num9 & 0x40) == 0) {
					num6 = (num6 & 0xFFFFFF00) | (((num6 & 0xFF) + ((num9 & 0x30) << 26 >> 30)) & 0xFF);
					num6 = (num6 & 0xFFFF00FF) | (((num6 & 0xFF00) + ((num9 & 0xC) << 28 >> 22)) & 0xFF00);
					num6 = (num6 & 0xFF00FFFF) | (((num6 & 0xFF0000) + ((num9 & 3) << 30 >> 14)) & 0xFF0000);
				}
				else if ((num9 & 0x20) == 0) {
					var num10 = input[num7++];
					var num11 = (num9 << 8) | num10;
					num6 = (num6 & 0xFFFFFF00) | (((num6 & 0xFF) + ((num11 & 0x1F00) << 19 >> 27)) & 0xFF);
					num6 = (num6 & 0xFFFF00FF) | (((num6 & 0xFF00) + ((num11 & 0xF0) << 24 >> 20)) & 0xFF00);
					num6 = (num6 & 0xFF00FFFF) | (((num6 & 0xFF0000) + ((num11 & 0xF) << 28 >> 12)) & 0xFF0000);
				}
				else if ((num9 & 0x10) == 0) {
					var num12 = input[num7++];
					var num13 = input[num7++];
					var num14 = (num9 << 16) | (num12 << 8) | num13;
					num6 = (num6 & 0xFFFFFF00) | (((num6 & 0xFF) + ((num14 & 0xF8000) << 12 >> 27)) & 0xFF);
					num6 = (num6 & 0xFFFF00FF) | (((num6 & 0xFF00) + ((num14 & 0x7C00) << 17 >> 19)) & 0xFF00);
					num6 = (num6 & 0xFF00FFFF) | (((num6 & 0xFF0000) + ((num14 & 0x3E0) << 22 >> 11)) & 0xFF0000);
					num6 = (num6 & 0x00FFFFFF) | (((num6 & -16777216) + ((num14 & 0x1F) << 27 >> 3)) & 0xFF000000);
				}
				else {
					if ((num9 & 8) != 0) {
						num6 = (num6 & 0xFFFFFF00) | input[num7++];
					}
					if ((num9 & 4) != 0) {
						num6 = (num6 & 0xFFFF00FF) | (input[num7++] << 8);
					}
					if ((num9 & 2) != 0) {
						num6 = (num6 & 0xFF00FFFF) | (input[num7++] << 16);
					}
					// ??? this is how it was in YoYoImage... perhaps a debug flag? whatever.
					if ((num9 & (true?1:0)) != 0) {
						num6 = (num6 & 0x00FFFFFF) | (input[num7++] << 24);
					}
				}
				var num15 = num6 & 0xFF;
				var num16 = (num6 >> 8) & 0xFF;
				var num17 = (num6 >> 16) & 0xFF;
				var num18 = (num6 >> 24) & 0xFF;
				var num19 = (num15 ^ num16 ^ num17 ^ num18) & 0x3F;
				workbuff[num19] = num6;
				// must always use &0xff since ImageData is a clamped array and we must do &0xff ourselves...
				rgbapixels[num8++] = num15 & 0xff;
				rgbapixels[num8++] = num16 & 0xff;
				rgbapixels[num8++] = num17 & 0xff;
				rgbapixels[num8++] = num18 & 0xff;
			}
			else {
				if ((num9 & 0x40) == 0) {
					num6 = workbuff[num9];
				}
				else if ((num9 & 0x20) == 0) {
					repeats = num9 & 0x1F;
				}
				else {
					var repeats2ORd = input[num7++];
					repeats = (((num9 & 0x1F) << 8) | repeats2ORd) + 32;
				}
				rgbapixels[num8++] = num6 & 0xff;
				rgbapixels[num8++] = (num6 >> 8) & 0xff;
				rgbapixels[num8++] = (num6 >> 16) & 0xff;
				rgbapixels[num8++] = (num6 >> 24) & 0xff;
				while (repeats > 0) {
					rgbapixels[num8++] = num6 & 0xff;
					rgbapixels[num8++] = (num6 >> 8) & 0xff;
					rgbapixels[num8++] = (num6 >> 16) & 0xff;
					rgbapixels[num8++] = (num6 >> 24) & 0xff;
					repeats--;
				}
			}
		}

		cnv_ctx.putImageData(imgdat, 0, 0);
		return cnv.toDataURL("png");
	}
	public static function decodeQoif(input:Bytes, offset:Int) {
		var hdr = input.getInt32(offset);
		if (hdr != 0x716f6966) {
			// not a qoif file o_O
			Browser.window.console.error("Not a valid qoif file..? Expected 'fioq' got " + hdr);
			return "";
		}

		var width = input.getUInt16(offset + 4);
		var height = input.getUInt16(offset + 6);
		// length of compressed data after the 12byte header
		// not used in this particular implementation due to optimization concerns.
		var qoidatalen = input.getInt32(offset + 8);
		var qoidatastart = offset + 12;

		return decodeQoGeneric(new Uint8Array(input.getData()), qoidatastart, width, height);
	}
	public static function decodeQoz2(input:Bytes, offset:Int, length:Int) {
		var hdr = input.getInt32(offset);
		if (hdr != 0x716f7a32) {
			// not a qoz2 file o_O
			Browser.window.console.error("Not a valid qoz2 file..? Expected '2zoq' got " + hdr);
			return "";
		}

		var width = input.getUInt16(offset + 4);
		var height = input.getUInt16(offset + 6);
		// after height comes the Bzip2 header and data...
		var qoibzipstart = offset + 8;
		
		// TODO: apparently passing `length` here breaks the bz2 decompressor..?
		var qoibzu8arr = new Uint8Array(input.getData(), qoibzipstart);
		var qoidata = Bz2Js.decompress(qoibzu8arr, false);
		// qoidata actually contains the qoif header and width and height duplicated....
		// so we must skip 12 bytes

		return decodeQoGeneric(qoidata, 12, width, height);
	}
	public static function base64of(bytes:Bytes, offset:Int, length:Int) {
		var pos = 0;
		var raw = "";
		while (pos < length) {
			var end = pos + 0x8000;
			if (end > length) end = length;
			var sub = UInt8Array.fromBytes(bytes, offset + pos, end - pos);
			raw += untyped js.Syntax.code("String.fromCharCode.apply(null, {0})", sub);
			pos = end;
		}
		return Browser.window.btoa(raw);
	}
	public static function bytesOfBase64(base64:String) {
		var data = Browser.window.atob(base64);
		var out = Bytes.alloc(data.length);
		for (i in 0 ... data.length) {
			out.set(i, StringTools.fastCodeAt(data, i));
		}
		return out;
	}
	public static function bytesOfDataURL(dataURL:String) {
		return bytesOfBase64(dataURL.substring(dataURL.indexOf(",") + 1));
	}
	public static function bytesToBlobURL(bytes:Bytes, path:String, type:String):String {
		try {
			var blob:Blob = new Blob([bytes.getData()], { type: type });
			//
			var nav:Dynamic = Browser.navigator;
			if (nav.msSaveBlob != null) {
				nav.msSaveBlob(blob, path);
				return null;
			}
			//
			return js.html.URL.createObjectURL(blob);
		} catch (err:Dynamic) {
			Browser.window.console.error("Failed to make blob", err);
			return "data:" + type + ";base64," + base64of(bytes, 0, bytes.length);
		}
	}
}
