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

package net.jangaroo.jooc.ast;

import net.jangaroo.jooc.JooSymbol;
import net.jangaroo.jooc.Scope;

import java.io.IOException;
import java.util.List;

/**
 * @author Andreas Gawecki
 */
public class Initializer extends NodeImplBase {

  private JooSymbol symEq;
  private Expr value;

  public Initializer(JooSymbol symEq, Expr value) {
    this.symEq = symEq;
    this.value = value;
  }

  @Override
  public List<? extends AstNode> getChildren() {
    return makeChildren(super.getChildren(), value);
  }

  @Override
  public void visit(AstVisitor visitor) throws IOException {
    visitor.visitInitializer(this);
  }

  @Override
  public void scope(final Scope scope) {
    getValue().scope(scope);
  }

  public void analyze(AstNode parentNode) {
    super.analyze(parentNode);
    getValue().analyze(this);
  }

  public JooSymbol getSymbol() {
    return getSymEq();
  }

  public JooSymbol getSymEq() {
    return symEq;
  }

  public Expr getValue() {
    return value;
  }

  void addPublicApiDependencies() {
    if (value.isCompileTimeConstant()) {
      try {
        value.visit(new TransitiveAstVisitor(new AstVisitorBase() {
          @Override
          public void visitQualifiedIde(QualifiedIde qualifiedIde) throws IOException {
            qualifiedIde.addPublicApiDependency();
          }
        }));
      } catch (IOException e) {
        throw new IllegalStateException("should not happen");
      }
    }
  }
}
