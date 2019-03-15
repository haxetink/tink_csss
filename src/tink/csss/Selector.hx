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

@:enum abstract Directionality(String) to String {
  var Rtl = 'rtl';
  var Ltr = 'ltr';
}

enum Pseudo {
  Active;
  AnyLink;
  Blank;
  Checked;
  Current;
  Default;
  Defined;
  Dir(d:Directionality);
  Disabled;
  Drop;
  Empty;
  Enabled;
  FirstChild;
  FirstOfType;
  Fullscreen;
  Future;
  Focus;
  FocusVisible;
  FocusWithin;
  Has(s:Selector);
  Hover;
  Indeterminate;
  InRange;
  Invalid;
  Is(s:Selector);
  Lang(lang:String);
  LastChild;
  LastOfType;
  // Left;
  // First;
  Link;
  LocalLink;
  Not(s:Selector);
  NthChild(factor:Int, offset:Int);
  NthLastChild(factor:Int, offset:Int);
  NthLastOfType(factor:Int, offset:Int);
  NthOfType(factor:Int, offset:Int);
  OnlyChild;
  OnlyOfType;
  Optional;
  OutOfRange;
  Past;
  PlaceholderShown;
  ReadOnly;
  ReadWrite;
  Required;
  Right;
  Root;
  Scope;
  Target;
  TargetWithin;
  UserInvalid;
  Valid;
  Visited;
  Where(s:Selector);
  GrammarError;
  Marker;
  Placeholder;
  Selection;
  SpellingError;
  After;
  Before;
  Cue;
  FirstLetter;
  FirstLine;
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