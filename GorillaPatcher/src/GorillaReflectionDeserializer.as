/**
 * Created by IntelliJ IDEA.
 * User: James Ward <james@jamesward.org>
 * Date: 3/14/11
 * Time: 9:35 PM
 */
package
{
import flash.utils.ByteArray;

import org.as3commons.bytecode.reflect.ReflectionDeserializer;

public class GorillaReflectionDeserializer extends ReflectionDeserializer
{

  public function GorillaReflectionDeserializer(byteArray:ByteArray)
  {
    super();
    _byteStream = byteArray;
  }

}
}