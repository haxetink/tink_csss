package tink.csss;

import tink.parse.Char.*;
import tink.csss.Selector;
import tink.core.Error;

using tink.core.Outcome;
using StringTools;

class ParserBase<Pseudo, Pos, Error> extends tink.parse.ParserBase<Pos, Error> {
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
  
  function parseFullSelector():SelectorOf<Pseudo> {
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


  function parseSelector():SelectorOptionOf<Pseudo> {
    var ret:Array<SelectorPartOf<Pseudo>> = [];
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

  function parsePseudo():Pseudo
    return throw 'abstract';

  function parseInt(?here = false) {
    if (!here) skipIgnored();
    return
      if (!is(DIGIT)) Failure(makeError('number expected', makePos(this.pos)));
      else Success(Std.parseInt(this.readWhile(DIGIT)));
  }    
}