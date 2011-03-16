/**
 * Created by IntelliJ IDEA.
 * User: jamesw
 * Date: 2/8/11
 * Time: 11:36 AM
 * To change this template use File | Settings | File Templates.
 */
package
{
import flash.utils.ByteArray;

import org.as3commons.bytecode.swf.SWFFile;

public interface IPatcher
{
  function run(swfTags:Array):void;
}
}