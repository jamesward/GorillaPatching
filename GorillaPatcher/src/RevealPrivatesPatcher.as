/**
 * Created by IntelliJ IDEA.
 * User: jamesw
 * Date: 2/8/11
 * Time: 11:30 AM
 * To change this template use File | Settings | File Templates.
 */
package
{
import flash.utils.ByteArray;

import org.as3commons.bytecode.abc.InstanceInfo;
import org.as3commons.bytecode.abc.LNamespace;
import org.as3commons.bytecode.abc.MethodInfo;
import org.as3commons.bytecode.abc.MethodTrait;
import org.as3commons.bytecode.abc.TraitInfo;
import org.as3commons.bytecode.abc.enum.NamespaceKind;
import org.as3commons.bytecode.io.AbcSerializer;
import org.as3commons.bytecode.reflect.ByteCodeMethod;
import org.as3commons.bytecode.reflect.ByteCodeType;
import org.as3commons.bytecode.reflect.ByteCodeTypeCache;
import org.as3commons.bytecode.reflect.ReflectionDeserializer;
import org.as3commons.bytecode.swf.SWFFile;
import org.as3commons.bytecode.tags.DoABCTag;
import org.as3commons.bytecode.util.AbcFileUtil;
import org.as3commons.bytecode.util.SWFSpec;
import org.as3commons.reflect.Method;
import org.as3commons.reflect.as3commons_reflect;

use namespace as3commons_reflect;


public class RevealPrivatesPatcher implements IPatcher
{

  public var fullClassName:String;
  public var classTagName:String;

  public var propertyOrMethodName:String;

  public function run(swfTags:Array):void
  {
    trace('RevealPrivatesPatcher run()');

    for each (var swfTag:SwfTag in swfTags)
    {
      if (swfTag.name == classTagName)
      {
        trace('found Foo');

        // deserialize tag
        var byteCodeTypeCache:ByteCodeTypeCache = new ByteCodeTypeCache();

        var gorillaReflectionDeserializer:GorillaReflectionDeserializer = new GorillaReflectionDeserializer(swfTag.tagBody);
        swfTag.tagBody.readInt(); //skip flags
			  SWFSpec.readString(swfTag.tagBody);  // skip name
        gorillaReflectionDeserializer.readABCTag(byteCodeTypeCache, swfTag.tagBody);

        // find the method
        var byteCodeType:ByteCodeType = byteCodeTypeCache.get(byteCodeTypeCache.definitionNames[0]) as ByteCodeType;
        var method:ByteCodeMethod = byteCodeType.getMethod(propertyOrMethodName) as ByteCodeMethod;
        method.as3commons_reflect::setVisibility(NamespaceKind.PACKAGE_NAMESPACE);
        method.as3commons_reflect::setScopeName("public:");

        // modify the tag
        

      }
    }
  }
}
}