package tink.csss;

import tink.parse.Char.*;
import tink.csss.Selector;
import tink.core.Error;
using tink.core.Outcome;
using StringTools;

#if !macro
private class RuntimeReporter implements tink.parse.Reporter.ReporterObject<Pos, Error> {

  var pos:Pos;

  public function new(pos)
    this.pos = pos;

  public function makeError(message:String, pos:Pos):Error
    return new Error(UnprocessableEntity, message, pos);

  public function makePos(from:Int, to:Int):Pos
    return pos;

}
#end
class Parser<Position, Error> extends tink.parse.ParserBase<Position, Error> {
  static var IDENT_START = "_" || UPPER || LOWER;
  static var IDENT_CONTD = IDENT_START || DIGIT || '-';
  static var SELECTOR_START = IDENT_START || '#*:[.';

  function ident(here = false)
    return
      if ((here && is(IDENT_START)) || (!here && upNext(IDENT_START)))
        Success(readWhile(IDENT_CONTD));
      else
        Failure(makeError('Identifier expected', makePos(pos)));

  override function doSkipIgnored()
    doReadWhile(WHITE);

  function parseFullSelector():Selector {
    var ret = [];
    do ret.push(switch parseSelector() {
      case { length : 0 }: die('selector expected');
      case v: v;
    })
    while (allow(','));
    return ret;
  }

  function parseString() {
    var end =
      if (allow("'")) "'";
      else {
        expect('"');
        '"';
      }
    return upto(end).sure();
  }


  function parseSelector():SelectorOption {
    var ret:Array<SelectorPart> = [];
    while (upNext(SELECTOR_START)) {
      var s = parseSelectorPart();
      var pos = this.pos;
      ret.push({
        id: s.id,
        tag: s.tag,
        classes: s.classes,
        pseudos: s.pseudos,
        attrs: s.attrs,
        combinator:
          if (allow('~')) GeneralSibling;
          else if (allow('+')) AdjacentSibling;
          else if (allow('>')) Child;
          else Descendant
      });
      if (this.pos == pos) break;
    }
    return ret;
  }

  function parseSelectorPart() {
    var tag = switch ident() {
      case Success(tag): tag.toString();
      default:
        allow('*');
        null;
    }
    var ret = { tag: tag, id: null, classes: [], attrs: new Array<AttrFilter>(), pseudos: [] };
    while (true) {
      if (allowHere('#')) {
        if (ret.id != null) die('cannot have multiple ids (already have ${ret.id})');
        else ret.id = ident(true).sure();
      }
      else if (allowHere(':'))
        ret.pseudos.push(parsePseudo());
      else if (allowHere('[')) {
        var name = ident().sure();
        ret.attrs.push(
          if (allow(']')) { name: name, op: None, value: null }
          else {
            name: name,
            op:
              if (allow('~=')) WhitespaceSeperated
              else if (allow('|=')) HyphenSeparated
              else if (allow('^=')) BeginsWith
              else if (allow('$=')) EndsWith
              else if (allow('*=')) Contains
              else if (allow('=')) Exactly
              else die('operator expected'),
            value:
              (switch ident() {
                case Success(v): v;
                default: parseString();
              }) + expect(']'),
          }
        );
      }
      else if (allowHere('.'))
        ret.classes.push(ident(true).sure().toString());
      else break;
    }
    return ret;
  }

  function parseInt(?here = false) {
    if (!here) skipIgnored();
    return
      if (!is(DIGIT)) Failure(makeError('number expected', makePos(this.pos)));
      else Success(Std.parseInt(this.readWhile(DIGIT)));
  }

  static public function parse(source, ?pos)
    return
      try {
        #if macro
        if (pos == null)
          pos = haxe.macro.Context.currentPos();
        var pos = haxe.macro.Context.getPosInfos(pos);
        var offset = pos.min;
        var reporter = tink.parse.Reporter.expr(pos.file);
        #else
        var offset = 0;
        var reporter = new RuntimeReporter(pos);
        #end
        var p = new Parser(source, reporter, offset);
        var s = p.parseFullSelector();
        if (p.pos < p.source.length)
          p.die('expected selector end');
        else
          Success(s);
      }
      catch (e:Error) Failure(e);


