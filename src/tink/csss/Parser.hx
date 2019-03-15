package tink.csss;

import tink.csss.Selector;
import tink.core.Error;

using tink.core.Outcome;
using StringTools;

typedef Plugin = {
  function not(s:Selector):Pseudo;
  function state(s:ElementState):Pseudo;
  function nth(matchType:Bool, factor:Int, offset:Int, backward:Bool):Pseudo;
  function custom(name:String):Pseudo;
}

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
class Parser<Position, Error> extends ParserBase<Position, Error> {
  
  var pseudos:Plugin;
  
  function new(pseudos, source, reporter, ?offset) {
    super(source, reporter, offset);
    this.pseudos = pseudos;
  }
  
  static public function parse(source, ?pos) 
    return parseWith(source, {
      not: Not, nth: Nth, state: State, custom: Custom,
    }, pos);
  
  static public function parseWith<Pseudo>(source, pseudos:Plugin, ?pos):Outcome<Selector, Error>
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
        var p = new Parser(pseudos, source, reporter, offset);
        var s = p.parseFullSelector();
        if (p.pos < p.source.length)
          p.die('expected selector end');
        else 
          Success(s);
      }
      catch (e:Error) Failure(e);
  
  override function parsePseudo():Pseudo {
    allowHere(':');
    var name = ident().sure();
    return switch name.toString() {
      case 'not': 
        expect('(') + pseudos.not(parseFullSelector()) + expect(')');
      case 'first-child': pseudos.nth(false, 0, 1, false);
      case 'last-child': pseudos.nth(false, 0, 1, true);
      case 'first-of-type': pseudos.nth(true, 0, 1, false);
      case 'last-of-type': pseudos.nth(true, 0, 1, true);
      case 'only-child': pseudos.nth(false, 0, 0, false);
      case 'only-of-type': pseudos.nth(true, 0, 0, false);
      case 'odd': pseudos.nth(false, 2, 1, false);
      case 'even': pseudos.nth(false, 2, 0, false);
      case ElementState.ofString(_) => Success(state): pseudos.state(state);    
      case CHILD_RULES[_] => [matchType, backward]:
        expect('(');
        var sign = if (allow('-')) -1 else 1;
        
        function withFactor(factor:Int) 
          return 
            pseudos.nth(
              matchType, 
              sign * factor, 
              if (allow('-')) -parseInt().sure()
              else if (allow('+')) parseInt().sure()
              else 0,
              backward
            );

        (if (allowHere('n')) 
          withFactor(1);
        else {
          var i = parseInt(true).sure();
          if (allowHere('n')) withFactor(i);
          else pseudos.nth(matchType, 0, i * sign, backward);
        }) + expect(')');
      default: 
        reject(name);
    }
  }

  static var CHILD_RULES = [
    'nth-child' => [false, false],
    'nth-of-type' => [true, false],
    'nth-last-child' => [false, true],
    'nth-last-of-type' => [true, true],
  ];	
}