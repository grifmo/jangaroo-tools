/*
 * Copyright 2008 CoreMedia AG
 * 
 * Licensed under the Apache License, Version 2.0 (the "License"); 
 * you may not use this file except in compliance with the License. 
 * You may obtain a copy of the License at
 * http://www.apache.org/licenses/LICENSE-2.0 
 * 
 * Unless required by applicable law or agreed to in writing, 
 * software distributed under the License is distributed on an "AS
 * IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either 
 * express or implied. See the License for the specific language 
 * governing permissions and limitations under the License.
 */

package net.jangaroo.jooc;

import java.io.IOException;
import java.util.List;

/**
 * @author Andreas Gawecki
 */
class Catch extends KeywordStatement {

  JooSymbol lParen;
  Parameter param;
  JooSymbol rParen;
  BlockStatement block;

  public Catch(JooSymbol symCatch, JooSymbol lParen, Parameter param, JooSymbol rParen, BlockStatement block) {
    super(symCatch);
    this.lParen = lParen;
    this.param = param;
    this.rParen = rParen;
    this.block = block;
  }

  public void generateCode(JsWriter out) throws IOException {
    List<Catch> catches = ((TryStatement)parentNode).catches;
    Catch firstCatch = catches.get(0);
    boolean isFirst = equals(firstCatch);
    boolean isLast = equals(catches.get(catches.size()-1));
    TypeRelation typeRelation = param.optTypeRelation;
    boolean hasCondition = typeRelation != null && typeRelation.getType().getSymbol().sym!=sym.MUL;
    if (!hasCondition && !isLast) {
      Jooc.error(rParen, "Only last catch clause may be untyped.");
    }
    final JooSymbol errorVar = firstCatch.param.getIde().ide;
    final JooSymbol localErrorVar = param.getIde().ide;
    // in the following, always take care to write whitespace only once!
    out.writeSymbolWhitespace(symKeyword);
    if (isFirst) {
      out.writeSymbolToken(symKeyword); // "catch"
      // "(localErrorVar)":
      out.writeSymbol(lParen, !hasCondition);
      out.writeSymbol(errorVar, !hasCondition);
      if (!hasCondition && typeRelation!=null) {
        // can only be ": *", add as comment:
        typeRelation.generateCode(out);
      }
      out.writeSymbol(rParen, !hasCondition);
      if (hasCondition || !isLast) {
        // a catch block always needs a brace, so generate one for conditions:
        out.writeToken("{");
      }
    } else {
      // transform catch(ide:Type){...} into else if is(e,Type)){var ide=e;...}
      out.writeToken("else");
    }
    if (hasCondition) {
      out.writeToken("if(is");
      out.writeSymbol(lParen);
      out.writeSymbolWhitespace(localErrorVar);
      out.writeSymbolToken(errorVar);
      out.writeSymbolWhitespace(typeRelation.symRelation);
      out.writeToken(",");
      typeRelation.getType().generateCode(out);
      out.writeSymbol(rParen);
      out.writeToken(")");
    }
    if (!localErrorVar.getText().equals(errorVar.getText())) {
      block.addBlockStartCodeGenerator(new CodeGenerator() {
        public void generateCode(JsWriter out) throws IOException {
          out.writeToken("var");
          out.writeSymbolToken(localErrorVar);
          out.writeToken("=");
          out.writeSymbolToken(errorVar);
          out.writeToken(";");
        }
      });
    }
    block.generateCode(out);
    if (isLast && !(isFirst && !hasCondition)) {
      // last catch clause causes the JS catch block:
      out.writeToken("}");
    }
  }

  public Node analyze(Node parentNode, AnalyzeContext context) {
    super.analyze(parentNode, context);
    context.enterScope(this);
    param.analyze(this, context);
    block.analyze(this, context);
    context.leaveScope(this);
    return this;
  }

}