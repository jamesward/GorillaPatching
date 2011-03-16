package {
import flash.display.Loader;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.MouseEvent;
import flash.net.FileReference;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.system.ApplicationDomain;
import flash.system.LoaderContext;
import flash.utils.ByteArray;
import flash.utils.Endian;

import org.as3commons.bytecode.reflect.ByteCodeType;
import org.as3commons.bytecode.util.SWFSpec;
import org.as3commons.reflect.Metadata;
import org.as3commons.reflect.MetadataArgument;

[Frame(extraClass="RevealPrivatesPatcher")]
[SWF(width="600", height="700")]
public class GorillaPatcher extends Sprite {

  // todo: externalize the applicationURL
  private static const applicationURL:String = "Testapp2.swf";
  private var loader:Loader;
  private var isStageRoot:Boolean = true;
  private var originalBytes:ByteArray;
  public var modifiedBytes:ByteArray;

  public function GorillaPatcher()
  {
    super();
    stage.scaleMode = StageScaleMode.NO_SCALE;
    stage.align = StageAlign.TOP_LEFT;

    stage.addEventListener(Event.RESIZE, resizeHandler);

    stage.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):void {
      var file:FileReference = new FileReference();
      file.save(modifiedBytes, "MyGeneratedClasses.swf");
    });

    var urlLoader:URLLoader = new URLLoader();
    urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
    urlLoader.addEventListener(Event.COMPLETE, handleOriginalSwfLoad);
    urlLoader.load(new URLRequest(applicationURL));
  }

  private function handleOriginalSwfLoad(event:Event):void
  {
    var input:ByteArray = (event.currentTarget as URLLoader).data as ByteArray;
    trace("input.length = " + input.length);
    if (input.readByte() == 0x43)
    {
      var swfGuts:ByteArray = new ByteArray();
      input.position = 0;
      swfGuts.writeBytes(input, 8);
      trace('swfGuts.length = ' + swfGuts.length);
      swfGuts.position = 0;
      swfGuts.uncompress();

      originalBytes = new ByteArray();
      originalBytes.endian = Endian.LITTLE_ENDIAN;
      originalBytes.writeByte(0x46);
      originalBytes.writeByte(0x57);
      originalBytes.writeByte(0x53);
      originalBytes.writeByte(0x0a);
      originalBytes.writeUnsignedInt(swfGuts.length + 8);
      originalBytes.writeBytes(swfGuts);
    }
    else
    {
      originalBytes = input;
    }
    originalBytes.position = 0;

    var swfTags:Array = getSwfTags(originalBytes);

    trace("originalBytes.length = " + originalBytes.length);

    ByteCodeType.fromByteArray(originalBytes);

    for each (var patcherClassName:String in ByteCodeType.getClassesWithMetadata("Patcher"))
    {
      var t:ByteCodeType = ByteCodeType.forName(patcherClassName);

      for each (var metadata:Metadata in t.metadata)
      {
        if (metadata.name == "Patcher")
        {

          // create the patcher based on the "type" argument in the metadata
          var patcher:IPatcher;
          for each (var ma1:MetadataArgument in metadata.arguments)
          {
            if (ma1.key == "type")
            {
              var patcherClass:Class = this.loaderInfo.applicationDomain.getDefinition(ma1.value) as Class;
              patcher = new patcherClass();
            }
          }

          // set any properties on the patcher
          for each (var ma2:MetadataArgument in metadata.arguments)
          {
            try
            {
              patcher[ma2.key] = ma2.value;
            }
            catch (e:Error)
            {
              // ignore
            }
          }

          patcher.run(swfTags);

          /*var abcBuilder:IAbcBuilder = new AbcBuilder();
          var packageBuilder:IPackageBuilder  = abcBuilder.definePackage("blah");
          var classBuilder:IClassBuilder = packageBuilder.defineClass("Foo");
          var methodBuilder:IMethodBuilder = classBuilder.defineMethod("getPrivateBar");
          methodBuilder.scopeName = "public";
          methodBuilder.returnType = "String";
          methodBuilder.addOpcode(Opcode.getlocal_0).addOpcode(Opcode.pushscope).addOpcode(Opcode.pushstring, ["fuck bar"]).addOpcode(Opcode.returnvalue);

          var abcFile:AbcFile = abcBuilder.build();

          var abcSerializer:AbcSerializer = new AbcSerializer();
          var abcByteArray:ByteArray = abcSerializer.serializeAbcFile(abcFile);*/


        }
      }
    }
    /*
    if (swfTag.name == "blah/Foo")
      {
        for each (var abcHeaderByte:int in [0x3f, 0x12])
        {
          modifiedBytes.writeByte(abcHeaderByte);
        }
        modifiedBytes.writeInt(abcByteArray.length);
        modifiedBytes.writeBytes(abcByteArray);
      }
      else
      {
     */

    modifiedBytes = new ByteArray();
    modifiedBytes.endian = Endian.LITTLE_ENDIAN;

    for each (var swfHeaderByte:int in [0x46, 0x57, 0x53, 0x0a, 0xff, 0xff, 0xff, 0xff, 0x70, 0x00, 0x0b, 0xb8, 0x00, 0x00, 0xbb, 0x80, 0x00, 0x18, 0x02, 0x00])
    {
      modifiedBytes.writeByte(swfHeaderByte);
    }

    for each (var swfTag:SwfTag in swfTags)
    {
      modifiedBytes.writeBytes(swfTag.recordHeader);
      modifiedBytes.writeBytes(swfTag.tagBody);
    }

    // write the swf footer
    modifiedBytes.writeByte(0);
    modifiedBytes.writeByte(0);

    // set the length of the total SWF
    modifiedBytes.position = 4;
    modifiedBytes.writeUnsignedInt(modifiedBytes.length);

    modifiedBytes.position = 0;

    trace('modifiedBytes.length = ' + modifiedBytes.length);

    //trace(HexDump.dumpHex(modifiedBytes));

    loader = new Loader();
    loader.width = stage.width;
    loader.height = stage.height;
    addChild(loader);
    loader.contentLoaderInfo.addEventListener(Event.INIT, handleInit);
    loader.contentLoaderInfo.addEventListener(Event.COMPLETE, handleComplete);
    loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, handleIOError);
    loader.addEventListener("mx.managers.SystemManager.isBootstrapRoot", bootstrapRootHandler);
    loader.addEventListener("mx.managers.SystemManager.isStageRoot", stageRootHandler);

    var loaderContext:LoaderContext = new LoaderContext();
    loaderContext.applicationDomain = ApplicationDomain.currentDomain;

    loader.loadBytes(modifiedBytes, loaderContext);
  }

  private function getSwfTags(originalBytes:ByteArray):Array
  {
    var swfTags:Array = new Array();

    // skip the header
    originalBytes.position = 8;

    // read framesize
    var fsByte:uint = originalBytes.readUnsignedByte();
    // it's really only 5 bits
    fsByte >>>= 3;

    // there are 4 of them
    var fsBits:uint = fsByte * 4;

    // we already read 3 extra bits
    fsBits -= 3;

    // number of additional bytes to move to get past the framesize
    var fsBytes:uint = Math.ceil(fsBits / 8);

    originalBytes.position += fsBytes;

    // move another 4 bytes past the frame rate and frame count
    originalBytes.position += 4;

    // read the tags
    while (originalBytes.position < (originalBytes.length - 2))
    {
      swfTags.push(readTag(originalBytes))
    }

    trace('swfTags.length = ' + swfTags.length);

    originalBytes.position = 0;

    return swfTags;
  }

  private function readTag(originalBytes:ByteArray):SwfTag
  {
    var swfTag:SwfTag = new SwfTag();

    // read the record header
    var tagCodeAndLength:uint = originalBytes.readUnsignedShort();
    swfTag.recordHeader.writeShort(tagCodeAndLength);
    swfTag.type = tagCodeAndLength >> 6;
    swfTag.tagLengthExcludingRecordHeader = tagCodeAndLength & 0x3f;
    if (swfTag.tagLengthExcludingRecordHeader == 0x3f)
    {
      swfTag.tagLengthExcludingRecordHeader = originalBytes.readUnsignedInt();
      swfTag.recordHeader.writeUnsignedInt(swfTag.tagLengthExcludingRecordHeader);
    }
    swfTag.tagBody = new ByteArray();
    if (swfTag.tagLengthExcludingRecordHeader > 0)
    {
      originalBytes.readBytes(swfTag.tagBody, 0, swfTag.tagLengthExcludingRecordHeader);
    }

    //trace('type = ' + swfTag.type);
    //trace('tagLengthExcludingRecordHeader = ' + swfTag.tagLengthExcludingRecordHeader);
    //trace(HexDump.dumpHex(swfTag.tagBody));
    
    if (swfTag.type == 82)
    {
      // skip the flags
      swfTag.tagBody.position += 4;

      swfTag.name = SWFSpec.readString(swfTag.tagBody);

      swfTag.tagBody.position = 0;
    }

    return swfTag;
  }

  private function handleIOError(event:IOErrorEvent):void
  {
    trace('ioerror ' + event);
  }

  private function handleInit(event:Event):void
  {
    trace('handleInit');
  }

  private function handleComplete(event:Event):void
  {
    trace("complete " + event.currentTarget.bytesLoaded);
  }

  private function bootstrapRootHandler(event:Event):void
  {
    trace('bootstrapRootHandler');
    event.preventDefault();
  }

  private function stageRootHandler(event:Event):void
  {
    trace('stageRootHandler');
    if (!isStageRoot)
      event.preventDefault();
  }

  private function resizeHandler(event:Event):void
  {
    if (loader != null)
    {
      loader.width = stage.width;
      loader.height = stage.height;
      Object(loader.content).setActualSize(stage.width, stage.height);
    }
  }
  
}
}