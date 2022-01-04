package;

import YyTexture.YyTextureFormat;
import assets.*;
import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.BytesInput;
import haxe.io.UInt8Array;
import haxe.zip.Writer;
import js.Browser;
import js.Lib;
import js.html.AnchorElement;
import js.lib.ArrayBuffer;
import js.html.Blob;
import js.html.DivElement;
import js.html.Element;
import js.html.Event;
import js.html.FileList;
import js.html.FileReader;
import js.html.FormElement;
import js.html.HTMLDocument;
import js.html.ImageElement;
import js.html.InputElement;
import js.html.DragEvent;
import js.html.KeyboardEvent;
import js.html.LabelElement;
import js.html.MouseEvent;
import js.html.TextAreaElement;
import js.html.Uint8Array;
import js.html.Uint8ClampedArray;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class Main {
	static var document(get, never):HTMLDocument;
	static inline function get_document():HTMLDocument {
		return js.Syntax.code("document");
	}
	
	static var form:FormElement;
	static var navPane:Element;
	static var editor:TextAreaElement;
	public static var status:LabelElement;
	static var start:Int;
	static var input:YyInput;
	static var bytes:Bytes;
	public static var path:String;
	public static var textures:Vector<YyTexture>;
	public static var textureAnchors:Vector<AnchorElement>;
	public static var hasSpriteList:Bool = false;
	public static var hasFrameSprites:Bool = false;
	public static var sprites:Vector<YySprite> = null;
	public static var spriteAnchors:Vector<AnchorElement> = null;
	public static var images:Vector<YyImage> = null;
	public static var imageMap:Map<Int, YyImage> = null;
	public static var imagesPerTP:Vector<Array<YyImage>> = null;
	static function resetTex() {
		textures = null;
		textureAnchors = null;
		hasSpriteList = false;
		hasFrameSprites = false;
		sprites = null;
		spriteAnchors = null;
		images = null;
		imageMap = null;
		imagesPerTP = null;
		pannerNotes.innerHTML = "";
		pannerImage.style.clipPath = "";
	}
	static var current:YyTexture;
	static var panner:Panner;
	static var pannerUnder:ImageElement;
	static var pannerImage:ImageElement;
	static var pannerNotes:DivElement;
	/// https://stackoverflow.com/questions/5775469/whats-the-valid-way-to-include-an-image-with-no-src#comment71592987_14115340
	static var noImage:String = "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7";
	
	static inline var clError = "error";
	static inline var clWarning = "warning";
	
	public static function show(text:String, cl:String = "", ?html:Bool) {
		status.className = cl;
		if (!html) {
			status.innerHTML = "";
			status.appendChild(Browser.document.createTextNode(text));
		} else status.innerHTML = text;
	}
	
	static function thousands(v:Int) {
		var c = String.fromCharCode(8239);
		var s = Std.string(v);
		var i = s.length - 3;
		while (i > 0) {
			s = s.substring(0, i) + c + s.substring(i);
			i -= 3;
		}
		return s;
	}
	
	public static function next(fn:Void->Void) {
		Browser.window.setTimeout(fn, 1);
	}
	
	static function replaceTexture(files:FileList) {
		//
		for (file in files) {
			var reader = new FileReader();
			reader.onloadend = function(_) {
				var abuf:ArrayBuffer = reader.result;
				var b = Bytes.ofData(abuf);
				var bn = b.length;
				var cn = current.size;
				var cp = current.pos;
				if (bn <= cn) {
					bytes.blit(cp, b, 0, bn);
					if (bn < cn) bytes.fill(cp + bn, cn - bn, 0);
					current.base64 = null;
					current.canvas = null;
					var cur = document.getElementById("nav-current");
					if (cur != null) cur.click();
				} else {
					Browser.window.alert('The file (${thousands(b.length)}) may not be larger than source (${thousands(current.size)}). Consider using a PNG optimizer like TinyPNG, PNGCrush, or PNGQuant.');
				}
			};
			reader.readAsArrayBuffer(file);
			break;
		}
	}
	
	static function showTexture_1() {
		show(
			'${pannerImage.width}x${pannerImage.height} &middot; ' +
			'${thousands(current.size)} bytes &middot; ' +
			'Image Format: ${YyTexture.texformat} &middot; ' +
			'<a href="#" onclick="return saveTexture()">Save?</a> &middot; ' +
			'<a href="#" onclick="${(YyTexture.texformat != YyTextureFormat.PNG) ? "return formatReplaceAlert()" : "document.getElementById(\'replacer\').click(); return false"}">Replace?</a>',
		'', true);
	}
	
	static function showTextureImpl(tx:YyTexture, un:Bool) {
		if (tx == current) {
			if (un) {
				if (pannerUnder.src == noImage) pannerUnder.src = pannerImage.src;
			} else if (pannerUnder.src != noImage) pannerUnder.src = noImage;
			return;
		}
		current = tx;
		panner.pan = tx.pan;
		panner.forceUpdate();
		if (!un) pannerUnder.src = noImage;
		if (tx.base64 == null) {
			show('Loading image (${Math.ceil(tx.size/1024)}KB)...');
			pannerImage.src = noImage;
			if (un) pannerUnder.src = noImage;
			next(function() {
				var b64 = tx.getBase64(input);
				if (un) pannerUnder.src = b64;
				pannerImage.src = b64;
				next(function() showTexture_1());
			});
		} else {
			if (un) pannerUnder.src = tx.base64;
			pannerImage.src = tx.base64;
			next(function() showTexture_1());
		}
	}
	
	static function showTexture(i:Int, link:AnchorElement) {
		var cur = document.getElementById("nav-current");
		if (cur != null) cur.id = null;
		link.id = "nav-current";
		//
		var tx = textures[i];
		pannerNotes.innerHTML = "";
		pannerImage.style.clipPath = "";
		showTextureImpl(tx, false);
		return false;
	}
	
	static function showSprite(sprID:Int, link:AnchorElement) {
		var cur = document.getElementById("nav-current");
		if (cur != null) cur.id = null;
		link.id = "nav-current";
		//
		var sprite:YySprite = sprites[sprID];
		if (sprite.imagePos.length == 0) return false;
		var img:YyImage = new YyImage();
		img.file = input;
		var texID:Int = -1;
		var clip = "";
		var subimg = 0;
		var markers:Array<PannerMarker> = [];
		for (subimg in 0 ... sprite.imagePos.length) {
			input.position = input.start + sprite.imagePos[subimg];
			img.proc();
			if (texID == -1) texID = img.texture;
			var ix = img.srcLeft, iy = img.srcTop;
			var iw = img.srcWidth, ih = img.srcHeight;
			var mk_info = '${iw}x$ih at $ix,$iy';
			var mj = markers.length;
			var mk:PannerMarker;
			while (--mj >= 0) {
				mk = markers[mj];
				if (mk.info == mk_info) {
					mk.frames.push(subimg);
					break;
				}
			}
			if (mj < 0) markers.push({
				style:'left:${ix}px;top:${iy}px;width:${iw}px;height:${ih}px',
				info:mk_info,
				index:subimg,
				frames:[subimg]
			});
			clip += '<rect x="$ix" y="$iy" width="$iw" height="$ih"/>\n';
		}
		//
		pannerNotes.innerHTML = "";
		for (mk in markers) {
			var mkd = document.createDivElement();
			var mkm = mk.frames.length > 1;
			mkd.setAttribute("data-index", mk.index + (mkm ? "*" : ""));
			mkd.setAttribute("style", mk.style);
			mkd.setAttribute("data-info", mkm ? mk.info + "\n#" + mk.frames.join(" ") : mk.info);
			pannerNotes.appendChild(mkd);
		}
		//
		document.getElementById("pan-clip").innerHTML = clip;
		var tx = textures[texID];
		pannerImage.style.clipPath = "url(#pan-clip)";
		showTextureImpl(tx, true);
		return false;
	}
	
	static function readYySprites(input:YyInput) {
		//input.position = input.chunks["SPRT"];
		var sprites = Main.sprites;
		if (sprites == null) {
			sprites = input.readAssets("SPRT", YySprite);
			Main.sprites = sprites;
			images = input.readAssets("TPAG", YyImage);
			imageMap = SaveSprites.makeImageMap(input, images);
		}
		if (!hasFrameSprites) {
			var im = imageMap;
			imagesPerTP = new Vector(textures.length);
			for (i in 0 ... textures.length) imagesPerTP[i] = [];
			for (spriteID in 0 ... sprites.length) {
				var sprite = sprites[spriteID];
				var frames = sprite.imagePos;
				for (frameID in 0 ... frames.length) {
					var frame = im[frames[frameID]];
					if (frame == null) continue;
					imagesPerTP[frame.texture].push(frame);
					frame.sprite = spriteID;
				}
			}
		}
		//
		spriteAnchors = new Vector(sprites.length);
		navPane.appendChild(document.createHRElement());
		for (i in 0 ... sprites.length) {
			var q:YySprite = sprites[i];
			var link = Browser.document.createAnchorElement();
			spriteAnchors[i] = link;
			link.href = "#";
			link.setAttribute("onclick", 'return showSprite($i, this)');
			var s = i + ' ${q.name} (${q.width}x${q.height}'
				+ '; ${q.xoffset},${q.yoffset}'
				+ ') [${q.imagePos.length}] ';
			//var s = i + " (" + tx.width + "x" + tx.height + ", " + Math.ceil(tx.size / 1024) + "KB)";
			link.appendChild(Browser.document.createTextNode(s));
			link.oncontextmenu = function(e) {
				Browser.window.prompt("", q.name);
				e.preventDefault();
			};
			navPane.appendChild(link);
		}
	}
	
	static function readYyAssets(input:YyInput) {
		Main.input = input;
		show("Looking for assets...");
		next(function() readYyAssets_0(input));
	}
	
	static function readYyAssets_0(input:YyInput) {
		var endsAt:Int = 0;
		while (input.position < input.length) {
			if (input.readInt32() != 0x4d524f46/* 'FORM' */) continue;
			endsAt = input.readInt32();
			endsAt += input.position;
			if (input.readInt32() != 0x384e4547/* 'GEN8' */) continue;
			input.position -= 4;
			break;
		}
		if (input.position < input.length) {
			start = input.position - 8;
			input.start = start;
			show("Found assets!");
			next(function() readYyAssets_1(input, endsAt));
		} else show("The file does not contain assets.", clError);
	}
	
	static function readYyAssets_1(input:YyInput, endsAt:Int) {
		var chunks = new Map<String, Int>();
		while (input.position < endsAt) {
			var chName = input.readString(4);
			var chSize = input.readInt32();
			chunks[chName] = input.position;
			input.position += chSize;
		}
		input.chunks = chunks;
		if (chunks["GEN8"] != null) {
			input.position = chunks["GEN8"] + 44;
			if (input.readInt32() == 2) {
				input.v2 = true;
			}
		}
		if (chunks["TXTR"] != null) {
			show("Found textures!");
			input.position = chunks["TXTR"];
			next(function() readYyAssets_2(input));
		} else show("The file does not contain a textures-section.", clError);
	}
	
	static function readYyAssets_2(input:YyInput) {
		input.position -= 4;
		var endsAt = input.readInt32();
		document.getElementById("filename").title = untyped (endsAt / 1024 / 1024).toFixed(2) 
			+ "MB textures total";
		endsAt += input.position;
		var n = input.readInt32(), i:Int;
		if (n == 0) {
			show("The file contains 0 textures.", clWarning);
			return;
		}
		var txs = new Vector<YyTexture>(n);
		var tx:YyTexture = null;
		i = -1; while (++i < n) {
			tx = new YyTexture(input);
			tx.index = i;
			tx.name = "tex" + i;
			tx.pos = input.readInt32();
			txs[i] = tx;
		}
		var lx:YyTexture = null;
		i = -1; while (++i < n) {
			tx = txs[i];
			input.position = start + tx.pos;
			input.readInt32(); // ?
			if (input.v2) input.readInt32(); // ??
			tx.pos = start + input.readInt32();
			if (lx != null) lx.size = tx.pos - lx.pos;
			lx = tx;
		}
		if (lx != null) lx.size = endsAt - lx.pos;
		resetTex();
		input.textures = txs;
		textures = txs;
		textureAnchors = new Vector(txs.length);
		//
		i = -1; while (++i < n) {
			tx = txs[i];
			tx.measure(input);
			var link = Browser.document.createAnchorElement();
			textureAnchors[i] = link;
			link.href = "#";
			link.setAttribute("onclick", 'return showTexture($i, this)');
			var s = i + " (" + tx.width + "x" + tx.height + ", " + Math.ceil(tx.size / 1024) + "KB)";
			link.appendChild(Browser.document.createTextNode(s));
			navPane.appendChild(link);
		}
		show("All good.");
	}
	
	static function save_1(link:AnchorElement, dl:String) {
		link.target = "_blank";
		link.download = dl;
		link.setAttribute("download", dl);
		//
		var ctr = document.body;
		ctr.appendChild(link);
		link.click();
		ctr.removeChild(link);
	}
	
	public static function saveBytes(bytes:Bytes, path:String, contentType:String = "application/octet-stream") {
		var link:AnchorElement = cast document.createElement("a");
		link.href = Tools.bytesToBlobURL(bytes, path, contentType);
		save_1(link, path);
	}
	
	static function hideMenu() {
		Browser.window.setTimeout(function() {
			Browser.document.getElementById('menu').style.display = 'none';
		});
	}
	
	static function saveYyAssets(_:Event):Bool {
		hideMenu();
		if (bytes == null) return false;
		saveBytes(bytes, path);
		return false;
	}
	
	static function saveImages(_:Event):Bool {
		hideMenu();
		if (bytes == null) return false;
		SaveSprites.proc(input, false);
		return false;
	}
	
	static function saveStrips(_:Event):Bool {
		hideMenu();
		if (bytes == null) return false;
		SaveSprites.proc(input, true);
		return false;
	}

	static function formatReplaceAlert() {
		Browser.window.alert("We're sorry, replacing non-PNG texture pages is not possible with this tool, please consider 'UndertaleModTool' instead.");
		return false;
	}
	
	static function saveTexture() {
		var link:AnchorElement = cast document.createElement("a");
		var dl = current.name + ".png";
		if (YyTexture.texformat == YyTextureFormat.PNG) {
			try {
				var arr = UInt8Array.fromBytes(bytes, current.pos, current.size);
				var blob = new Blob([cast arr], { type: "image/png" });
				//
				var nav:Dynamic = Browser.navigator;
				if (nav.msSaveBlob != null) {
					nav.msSaveBlob(blob, dl);
					return false;
				}
				//
				link.href = js.html.URL.createObjectURL(blob);
			} catch (_:Dynamic) {
				link.href = "data:image/png;base64," + current.base64;
			}
		}
		else {
			Browser.window.console.log("Saving a non-png texture via base64...");
			// should use cached base64 if present...
			link.href = current.getBase64(current.file, true);
		}
		save_1(link, dl);
		return false;
	}
	
	static function navPaneKeys(e:KeyboardEvent) {
		var d:Int;
		switch (e.keyCode) {
			case 38: d = -1;
			case 40: d = 1;
			default: d = 0;
		}
		if (d != 0) {
			var cur = document.getElementById("nav-current");
			if (cur == null) {
				var cc = navPane.children;
				cur = d > 0 ? cc[0] : cc[cc.length - 1];
			} else {
				cur = d > 0 ? cur.nextElementSibling : cur.previousElementSibling;
			}
			if (cur != null) {
				navPane.scrollBy(0, cur.scrollHeight * d);
				cur.click();
			}
			e.preventDefault();
			return false;
		}
		return null;
	}
	
	static function reset() {
		navPane.innerHTML = "";
		pannerUnder.src = noImage;
		pannerImage.src = noImage;
		pannerImage.style.clipPath = "";
		pannerNotes.innerHTML = "";
		bytes = null;
		resetTex();
		current = null;
	}
	
	static function main() {
		Reflect.setField(Browser.window, "showTexture", showTexture);
		Reflect.setField(Browser.window, "saveTexture", saveTexture);
		Reflect.setField(Browser.window, "formatReplaceAlert", formatReplaceAlert);
		Reflect.setField(Browser.window, "showSprite", showSprite);
		var doc = Browser.document;
		var body = doc.body;
		navPane = doc.getElementById("nav");
		navPane.addEventListener("keydown", navPaneKeys);
		editor = cast doc.getElementById("source");
		status = cast doc.getElementById("status");
		pannerUnder = cast doc.getElementById("pan-under"); pannerUnder.src = noImage;
		pannerImage = cast doc.getElementById("pan-image"); pannerImage.src = noImage;
		pannerNotes = cast doc.getElementById("pan-notes");
		var pannerCtr:Element = doc.getElementById("pan-ctr");
		panner = new Panner(cast doc.getElementById("pan"), cast pannerCtr);
		//
		function cancelDefault(e:Event) {
			e.preventDefault();
			return false;
		}
		//
		pannerCtr.oncontextmenu = function(e:MouseEvent) {
			if (!hasSpriteList || current == null) return null;
			//if (!e.ctrlKey) return null;
			if ((cast e.target:Element).hasAttribute("data-index")) {
				showTexture(current.index, textureAnchors[current.index]);
			} else {
				var mx = e.offsetX;
				var my = e.offsetY;
				for (img in imagesPerTP[current.index]) {
					var rx = mx - img.srcLeft;
					var ry = my - img.srcTop;
					if (rx >= 0 && ry >= 0 && rx < img.srcWidth && ry < img.srcHeight) {
						var el = spriteAnchors[img.sprite];
						if (el != null) {
							el.scrollIntoView();
							showSprite(img.sprite, el);
						}
						break;
					}
				}
			}
			return cancelDefault(e);
		};
		//
		function handleFiles(files:FileList) {
			for (file in files) {
				reset();
				show("Reading file...");
				path = file.name;
				var fne = document.getElementById("filename");
				fne.innerHTML = "";
				fne.appendChild(document.createTextNode(path));
				var reader = new FileReader();
				reader.onloadend = function(_) {
					var abuf:ArrayBuffer = reader.result;
					bytes = Bytes.ofData(abuf);
					readYyAssets(new YyInput(bytes));
				};
				reader.readAsArrayBuffer(file);
				break;
			}
		}
		body.addEventListener("dragover", cancelDefault);
		body.addEventListener("dragenter", cancelDefault);
		body.addEventListener("drop", function(e:DragEvent) {
			e.preventDefault();
			handleFiles(e.dataTransfer.files);
			return false;
		});
		//
		form = cast doc.getElementById("form");
		var picker:InputElement = cast doc.getElementById("picker");
		picker.addEventListener("change", function(e:Event) {
			handleFiles(picker.files);
			next(function() form.reset());
		});
		var replacer:InputElement = cast doc.getElementById("replacer");
		replacer.addEventListener("change", function(e:Event) {
			replaceTexture(replacer.files);
			next(function() form.reset());
		});
		doc.getElementById("saver").addEventListener("click", saveYyAssets);
		doc.getElementById("show-sprites").addEventListener("click", function(_) {
			hideMenu();
			if (!hasSpriteList && input != null) {
				hasSpriteList = true;
				readYySprites(input);
			}
		});
		doc.getElementById("save-images").addEventListener("click", saveImages);
		doc.getElementById("save-strips").addEventListener("click", saveStrips);
		//
		var menu = doc.getElementById("menu");
		doc.addEventListener("mousedown", function(e:MouseEvent) {
			if (menu.style.display != "") return;
			var el:Element = cast e.target;
			while (el != null) {
				if (el == menu) return;
				el = el.parentElement;
			}
			menu.style.display = "none";
		});
	}
	
}
typedef PannerMarker = {style:String, index:Int, info:String, frames:Array<Int>};
