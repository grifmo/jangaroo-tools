package ext.config {

[ExtConfig(target="Ext.Label")]
public class label {

  /**
   * The text of the label
   */
  public native function get text():String;
  /**
   * @private
   */
  public native function set items(text:String):void;
}
}