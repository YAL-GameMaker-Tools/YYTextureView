package;
import Main.next;
import Main.show;
import haxe.crypto.Crc32;
import haxe.ds.Vector;
import assets.*;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.io.Path;
import js.Browser;
import js.html.AnchorElement;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;

/**
 * ...
 * @author YellowAfterlife
 */
class SaveSprites {
	private static var saveStrips:Bool;
	public static function proc(input:YyInput, strip:Bool) {
		saveStrips = strip;
		var ctx:SaveSpritesCtx = {
			imageCount: 0,
			input: input,
		};
		show("Preparing...");
		next(function() procTextures(ctx));
	}
	static function procTextures(ctx:SaveSpritesCtx) {
		var textures = ctx.input.textures;
		var count = textures.length;
		var groups = new Vector(count);
		for (i in 0 ... count) {
			groups[i] = {
				texture: textures[i],
				images: []
			};
		}
		ctx.groups = groups;
		show("Loading images...");
		next(function() procImages(ctx));
	}
	public static function makeImageMap(input:YyInput, images:Vector<YyImage>):Map<Int, YyImage> {
		var imageMap = new Map();
		for (q in images) {
			imageMap.set(q.position - input.start, q);
		}
		return imageMap;
	}
	static function procImages(ctx:SaveSpritesCtx) {
		var images = Main.images;
		if (images == null) {
			images = ctx.input.readAssets("TPAG", YyImage);
			ctx.imageMap = makeImageMap(ctx.input, images);
			Main.imageMap = ctx.imageMap;
			Main.images = images;
		} else ctx.imageMap = Main.imageMap;
		show("Loading sprites...");
		next(function() procSprites(ctx));
	}
	static function procSprites(ctx:SaveSpritesCtx) {
		var sprites = Main.sprites;
		if (sprites == null) {
			sprites = ctx.input.readAssets("SPRT", YySprite);
			Main.sprites = sprites;
		}
		var imageMap = ctx.imageMap;
		var groups = ctx.groups;
		var strips = saveStrips;
		ctx.sprites = sprites;
		for (sprite in sprites) {
			var pfx = sprite.name + "_";
			var imagePos = sprite.imagePos;
			var strip:SaveSpritesStrip = null;
			var count = imagePos.length;
			if (strips) strip = {
				mult: sprite.width,
				width: sprite.width * count,
				height: sprite.height,
				name: pfx + "strip" + count + ".png",
				todoCount: count,
				context: null,
				canvas: null,
			};
			var stripName = (strips && count == 1) ? strip.name : null;
			for (i in 0 ... count) {
				var img = imageMap[imagePos[i]];
				var group = groups[img.texture];
				group.images.push({
					name: strips ? stripName : pfx + i + ".png",
					image: img,
					strip: strip,
					index: i,
				});
				ctx.imageCount += 1;
			}
		}
		show("Saving images...");
		next(function() procGroups(ctx));
	}
	static function procGroups(ctx:SaveSpritesCtx) {
		var groups = ctx.groups;
		var groupIndex = 0;
		var groupCount = groups.length;
		var texture = null;
		var images = null;
		var imageIndex = 0;
		var imageCount = 0;
		var totalIndex = 0;
		var totalCount = ctx.imageCount;
		var procGroup = null;
		var groupCanvas = Browser.document.createCanvasElement();
		var imageCanvas = Browser.document.createCanvasElement();
		var strips = saveStrips;
		var output = new BytesOutput();
		ctx.output = output;
		var zipWriter = new YyZipWriter(output);
		ctx.zipWriter = zipWriter;
		function procImage() {
			if (imageIndex < imageCount) {
				var pair:SaveSpritesImage = images[imageIndex++];
				var image:YyImage = pair.image;
				var pairName:String = pair.name;
				var imgc:CanvasElement, ctx:CanvasRenderingContext2D;
				if (pairName == null) {
					var strip:SaveSpritesStrip = pair.strip;
					imgc = strip.canvas;
					var first = imgc == null;
					if (first) {
						imgc = Browser.document.createCanvasElement();
						imgc.width = strip.width;
						imgc.height = strip.height;
						ctx = imgc.getContext2d();
						ctx.imageSmoothingEnabled = false;
					} else ctx = strip.context;
					//
					ctx.drawImage(groupCanvas,
						image.srcLeft, image.srcTop, image.srcWidth, image.srcHeight,
						image.dstLeft + pair.index * strip.mult,
						image.dstTop, image.dstWidth, image.dstHeight
					);
					//
					if (--strip.todoCount <= 0) {
						strip.canvas = null;
						strip.context = null;
						pairName = strip.name;
					} else if (first) {
						strip.canvas = imgc;
						strip.context = ctx;
					}
				} else {
					imgc = imageCanvas;
					//
					imgc.width = image.outWidth;
					imgc.height = image.outHeight;
					//
					ctx = imgc.getContext2d();
					ctx.imageSmoothingEnabled = false;
					ctx.drawImage(groupCanvas,
						image.srcLeft, image.srcTop, image.srcWidth, image.srcHeight,
						image.dstLeft, image.dstTop, image.dstWidth, image.dstHeight
					);
				}
				if (pairName != null) {
					var bytes = Tools.bytesOfDataURL(imgc.toDataURL());
					zipWriter.writeEntrySimple(pairName, bytes, 0, bytes.length);
					output.writeBytes(bytes, 0, bytes.length);
					bytes = null;
				}
				//
				totalIndex += 1;
				show('Saving images ($totalIndex/$totalCount)...');
				next(procImage);
			} else next(procGroup);
		}
		procGroup = function() {
			if (groupIndex < groupCount) {
				var group = groups[groupIndex++];
				var texture = group.texture;
				groupCanvas.width = texture.width;
				groupCanvas.height = texture.height;
				images = group.images;
				imageIndex = 0;
				imageCount = images.length;
				var texImg = Browser.document.createImageElement();
				texImg.onload = function(_) {
					/*if (imageCount == 1) {
						var first = images[0].image;
						trace(first);
					}*/
					groupCanvas.getContext2d().drawImage(texImg, 0, 0);
					next(procImage);
				};
				texImg.onerror = function(_) {
					trace("Failed to load texture " + groupIndex);
					next(procGroup);
				};
				show('Loading texture ($groupIndex/$groupCount)...');
				texImg.src = texture.getBase64(ctx.input, false);
			} else {
				show("Packing up...");
				next(function() procZip(ctx));
			}
		}
		next(procGroup);
	}
	static function procZip(ctx:SaveSpritesCtx) {
		ctx.zipWriter.writeCDR();
		var output = ctx.output;
		var path = Path.withoutExtension(Main.path) + "-sprites.zip";
		var bytes = output.getBytes();
		bytes = bytes.sub(0, output.length);
		Main.status.innerHTML = 'All good! <a>Click here to get the ZIP</a>.';
		var link:AnchorElement = cast Main.status.querySelector("a");
		link.href = Tools.bytesToBlobURL(bytes, path, "application/zip");
		link.download = path;
	}
}
private typedef SaveSpritesCtx = {
	input:YyInput,
	?groups:Vector<{ texture:YyTexture, images:Array<SaveSpritesImage> }>,
	?imageCount:Int,
	?images:Vector<YyImage>,
	?imageMap:Map<Int, YyImage>,
	?sprites:Vector<YySprite>,
	?output:BytesOutput,
	?zipWriter:YyZipWriter,
}
private typedef SaveSpritesStrip = {
	mult:Int,
	width:Int,
	height:Int,
	name:String,
	canvas:CanvasElement,
	context:CanvasRenderingContext2D,
	todoCount:Int,
}
private typedef SaveSpritesImage = {
	name:String,
	image:YyImage,
	index:Int,
	strip:SaveSpritesStrip,
}