  function parsePseudo():Pseudo {

    var cls = !allowHere(':');

    var name = ident().sure();

    return switch name.toString() {
      case 'lang' if (cls):
        expect('(') + Lang(ident().sure()) + expect(')');
      case 'dir' if (cls):
        expect('(') + Dir(if (allow(Rtl)) Rtl else if (allow(Ltr)) Ltr else die('expected `$Rtl` or `$Ltr`')) + expect(')');
      case ELEMENTS[_] => found if (found != null): found;
      case SIMPLE[_] => found if (cls && found != null): found;
      case STRICT_ELEMENTS[_] => found if (!cls && found != null): found;
      case FANCY[_] => ctor if (cls && ctor != null):
        expect('(') + ctor(parseFullSelector()) + expect(')');
      case NUMERIC[_] => ctor if (cls && ctor != null):
        expect('(');
        var sign = if (allow('-')) -1 else 1;

        function withFactor(factor:Int)
          return
            ctor(
              sign * factor,
              if (allow('-')) -parseInt().sure()
              else if (allow('+')) parseInt().sure()
              else 0
            );

        (if (allowHere('n'))
          withFactor(1);
        else {
          var i = parseInt(true).sure();
          if (allowHere('n')) withFactor(i);
          else ctor(0, i * sign);
        }) + expect(')');
      default:
        reject(name);
    }
  }

  static var FANCY = [
    'has' => Has,
    'is' => Is,
    'not' => Not,
    'where' => Where,
  ];

  static var NUMERIC = [
    'nth-child' => NthChild,
    'nth-last-child' => NthLastChild,
    'nth-last-of-type' => NthLastOfType,
    'nth-of-type' => NthOfType,
  ];

  static var STRICT_ELEMENTS = [
    'grammar-error' => GrammarError,
    'marker' => Marker,
    'placeholder' => Placeholder,
    'selection' => Selection,
    'spelling-error' => SpellingError,
  ];

  static var ELEMENTS = [
    'after' => After,
    'before' => Before,
    'cue' => Cue,
    'first-letter' => FirstLetter,
    'first-line' => FirstLine,
  ];

  static var SIMPLE:Map<String, Pseudo> = [
    'odd' => NthChild(2, 1),
    'even' => NthChild(2, 0),
    'active' => Active,
    'any-link' => AnyLink,
    'blank' => Blank,
    'checked' => Checked,
    'current' => Current,
    'default' => Default,
    'defined' => Defined,
    'disabled' => Disabled,
    'drop' => Drop,
    'empty' => Empty,
    'enabled' => Enabled,
    // 'first' => First,
    // 'left' => Left,
    'first-child' => FirstChild,
    'first-of-type' => FirstOfType,
    'fullscreen' => Fullscreen,
    'future' => Future,
    'focus' => Focus,
    'focus-visible' => FocusVisible,
    'focus-within' => FocusWithin,
    'hover' => Hover,
    'indeterminate' => Indeterminate,
    'in-range' => InRange,
    'invalid' => Invalid,
    'last-child' => LastChild,
    'last-of-type' => LastOfType,
    'link' => Link,
    'local-link' => LocalLink,
    'only-child' => OnlyChild,
    'only-of-type' => OnlyOfType,
    'optional' => Optional,
    'out-of-range' => OutOfRange,
    'past' => Past,
    'placeholder-shown' => PlaceholderShown,
    'read-only' => ReadOnly,
    'read-write' => ReadWrite,
    'required' => Required,
    'right' => Right,
    'root' => Root,
    'scope' => Scope,
    'target' => Target,
    'target-within' => TargetWithin,
    'user-invalid' => UserInvalid,
    'valid' => Valid,
    'visited' => Visited,
  ];
}