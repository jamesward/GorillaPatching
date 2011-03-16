/**
 * Created by IntelliJ IDEA.
 * User: James Ward <james@jamesward.org>
 * Date: 3/14/11
 * Time: 5:00 PM
 */
package
{
import flash.utils.ByteArray;
import flash.utils.Endian;

public class SwfTag
{

  public function SwfTag()
  {
    recordHeader = new ByteArray();
    recordHeader.endian = Endian.LITTLE_ENDIAN;
    name = new String();
  }


  public var name:String;

  public var type:uint;

  public var tagLengthExcludingRecordHeader:uint;

  public var tagBody:ByteArray;

  public var recordHeader:ByteArray;

}
}
