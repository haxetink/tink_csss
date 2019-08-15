package tink.csss;

using tink.CoreApi;

typedef Selector = ListOf<SelectorOption>;

typedef SelectorOption = ListOf<SelectorPart>;

typedef SelectorPart = {
  @:optional var id(default, never):String;
  @:optional var tag(default, never):String;
  @:optional var classes(default, never):ListOf<String>;
  @:optional var attrs(default, never):ListOf<AttrFilter>;
  @:optional var pseudos(default, never):ListOf<Pseudo>;
  @:optional var combinator(default, never):Combinator;
}

abstract ListOf<T>(Array<T>) from Array<T> {
  public var length(get, never):Int;

  function get_length()
    return if (this == null) 0 else this.length;

  @:arrayAccess inline function get(index:Int)
    return if (this == null) null else this[index];

  public function map<R>(f:T->R):ListOf<R>
    return switch this {
      case null: null;
      case v: v.map(f);
    }

  public function concat(that:ListOf<T>):ListOf<T>
    return switch [this, that] {
      case [null, v] | [v, null]: v;
      default: this.concat(cast that);
    }
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
  Vendored(s:String);
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

@:enum abstract AttrOperator(String) to String {
  var None = '';
  var WhitespaceSeperated = '~=';
  var HyphenSeparated = '|=';
  var BeginsWith = '^=';
  var EndsWith = '$=';
  var Contains = '*=';
  var Exactly = '=';
}

@:enum abstract Combinator(String) to String {
  var Descendant = null;
  var Child = '>';
  var AdjacentSibling = '+';
  var GeneralSibling = '~';
}