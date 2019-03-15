package tink.csss;

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
class Parser<Position, Error> extends ParserBase<Position, Error> {

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

  
  override function parsePseudo():Pseudo {
    allowHere(':');
    var name = ident().sure();
    return switch name.toString() {
      case 'not': 
        expect('(') + Not(parseFullSelector()) + expect(')');
      case 'first-child': Nth(false, 0, 1, false);
      case 'last-child': Nth(false, 0, 1, true);
      case 'first-of-type': Nth(true, 0, 1, false);
      case 'last-of-type': Nth(true, 0, 1, true);
      case 'only-child': Nth(false, 0, 0, false);
      case 'only-of-type': Nth(true, 0, 0, false);
      case 'odd': Nth(false, 2, 1, false);
      case 'even': Nth(false, 2, 0, false);
      case ElementState.ofString(_) => Success(state): State(state);    
      case CHILD_RULES[_] => [matchType, backward]:
        expect('(');
        var sign = if (allow('-')) -1 else 1;
        
        function withFactor(factor:Int) 
          return 
            Nth(
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
          else Nth(matchType, 0, i * sign, backward);
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