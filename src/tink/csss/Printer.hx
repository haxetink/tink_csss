package tink.csss;

import tink.csss.Selector;

class Printer {

  var SPACE:String;
  
  public function new(space)
    this.SPACE = space;

  public function part(p:SelectorPart) {

    var ret = switch p.tag {
      case null | '' | '*': '';
      case v: v;
    }    

    switch p.id {
      case null | '': 
      case v: ret += '#$v';
    }

    for (c in p.classes)
      ret += '.$c';

    for (a in p.attrs)
      ret += '[${a.name}${a.op}${attrValue(a.value)}]';

    for (p in p.pseudos)
      ret += pseudo(p);

    return switch ret {
      case '': '*';
      default: ret;
    }
  }

  static function attrValue(v:String) {
    if (v == null) return '';
    var quoted = false;
    var ret = '';
    
    for (i in 0...v.length) {
      var char = v.charAt(i);
      switch char {
        case '"' | "'" | '\\':
          ret += '\\';
          quoted = true;
        case ']' | '[':
          quoted = true;
        default:
      }
      ret += char;
    }
    return
      if (quoted) '"$ret"';
      else ret;
  }

  public function option(o:SelectorOption) 
    return 
      if (o.length == 0) '*';
      else {
        var ret = part(o[0]);

        for (i in 1...o.length)
          ret += (switch o[i - 1].combinator {
            case null: ' ';
            case v: '$SPACE$v$SPACE';
          }) + part(o[i]);
        ret;
      }

  public function selector(s:Selector)
    return [for (o in s) option(o)].join(',$SPACE');

  inline function args(factor:Int, offset:Int)
    return switch [factor, offset] {
      case [0, o]: '$o';
      case [f, 0]: '${f}n';
      case [f, o] if (o > 0): '${f}n$SPACE+$SPACE$o';
      case [f, o]: '${f}n$SPACE-$SPACE${-o}';
    }

  public function pseudo(p:Pseudo) 
    return switch p {
      case Vendored(s): s;
      case Dir(s): ':dir($s)';
      case Lang(s): ':name($s)';
      case NthChild(factor, offset): ':nth-child(${args(factor, offset)})';
      case NthLastChild(factor, offset): ':nth-last-child(${args(factor, offset)})';
      case NthLastOfType(factor, offset): ':nth-last-of-type(${args(factor, offset)})';
      case NthOfType(factor, offset): ':nth-of-type(${args(factor, offset)})';
      case Has(s): ':has(${selector(s)})';
      case Is(s): ':is(${selector(s)})';
      case Not(s): ':not(${selector(s)})';
      case Where(s): ':where(${selector(s)})';
      case Active: ':active';
      case AnyLink: ':any-link';
      case Blank: ':blank';
      case Checked: ':checked';
      case Current: ':current';
      case Default: ':default';
      case Defined: ':defined';
      case Disabled: ':disabled';
      case Drop: ':drop';
      case Empty: ':empty';
      case Enabled: ':enabled';
      case FirstChild: ':first-child';
      case FirstOfType: ':first-of-type';
      case Fullscreen: ':fullscreen';
      case Future: ':future';
      case Focus: ':focus';
      case FocusVisible: ':focus-visible';
      case FocusWithin: ':focus-within';
      case Hover: ':hover';
      case Indeterminate: ':indeterminate';
      case InRange: ':in-range';
      case Invalid: ':invalid';
      case LastChild: ':last-child';
      case LastOfType: ':last-of-type';
      case Link: ':link';
      case LocalLink: ':local-link';
      case OnlyChild: ':only-child';
      case OnlyOfType: ':only-of-type';
      case Optional: ':optional';
      case OutOfRange: ':out-of-range';
      case Past: ':past';
      case PlaceholderShown: ':placeholder-shown';
      case ReadOnly: ':read-only';
      case ReadWrite: ':read-write';
      case Required: ':required';
      case Right: ':right';
      case Root: ':root';
      case Scope: ':scope';
      case Target: ':target';
      case TargetWithin: ':target-within';
      case UserInvalid: ':user-invalid';
      case Valid: ':valid';
      case Visited: ':visited';
      case GrammarError: '::grammar-error';
      case Marker: '::marker';
      case Placeholder: '::placeholder';
      case Selection: '::selection';
      case SpellingError: '::spelling-error';
      case After: '::after';
      case Before: '::before';
      case Cue: '::cue';
      case FirstLetter: '::first-letter';
      case FirstLine: '::first-line';
  }
}
