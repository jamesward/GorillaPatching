package 
{

import mx.resources.ResourceBundle;

[ExcludeClass]

public class en_US$layout_properties extends ResourceBundle
{

    public function en_US$layout_properties()
    {
		 super("en_US", "layout");
    }

    override protected function getContent():Object
    {
        var content:Object =
        {
            "basicLayoutNotVirtualized": "BasicLayout doesn't support virtualization.",
            "invalidIndex": "invalidIndex"
        };
        return content;
    }
}



}
