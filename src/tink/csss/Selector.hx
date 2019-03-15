package tink.csss;

using tink.CoreApi;

typedef Selector = ListOf<SelectorOption>;

typedef SelectorOption = ListOf<SelectorPart>;

typedef SelectorPart = {
  ?id:String,
  ?tag:String,
  ?classes:ListOf<String>,
  ?attrs:ListOf<AttrFilter>,
  ?pseudos:ListOf<Pseudo>,
  ?combinator:Combinator,
}

abstract ListOf<T>(Array<T>) from Array<T> {
  public var length(get, never):Int;
  function get_length()
    return if (this == null) 0 else this.length;

  @:arrayAccess inline function get(index:Int)
    return if (this == null) null else this[index];
}

typedef AttrFilter = {	
  var name(default, never):String;
  @:optional var value(default, never):String;
  @:optional var op(default, never):AttrOperator;
}

enum Pseudo {
  State(s:ElementState);
  Not(s:Selector);
  Nth(matchType:Bool, factor:Int, offset:Int, backward:Bool);
  Custom(s:String);
}

@:enum abstract ElementState(String) to String {
  
  var Checked = "checked";
  var Invalid = "invalid";
  var Valid = "valid";
  var Focus = "focus";
  var Hover = "hover";

  static public function ofString(s:String, ?pos):Outcome<ElementState, Error>
    return switch s {
      case Checked | Invalid | Valid | Focus | Hover: Success(cast s);
      default: Failure(new Error(UnprocessableEntity, 'unknown state $s'));
    }

}

//TODO: with the next Haxe update, these should become inline enums
enum AttrOperator {
  None;
  Exactly;
  WhitespaceSeperated;
  HyphenSeparated;
  BeginsWith;
  EndsWith;
  Contains;
}

@:enum abstract Combinator(String) {
  var Descendant = null;
  var Child = '>';
  var AdjacentSibling = '+';
  var GeneralSibling = '~';
}