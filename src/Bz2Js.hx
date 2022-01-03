package;

@:native("window.bz2") extern class Bz2Js {
    public static function decompress(bytes:js.lib.Uint8Array, checkCRC:Bool = false):js.lib.Uint8Array;
}
